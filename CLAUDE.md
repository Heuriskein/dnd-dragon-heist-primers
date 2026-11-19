# Dragon Heist primers: working notes for Claude

The DM is running Waterdeep: Dragon Heist with **Winter / Manshoon & Zhentarim** as the villain. This repo holds spoiler-free player primers, published via GitHub Pages from `docs/`.

**Campaign twist:** the Death Curse from *Tomb of Annihilation* is active. It began about three months before the campaign. Besides the book effects (no resurrection; the once-raised waste away), it has drained the city treasury and much of its adventurer population. Laeral Silverhand is personally afflicted. Because of her strength, the wasting only became severe about a month after the curse began, so she withdrew from public life about two months before the campaign. That gap is why the public does not connect her absence to the curse. Her absence strains the city. Public-facing coverage is in `docs/lore/death-curse.md`.

## Hard rules
- **No spoilers in `docs/`.** Never include: Manshoon or his clone, Kolat Towers, the Gralhunds' Zhentarim ties, the Stone of Golorr, the vault's location/keys/guardians, the Cassalanters' devil pact, Jarlaxle as Zardoz Zord, or chapter plot beats (e.g. the Trollskull Alley fireball).
  - **Laeral's affliction and the curse's Chult origin are secret knowledge.** They never go in `docs/lore/` or the baseline primer. Only characters who qualify under `mapping.md` → "Secret knowledge" learn them. Laeral's absence is public, but public pages must not link it to the Death Curse: no "since the curse" wording, and don't put her absence on the Death Curse page. Date it "the past couple of months".
  - From Tomb of Annihilation, also never include: the Soulmonger, Acererak, Omu, Ras Nsi, the Nine Trickster Gods, the trapped-souls mechanism, or anything else about the curse's true cause. Rumors listed in `docs/lore/winter-season.md` are the approved level.
- **`data/` is committed but outside `docs/`**, so it is never on the site (it is visible to anyone browsing the repo; the DM is fine with that). Never copy backstory details into `docs/` that the player hasn't agreed to make public.
- Write original prose; don't copy text from the book.
- Mark lore you're unsure of with `⚠ verify`.

## Adding a character ("add character <url>")
1. Character ID = the number in `dndbeyond.com/characters/<id>`. The character must be **Public**; a 403 means it's private.
2. Fetch it (PowerShell):
   `$r = Invoke-RestMethod "https://character-service.dndbeyond.com/character/v5/character/<id>"`
   and save it with `$r | ConvertTo-Json -Depth 100 | Out-File -Encoding utf8 data/<slug>.json`.
3. Extract the following from `$r.data`:
   - `name`, `race.fullName`, `classes[].definition.name/level`, `background.definition.name`.
   - From `modifiers.{race,class,background,item,feat}`: entries of type `proficiency`, `expertise` and `language`, using `friendlySubtypeName`.
   - `traits`, `notes.backstory`, `notes.organizations`, `faith`, `alignmentId`.

   Write `data/<slug>.md` in the same format as `data/finnian-goodbarrel.md`.
4. Choose tiers with `mapping.md`. Write `docs/primers/<slug>.md` from `templates/primer-template.md`. Every section needs a "Because:" line.
5. Replace the player's `*-pending.md` placeholder if one exists. Update `roster.md` and the table in `docs/index.md`.
6. Secret knowledge: if the character qualifies under `mapping.md` → "Secret knowledge" (the bar is **proficiency**), write `docs/s/<first-name>-<16 random hex>.md` with front matter `nav_exclude: true`, `search_exclude: true`, `sitemap: false`, using an existing `docs/s/` page as the model. Never link it from anywhere on the site. Record the path in `roster.md` so the DM can send it privately.
7. Spoiler checks. Both should print nothing:
   - `grep -rniE "manshoon|golorr|kolat|zord|vault|devil|asmodeus|fireball|soulmonger|acererak|\bomu\b|ras nsi|trickster gods" docs/` (the Dragon Heist and ToA spoilers; banned everywhere, including `docs/s/`).
   - `grep -rliE "chult|nyanzaru" docs/ | grep -v "^docs/s/"` (secret-tier words; allowed only on hidden pages).
   - Also make sure no page links to `docs/s/`.
8. If the new character needs lore not yet written (e.g. a new ancestry or faction), add it to the relevant `docs/lore/` module in Common/Proficient/Expert tiers.
