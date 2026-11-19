# Waterdeep: Dragon Heist: character primers

Player-facing primers for a *Waterdeep: Dragon Heist* campaign (Winter: the Zhentarim), run with the *Tomb of Annihilation* Death Curse active. Each primer holds what a character knows about Waterdeep, based on their skills, background and ancestry.

## Layout
- `docs/` is the GitHub Pages site (Jekyll + just-the-docs). Only this folder is published.
  - `docs/primers/`: `00-every-resident.md` plus one page per character.
  - `docs/lore/`: reference modules, each tiered Common / Proficient / Expert.
- `data/` holds raw D&D Beyond JSON and normalized summaries. It is committed but sits outside `docs/`, so it never appears on the site (anyone browsing the repo can still see it).
- `mapping.md`: rules for which skills and backgrounds unlock which lore tiers.
- `roster.md`: players, characters and status.
- `templates/primer-template.md`: structure for new primers.

## Spoiler policy
Primers hold public knowledge and rumor only. No villain secrets or plot reveals. `⚠ verify` marks lore to check against the book. Remove these marks before sharing links.

## Adding a character
1. The player sets the D&D Beyond character to **Public**.
2. Pull and summarize it into `data/` (see `CLAUDE.md`).
3. Pick lore tiers using `mapping.md`, then write the primer from the template.
4. Update `roster.md` and the table in `docs/index.md`.
5. Run the spoiler check.

## Publishing
GitHub repo → Settings → Pages → Deploy from branch `main`, folder `/docs`.
