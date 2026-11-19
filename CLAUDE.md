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
  - `lore/rumors.md`: **not tiered.** It's a pool of rumors, each a `## <id>` section (lowercase-with-dashes). Lines starting `DM:` are notes and are stripped from pages. A `DM:` line containing `DRAFT` marks a rumor the DM hasn't approved yet. `ALLOW-LAERAL-CURSE` exempts that one rumor from the Laeral/curse check (see Hard rules).
    - The build draws each character's rumors. Nothing is stored in the character JSON, and a `"rumors"` field there fails the build. The count is set by `"investigation"`: `none` hears 1, `proficient` 2, `expert` 3.
    - The draw is seeded from the character's slug and the pool's ids. Rebuilds are stable, but adding or removing a rumor id redraws everyone. Rewording a rumor doesn't.
    - The DM's plan: grow the pool until it's good, then publish, and leave rumors alone after that. If rumors ever need changing after publishing, adding an id will reshuffle what players have already read, so ask first.
    - A good rumor names someone or somewhere, can be checked, and might be wrong. It must not be contradicted by any Common or Proficient lore, or the baseline. Higher tiers may contradict it; that's the point of expertise.
    - **Everything written is signal.** Players read every line of a handout as a deliberate clue, because the DM chose to write it. In-text framing like "they say it as a joke", "probably nonsense" or "nobody believes it" does *not* make players dismiss something; it draws attention. Judge each rumor by how strong a clue it is when read at face value, and choose a weaker rumor rather than a disclaimer.
    - **Give every claim an in-world source** (a lamplighter, a link-boy, a Watchful Order apprentice). A rumor narrated without one reads as fact. If something isn't common knowledge, put it behind the source as well, including who an NPC *is*.
    - **A rumor must earn its keep.** It needs something players can *do*: avoid it, exploit it, sell it, follow it, or worry about someone. It doesn't have to be a major hook, but the DM cuts throwaway mood rumors. Already cut for this reason: the tax rise, the Zhentarim buying friends, a noble house in debt, and the frozen ship.
    - Several competing rumors about one subject are welcome (Laeral has three), and a character may draw more than one of them.
    - **The vault:** the DM wants no hints beyond "there is a vault". Don't tease Aurinax. The joke, sighting and pearl-buyer ideas were all rejected.
    - **Renaer Neverember** was deliberately removed from the lore. He appears only in the `neverember-renaer` rumor, and his identity comes only through the link-boy.
  - `characters/<slug>.json`: one per character. See `characters/_template.json`; files starting with `_` are skipped.
- The output is `docs/<slug>.md` per character, plus `docs/index.md` and `docs/s/<secretPage>.md` hidden pages.
- **Tiers stack:** a module at `expert` includes its Common and Proficient text too. Links inside lore are reduced to plain text, because the lore library isn't published.
- The build refuses to write anything if:
  - a banned spoiler appears anywhere;
  - secret-tier text (Chult, Nyanzaru, Laeral as wasting/afflicted) appears on a public page;
  - a public line ties Laeral or the Open Lord to the curse;
  - a page links to `s/`.

  It also reports how many `⚠` flags are left on public pages, and which DRAFT rumors are on pages.
- After building, review `git diff docs/` before committing: it is exactly what will be published.
- **Hand-edit guard:** `.build-manifest.json` (committed, repo root) records a hash of every file the last build wrote, ignoring line endings. If anything in `docs/` was edited or added by hand since then, the build lists the files and stops without changing anything.
  - The DM sometimes edits generated pages directly. When that happens, use `git diff docs/` to see the edit, port it into the right source (`lore/`, `lore/secrets/`, or `characters/*.json`), rebuild with `-Force`, and confirm the regenerated page matches the edit.
  - Never use `-Force` without porting first.

## Hard rules
- **No spoilers in `lore/` (except `lore/secrets/`), `characters/`, or `docs/`.** Never include: Manshoon or his clone, Kolat Towers, the Gralhunds' Zhentarim ties, the Stone of Golorr, the vault's location/keys/guardians, the Cassalanters' devil pact, Jarlaxle as Zardoz Zord, or chapter plot beats (e.g. the Trollskull Alley fireball).
  - **Laeral's affliction and the curse's Chult origin are secret knowledge.** They live only in `lore/secrets/` and reach only characters who qualify under `mapping.md` → "Secret knowledge". Laeral's absence is public, but public text must not link it to the Death Curse: no "since the curse" wording, and don't put her absence in `lore/death-curse.md`. Date it "the past couple of months".
    - **The one exception is `laeral-errand`**, a rumor the DM deliberately approved that ties her absence to the curse: she's said to be out *fighting* it. It's a red herring. It points north-east (Silverymoon), never south. It's marked `ALLOW-LAERAL-CURSE` in `lore/rumors.md`. Never add that flag yourself; only the DM grants it.
  - The **Doom Raider / Zhentarim schism** drives the Xanathar rumor, but it appears only in `DM:` notes, never in public text.
  - From Tomb of Annihilation, also never include, even in secrets: the Soulmonger, Acererak, Omu, Ras Nsi, the Nine Trickster Gods, the trapped-souls mechanism, or anything else about the curse's true cause. Rumors in `lore/rumors.md` are the approved level.
- **`data/` is committed but outside `docs/`**, so it is never on the site (it is visible to anyone browsing the repo; the DM is fine with that). Never copy backstory details into character JSON that the player hasn't agreed to make public.
- **Repo visibility (DM's decision, 2026-11-19):** the repo may be public even though it holds spoilers: this file, `lore/secrets/`, `DM:` notes, and `roster.md`. The DM trusts the players, and gives them only the Pages link, never the repo link. Don't raise this again. What matters is that the repo can't be *stumbled upon* from the site: never add links to the repo on any page or in `docs/_config.yml` (no `gh_edit_link`, no repo in `aux_links`, no footer links).
- **The DM edits text directly.** Before changing lore or character files, read them from disk; never regenerate them from memory. Keep the DM's wording and tier choices.
- Write original prose; don't copy text from the book.
- Mark lore you're unsure of with `⚠ verify`.

## Working notes
- **Before building, run `git status`.** If the DM has uncommitted edits in `lore/` or `characters/`, the build will publish them. Say so, and ask before committing output that includes them. When told to, commit their source files together with the rebuilt `docs/`.
- **Edit `tools/build.ps1` (and any text containing backslashes) with the Edit tool, not sed or perl.** Shell escaping of `\b` twice turned it into an invisible backspace character: once in a regex, and once in the README's `tools\build.ps1` path. Keep `build.ps1` ASCII-only (Windows PowerShell 5.1).
- `DM:` notes in `lore/rumors.md` may span several lines, but **every line must start with `DM:`**. Any line that doesn't is published as part of the rumor.
- Open items and status live in `roster.md` → "Open items".

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
5. Set `"investigation"` (none, proficient or expert). The build draws the rumors.
6. Secret knowledge: apply `mapping.md` → "Secret knowledge" (the bar is **proficiency**). If the character qualifies, add `secrets` and a `secretPage` of `<first-name>-<16 random hex>`. The build suggests one if it's missing.
7. If the character needs lore that doesn't exist yet (e.g. a new ancestry or faction), add a tiered module to `lore/`.
8. Run the build, review `git diff docs/`, and update `roster.md` (status, plus the hidden page path for the DM to send privately).
