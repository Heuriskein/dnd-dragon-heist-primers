# Dragon Heist primers: working notes for Claude

The DM is running Waterdeep: Dragon Heist with **Winter / Manshoon & Zhentarim** as the villain. This repo holds spoiler-free player primers, published via GitHub Pages from `docs/`.

**Campaign twist:** the Death Curse from *Tomb of Annihilation* is active. It began about three months before the campaign. Besides the book effects (no resurrection; the once-raised waste away), it has drained the city treasury and much of its adventurer population. Laeral Silverhand is personally afflicted and has withdrawn from public life, which strains the city. Public-facing coverage is in `docs/lore/death-curse.md`.

## Hard rules
- **No spoilers in `docs/`.** Never include: Manshoon or his clone, Kolat Towers, the Gralhunds' Zhentarim ties, the Stone of Golorr, the vault's location/keys/guardians, the Cassalanters' devil pact, Jarlaxle as Zardoz Zord, or chapter plot beats (e.g. the Trollskull Alley fireball).
  - From Tomb of Annihilation, also never include: the Soulmonger, Acererak, Omu, Ras Nsi, the Nine Trickster Gods, the trapped-souls mechanism, or anything else about the curse's true cause. Whether Laeral's affliction and the "far to the south" rumor are public is the DM's call; they're marked `⚠ DM` in death-curse.md. Rumors listed in `docs/lore/winter-season.md` are the approved level.
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
6. Spoiler check: `grep -riE "manshoon|golorr|kolat|zord|vault|devil|asmodeus|fireball|soulmonger|acererak|\bomu\b|ras nsi|trickster|chult" docs/` should return nothing.
7. If the new character needs lore not yet written (e.g. a new ancestry or faction), add it to the relevant `docs/lore/` module in Common/Proficient/Expert tiers.
