/* digi-carts knowledge graph renderer. Reads window.DIGICARTS_GRAPH from graph-data.js. */
(function () {
  const DATA = window.DIGICARTS_GRAPH;
  if (!DATA) {
    document.getElementById("inspector").innerHTML = "<p>Missing graph-data.js</p>";
    return;
  }

  const types = DATA.types;
  const canvas = document.getElementById("graph");
  const ctx = canvas.getContext("2d");
  const inspector = document.getElementById("inspector");
  const filtersEl = document.getElementById("filters");
  const statsEl = document.getElementById("stats");
  const searchEl = document.getElementById("search");

  const enabled = {};
  Object.keys(types).forEach((t) => {
    enabled[t] = true;
  });

  const nodes = DATA.nodes.map((n, i) => ({
    ...n,
    x: Math.cos((i / DATA.nodes.length) * Math.PI * 2) * 220,
    y: Math.sin((i / DATA.nodes.length) * Math.PI * 2) * 220,
    vx: 0,
    vy: 0,
  }));
  const byId = Object.fromEntries(nodes.map((n) => [n.id, n]));
  const edges = DATA.edges
    .filter((e) => byId[e.source] && byId[e.target])
    .map((e) => ({ ...e, a: byId[e.source], b: byId[e.target] }));

  Object.keys(types).forEach((t) => {
    const id = "t-" + t;
    const row = document.createElement("label");
    row.className = "filter";
    row.innerHTML =
      '<input type="checkbox" checked />' +
      '<span class="dot" style="background:' +
      types[t].color +
      '"></span>' +
      types[t].label;
    const input = row.querySelector("input");
    input.addEventListener("change", () => {
      enabled[t] = input.checked;
    });
    filtersEl.appendChild(row);
  });

  let cam = { x: 0, y: 0, k: 0.85 };
  let dragging = null;
  let panning = null;
  let selected = null;
  let hover = null;
  let query = "";

  function visibleNode(n) {
    if (!enabled[n.type]) return false;
    if (!query) return true;
    const blob = (n.label + " " + n.id + " " + (n.detail || "") + " " + (n.schema || "")).toLowerCase();
    return blob.includes(query);
  }

  function visibleEdge(e) {
    return visibleNode(e.a) && visibleNode(e.b);
  }

  function sizeOf(n) {
    if (n.type === "org") return 18;
    if (n.type === "gateway") return 14;
    if (n.type === "ui" || n.type === "service") return 11;
    if (n.type === "schema") return 8;
    return 9;
  }

  function tick() {
    const vis = nodes.filter(visibleNode);
    const kRep = 2800;
    const kSpring = 0.012;
    const rest = 90;

    for (const n of vis) {
      if (n === dragging) continue;
      n.vx *= 0.86;
      n.vy *= 0.86;
    }

    for (let i = 0; i < vis.length; i++) {
      for (let j = i + 1; j < vis.length; j++) {
        const a = vis[i];
        const b = vis[j];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let d2 = dx * dx + dy * dy || 1;
        const d = Math.sqrt(d2);
        const f = kRep / d2;
        const fx = (dx / d) * f;
        const fy = (dy / d) * f;
        if (a !== dragging) {
          a.vx -= fx;
          a.vy -= fy;
        }
        if (b !== dragging) {
          b.vx += fx;
          b.vy += fy;
        }
      }
    }

    for (const e of edges) {
      if (!visibleEdge(e)) continue;
      const a = e.a;
      const b = e.b;
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const d = Math.sqrt(dx * dx + dy * dy) || 1;
      const force = (d - rest) * kSpring;
      const fx = (dx / d) * force;
      const fy = (dy / d) * force;
      if (a !== dragging) {
        a.vx += fx;
        a.vy += fy;
      }
      if (b !== dragging) {
        b.vx -= fx;
        b.vy -= fy;
      }
    }

    for (const n of vis) {
      if (n === dragging) continue;
      const gx = -n.x * 0.004;
      const gy = -n.y * 0.004;
      n.vx += gx;
      n.vy += gy;
      n.x += n.vx;
      n.y += n.vy;
    }
  }

  function worldFromEvent(ev) {
    const r = canvas.getBoundingClientRect();
    const mx = ev.clientX - r.left;
    const my = ev.clientY - r.top;
    return {
      x: (mx - canvas.width / 2) / cam.k - cam.x,
      y: (my - canvas.height / 2) / cam.k - cam.y,
    };
  }

  function hit(wx, wy) {
    let best = null;
    let bestD = 1e9;
    for (const n of nodes) {
      if (!visibleNode(n)) continue;
      const d = Math.hypot(n.x - wx, n.y - wy);
      const r = sizeOf(n) + 8;
      if (d <= r && d < bestD) {
        best = n;
        bestD = d;
      }
    }
    return best;
  }

  function showNode(n) {
    selected = n;
    const t = types[n.type] || {};
    inspector.innerHTML =
      '<h2>Inspector</h2>' +
      '<div class="type">' +
      (t.label || n.type) +
      "</div>" +
      "<h3>" +
      n.label +
      "</h3>" +
      "<dl>" +
      (n.port != null ? "<dt>Port</dt><dd>" + n.port + "</dd>" : "") +
      (n.schema ? "<dt>Schema</dt><dd><code>" + n.schema + "</code></dd>" : "") +
      (n.stack ? "<dt>Stack</dt><dd>" + n.stack + "</dd>" : "") +
      (n.detail ? "<dt>About</dt><dd>" + n.detail + "</dd>" : "") +
      (n.url ? '<dt>Repo</dt><dd><a href="' + n.url + '" target="_blank" rel="noreferrer">' + n.url + "</a></dd>" : "") +
      "<dt>Id</dt><dd><code>" +
      n.id +
      "</code></dd>" +
      neighborsHtml(n) +
      "</dl>";
  }

  function neighborsHtml(n) {
    const rels = edges.filter((e) => e.a === n || e.b === n);
    if (!rels.length) return "";
    const items = rels
      .map((e) => {
        const other = e.a === n ? e.b : e.a;
        const dir = e.a === n ? "→" : "←";
        return "<li>" + dir + " <strong>" + other.label + "</strong> <span class=\"hint\">" + (e.label || e.rel) + "</span></li>";
      })
      .join("");
    return "<dt>Links</dt><dd><ul style=\"padding-left:16px;margin:4px 0\">" + items + "</ul></dd>";
  }

  function resize() {
    const r = canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    canvas.width = Math.max(1, r.width * dpr);
    canvas.height = Math.max(1, r.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function draw() {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    ctx.clearRect(0, 0, w, h);
    ctx.save();
    ctx.translate(w / 2, h / 2);
    ctx.scale(cam.k, cam.k);
    ctx.translate(cam.x, cam.y);

    for (const e of edges) {
      if (!visibleEdge(e)) continue;
      const on = selected && (e.a === selected || e.b === selected);
      ctx.beginPath();
      ctx.moveTo(e.a.x, e.a.y);
      ctx.lineTo(e.b.x, e.b.y);
      ctx.strokeStyle = on ? "rgba(201,162,39,0.85)" : "rgba(154,163,178,0.28)";
      ctx.lineWidth = on ? 1.6 / cam.k : 1 / cam.k;
      ctx.stroke();
    }

    for (const n of nodes) {
      if (!visibleNode(n)) continue;
      const r = sizeOf(n);
      const color = (types[n.type] && types[n.type].color) || "#888";
      const isSel = n === selected;
      const isHov = n === hover;
      ctx.beginPath();
      ctx.arc(n.x, n.y, r, 0, Math.PI * 2);
      ctx.fillStyle = color;
      ctx.globalAlpha = query && !visibleNode(n) ? 0.15 : 1;
      ctx.fill();
      ctx.globalAlpha = 1;
      if (isSel || isHov) {
        ctx.strokeStyle = "#fff";
        ctx.lineWidth = 2 / cam.k;
        ctx.stroke();
      }
      ctx.fillStyle = "#e8eaed";
      ctx.font = 11 / cam.k + "px ui-sans-serif, system-ui, sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "top";
      ctx.fillText(n.label, n.x, n.y + r + 3 / cam.k);
    }
    ctx.restore();

    const vc = nodes.filter(visibleNode).length;
    const ec = edges.filter(visibleEdge).length;
    statsEl.textContent = vc + " nodes · " + ec + " edges";
  }

  function loop() {
    tick();
    draw();
    requestAnimationFrame(loop);
  }

  canvas.addEventListener("mousedown", (ev) => {
    const w = worldFromEvent(ev);
    const n = hit(w.x, w.y);
    if (n) {
      dragging = n;
      n.vx = n.vy = 0;
      showNode(n);
    } else {
      panning = { mx: ev.clientX, my: ev.clientY, cx: cam.x, cy: cam.y };
      canvas.classList.add("dragging");
    }
  });
  window.addEventListener("mousemove", (ev) => {
    const w = worldFromEvent(ev);
    hover = hit(w.x, w.y);
    canvas.style.cursor = hover ? "pointer" : panning ? "grabbing" : "grab";
    if (dragging) {
      dragging.x = w.x;
      dragging.y = w.y;
      dragging.vx = dragging.vy = 0;
    } else if (panning) {
      cam.x = panning.cx + (ev.clientX - panning.mx) / cam.k;
      cam.y = panning.cy + (ev.clientY - panning.my) / cam.k;
    }
  });
  window.addEventListener("mouseup", () => {
    dragging = null;
    panning = null;
    canvas.classList.remove("dragging");
  });
  canvas.addEventListener(
    "wheel",
    (ev) => {
      ev.preventDefault();
      const factor = ev.deltaY < 0 ? 1.08 : 0.92;
      cam.k = Math.min(3, Math.max(0.25, cam.k * factor));
    },
    { passive: false }
  );
  canvas.addEventListener("dblclick", (ev) => {
    const w = worldFromEvent(ev);
    const n = hit(w.x, w.y);
    if (n && n.url) window.open(n.url, "_blank", "noopener");
  });
  searchEl.addEventListener("input", () => {
    query = searchEl.value.trim().toLowerCase();
    const matches = nodes.filter(visibleNode);
    if (matches.length === 1) showNode(matches[0]);
  });
  document.getElementById("reset").addEventListener("click", () => {
    cam = { x: 0, y: 0, k: 0.85 };
    query = "";
    searchEl.value = "";
  });

  window.addEventListener("resize", resize);
  resize();
  showNode(byId.org);
  loop();
})();
