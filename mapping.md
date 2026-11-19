# Knowledge mapping (DM-facing, not published)

How a character's sheet decides which lore tiers they get. A primer section must cite one of these sources.

## Tier rules
- **Common:** everyone. Covered by `docs/primers/00-every-resident.md`. Includes the Death Curse common tier.
- **Proficient:** one matching skill, background or faction.
- **Expert:** any ONE of:
  - **expertise** in a mapped skill;
  - a **background whose mapping says "expert"** for that module. Where it says "X or Y (expert)", pick one; the other is Proficient;
  - **proficiency plus a backstory tie** to the topic.
- **No stacking:** plain proficiencies don't add up to Expert, however many map to the same module.
- **No double-counting:** a skill granted by a background counts once, together with that background.
- **This is a guideline, not a formula** (DM, 2026-11-19: "comfortable with being a little goosey"). A few expert-tier details can go into a Proficient section when the character's concept clearly earns them, such as a thief knowing rooftop routes. Say why in the section's "Because:" line.

## Skills
| Skill | Lore modules |
|---|---|
| Arcana | arcana, death-curse |
| History | history, nobility |
| Religion | religion, death-curse |
| Nature | winter-season, races-cultures (rural folk, druids) |
| Investigation | places, underworld |
| Insight | underworld, factions, nobility (reading people) |
| Perception | places |
| Survival | winter-season, places (Southern Ward caravans) |
| Medicine | religion (temple healing), death-curse |
| Performance | places (taverns), nobility (patrons) |
| Persuasion / Deception | nobility, guilds-trade |
| Stealth / Sleight of Hand | underworld (with a criminal background, or as expertise) |
| Intimidation | underworld |
| Athletics / Acrobatics | none alone; supports places (rooftops) |
| Animal Handling | guilds-trade (caravans), nobility (House Amcathra) |

## Backgrounds
| Background | Modules (tier) |
|---|---|
| Acolyte | religion (expert) |
| Charlatan | underworld (proficient), nobility (proficient) |
| Criminal | underworld (expert) |
| Entertainer | places (expert), nobility (proficient) |
| Folk Hero | winter-season, races-cultures |
| Guild Artisan / Guild Merchant | guilds-trade (expert) |
| Hermit | religion or arcana (proficient) |
| Noble / Waterdhavian Noble | nobility (expert), history (proficient) |
| Outlander | winter-season, places (Southern Ward) |
| Sage | arcana or history (expert) |
| Sailor | places (Dock Ward, expert), underworld (smuggling, proficient) |
| Soldier | city-basics (Guard/Watch, expert) |
| Urchin | underworld (proficient), places (expert) |
| City Watch | city-basics (expert), underworld (proficient) |
| Urban Bounty Hunter | underworld (expert), city-basics (proficient) |
| Faction Agent | factions (expert for own faction) |
| 2024 backgrounds (Farmer, Guard, Guide, Merchant, Scribe, Wayfarer, etc.) | map by nearest PHB 2014 equivalent |

## Other sources
- **Race/ancestry:** races-cultures, that people's section.
- **Divine class:** religion, their own temple at expert depth.
- **Arcane class:** arcana (proficient).
- **Faction:** factions, insider notes come from the DM in play.
- **Languages:** Thieves' Cant → underworld cant sigils. Racial languages → that community.

## Secret knowledge (never on public pages)
These are DM-gated. Only characters who meet the bar learn them, and they never appear in `docs/lore/` or `00-every-resident.md`.

| Secret | Who can know it | What they know |
|---|---|---|
| **Laeral is afflicted** | High History **and** high Arcana or Religion | The Death Curse wastes the once-raised. Laeral is centuries old and, by the old histories, has died and returned before. She began vanishing from public life about a month after the curse struck, which is about how long the wasting would take to show in someone that strong. Put together, she is almost certainly wasting. A deduction, not proof. |
| **The curse comes from Chult** | High Investigation ("people who know things") | Expeditions, sages and certain buyers are all looking toward Chult, far to the south. The curse's source is there. Nothing more specific: no Soulmonger, no Omu, no Acererak. |

### How the bar was set (decided 2026-11-19, apply to new characters)
- **"High" means proficient.** The DM said secrets go to characters with "high" History plus Arcana or Religion (Laeral), or "high" Investigation (Chult), and then chose **proficiency** as the bar. The other options were a +5 modifier, expertise only, or case by case.
- **Why proficiency:** at level 1, nobody has expertise in these skills, and a modifier bar would hinge on ability scores rather than training. Proficiency reflects what the character has actually studied or done.
- **How to apply it:** check the character's proficiency and expertise list (`modifiers` of type `proficiency`/`expertise`) for the exact skills. Proficiency from any source counts: class, background, race or feat. Ability scores and modifiers don't matter. Laeral needs **History AND (Arcana OR Religion)**. Chult needs **Investigation**.
- **Results so far:** Nixy gets both (History, Arcana, Investigation). Finnian gets Chult (Investigation; History alone isn't enough for Laeral). Hadrian gets neither (Arcana without History, and no Investigation).
- **Delivery:** a hidden page per qualifying character at `docs/s/<first-name>-<16 random hex>.md`. It isn't linked from the site and is excluded from nav, search and sitemap. The DM sends the link privately. Anyone browsing the repo could still find it, and the DM accepted that. See step 6 in `CLAUDE.md`.
- If a character gains a qualifying proficiency later (e.g. through a feat at a level-up), they qualify then. Re-check on level-ups if the DM asks.
