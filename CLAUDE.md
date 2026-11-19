# Dragon Heist primers: working notes for Claude

The DM is running Waterdeep: Dragon Heist with **Winter / Manshoon & Zhentarim** as the villain. This repo holds spoiler-free player primers, published via GitHub Pages from `docs/`.

**Campaign twist:** the Death Curse from *Tomb of Annihilation* is active. It began about three months before the campaign. Besides the book effects (no resurrection; the once-raised waste away), it has drained the city treasury and much of its adventurer population. Laeral Silverhand is personally afflicted. Because of her strength, the wasting only became severe about a month after the curse began, so she withdrew from public life about two months before the campaign. That gap is why the public does not connect her absence to the curse. Her absence strains the city. Public-facing coverage is in `lore/death-curse.md`.

## How the site is built
- **`docs/` is generated. Never edit it by hand.** Run `powershell -ExecutionPolicy Bypass -File tools\build.ps1`. It deletes everything in `docs/` except `_config.yml` and rebuilds it.
- Sources:
  - `lore/<module>.md`: a `# Title`, an optional intro (ignored by the build), then only `## Common`, `## Proficient` and `## Expert` sections. Any other `##` heading fails the build. Use `###` or nested bullets inside a tier.
  - `lore/baseline.md`: "What every resident knows". Its Common tier opens every character page.
  - `lore/peoples-*.md`: one module per ancestry.
  - `lore/secrets/<id>.md`: secret-tier text (`# Title` + body). An optional `<!-- extras -->` line marks where a character's extra bullets go.
  - `characters/<slug>.json`: one per character. See `characters/_template.json`; files starting with `_` are skipped.
- The output is `docs/<slug>.md` per character, plus `docs/index.md` and `docs/s/<secretPage>.md` hidden pages.
- **Tiers stack:** a module at `expert` includes its Common and Proficient text too. Links inside lore are reduced to plain text, because the lore library isn't published.
- The build refuses to write anything if:
  - a banned spoiler appears anywhere;
  - secret-tier text (Chult, Nyanzaru, Laeral as wasting/afflicted) appears on a public page;
  - a public line ties Laeral or the Open Lord to the curse;
  - a page links to `s/`.

  It also reports how many `⚠` flags are left on public pages.
- After building, review `git diff docs/` before committing: it is exactly what will be published.

## Hard rules
- **No spoilers in `lore/` (except `lore/secrets/`), `characters/`, or `docs/`.** Never include: Manshoon or his clone, Kolat Towers, the Gralhunds' Zhentarim ties, the Stone of Golorr, the vault's location/keys/guardians, the Cassalanters' devil pact, Jarlaxle as Zardoz Zord, or chapter plot beats (e.g. the Trollskull Alley fireball).
  - **Laeral's affliction and the curse's Chult origin are secret knowledge.** They live only in `lore/secrets/` and reach only characters who qualify under `mapping.md` → "Secret knowledge". Laeral's absence is public, but public text must not link it to the Death Curse: no "since the curse" wording, and don't put her absence in `lore/death-curse.md`. Date it "the past couple of months".
  - From Tomb of Annihilation, also never include, even in secrets: the Soulmonger, Acererak, Omu, Ras Nsi, the Nine Trickster Gods, the trapped-souls mechanism, or anything else about the curse's true cause. Rumors in `lore/winter-season.md` are the approved level.
- **`data/` is committed but outside `docs/`**, so it is never on the site (it is visible to anyone browsing the repo; the DM is fine with that). Never copy backstory details into character JSON that the player hasn't agreed to make public.
- **The DM edits text directly.** Before changing lore or character files, read them from disk; never regenerate them from memory. Keep the DM's wording and tier choices.
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
4. Choose modules and tiers with `mapping.md`. Write `characters/<slug>.json` from `characters/_template.json`. Every section needs a `because`. Put character-specific angles in `lead` and `extra`, not in shared lore.
5. Secret knowledge: apply `mapping.md` → "Secret knowledge" (the bar is **proficiency**). If the character qualifies, add `secrets` and a `secretPage` of `<first-name>-<16 random hex>`. The build suggests one if it's missing.
6. If the character needs lore that doesn't exist yet (e.g. a new ancestry or faction), add a tiered module to `lore/`.
7. Run the build, review `git diff docs/`, and update `roster.md` (status, plus the hidden page path for the DM to send privately).
