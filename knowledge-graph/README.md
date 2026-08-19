# Knowledge graph

Interactive map of the **digi-carts** GitHub org: repositories, actors, gateway routes, PostgreSQL schemas, GCP, CI, and known design gaps.

## Open the visualizer

From this folder:

```bash
cd knowledge-graph
python3 -m http.server 8765
```

Then open [http://localhost:8765](http://localhost:8765).

You can also open `index.html` directly; `graph-data.js` embeds the same payload as `graph.json` so the page works without a server.

## Files

| File | Role |
|------|------|
| `graph.json` | Source of truth (nodes, edges, type colors) |
| `graph-data.js` | `window.DIGICARTS_GRAPH = …` generated from the JSON |
| `graph.js` | Force-directed renderer (no npm, no CDN) |
| `index.html` | Shell: filters, search, inspector |

## Edit the graph

1. Change `graph.json`.
2. Regenerate the JS embed:

```bash
python3 - <<'PY'
from pathlib import Path
p = Path("graph.json")
js = "window.DIGICARTS_GRAPH = " + p.read_text().rstrip() + ";\n"
Path("graph-data.js").write_text(js)
PY
```

Node fields: `id`, `label`, `type`, `detail`, optional `url`, `port`, `schema`, `stack`.  
Edges: `source`, `target`, `rel`, `label`.
