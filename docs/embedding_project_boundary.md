# Embedding Project Boundary

Moneyfy is the product app repository. It should not contain Python virtual environments, raw market datasets, generated embedding matrices, model checkpoints, or experiment notebooks.

The standalone embedding project owns:
- data collection and preprocessing
- model training and reproduction scripts
- generated `.npy`, `.csv`, model, and report artifacts
- experiment documentation

Moneyfy may consume:
- stable Supabase tables populated from embedding outputs
- small checked-in schema or contract docs
- app-facing API or Edge Function responses
- manually curated sample fixtures for tests

Current standalone project path:
`/Users/maegmini/Project/moneyfy-stock-embeddings`
