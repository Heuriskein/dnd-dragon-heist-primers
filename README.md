# Waterdeep: Dragon Heist: character primers

Player-facing primers for a *Waterdeep: Dragon Heist* campaign (Winter: the Zhentarim), run with the *Tomb of Annihilation* Death Curse active. Each primer holds what a character knows about Waterdeep, based on their skills, background and ancestry.

## Layout
- `lore/`: the source library. Each module is tiered Common / Proficient / Expert, except `lore/rumors.md`, a pool the build draws a random set from for each character (adding or removing a rumor redraws everyone). `lore/baseline.md` is what every resident knows, `lore/peoples-*.md` covers each ancestry, and `lore/secrets/` holds secret knowledge.
- `characters/<slug>.json`: per character, which modules at which tier, with a "because" line for each section, plus character-specific bullets and secrets. `_template.json` is the starting point.
- `tools/build.ps1`: generates `docs/` from the two folders above and refuses to publish anything that fails the spoiler checks.
- `docs/`: **generated**, and the GitHub Pages root. It holds one page per character, the index, and hidden secret pages under `docs/s/`. Don't edit it by hand.
- `data/`: raw D&D Beyond JSON and summaries. Committed, never published.
- `mapping.md`: which skills and backgrounds unlock which tiers, and the secret-knowledge bar.
- `roster.md`: players, characters, status and hidden page links.

## Spoiler policy
Primers hold public knowledge and rumor only. No villain secrets or plot reveals. `⚠ verify` marks lore to check against the book. Remove these marks before sharing links.

## Adding a character
1. The player sets the D&D Beyond character to **Public**.
2. Pull and summarize it into `data/` (see `CLAUDE.md`).
3. Write `characters/<slug>.json` using `mapping.md`.
4. Run `powershell -ExecutionPolicy Bypass -File tools\build.ps1`, then review `git diff docs/`. Don't edit `docs/` by hand: the build refuses to overwrite hand edits until they're moved into the source files (then rerun with `-Force`).
5. Update `roster.md`.

## Publishing
GitHub repo → Settings → Pages → Deploy from branch `main`, folder `/docs`.
