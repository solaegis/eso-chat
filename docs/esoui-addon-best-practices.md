# ESOUI AddOn Best Practices

Internal reference for all addons developed under this account. Merges the verbatim rules from the ESOUI "Released AddOns" forum sticky threads with technical manifest detail confirmed against the ESOUI Wiki.

Source threads: [Released AddOns forum](https://www.esoui.com/forums/forumdisplay.php?f=170)

---

## 1. Manifest (`.txt`) technical requirements

Source: [Addon manifest (.txt) format](https://wiki.esoui.com/Addon_manifest_(.txt)_format), ESOUI Wiki.

**File encoding**
- UTF-8 without BOM. UTF-8-BOM and ANSI cause loading issues.
- No line longer than 301 bytes. Anything beyond that is silently ignored by the client.

**Mandatory directives**
- `## Title:` — display name, max 64 characters.
- `## AddOnVersion:` — positive integer only (`1`, `2`, `3`, not `3.4` or `r5`). ESO parses it with C `atoi`, so `3.1` and `3.2` both resolve to `3`. Don't rely on decimals to signal precedence.
- `## APIVersion:` — six-digit value matching the client's API version. Up to two values allowed, space-separated, to support Live and PTS simultaneously (e.g. `100026 100027`).

**Situational directives**
- `## DependsOn:` — space-separated, case-sensitive folder names. A missing hard dependency blocks the addon from loading at all.
- `## OptionalDependsOn:` — same idea, but a missing entry doesn't block loading. Use it for load-order control only.
- `## IsLibrary: true` — set this on library/support addons so ESOUI files them under Libraries rather than AddOns.
- `## Version:` — free-form string for ESOUI/Minion release tracking, not an in-game directive.

**SavedVariables**
- Names are global, not addon-scoped. Never reuse another addon's SavedVariables name. Prefix with your addon's name.
- Create the SavedVariables table inside your `EVENT_ADD_ON_LOADED` handler, not earlier.
- `## DisableSavedVariablesAutoSaving: 0` controls whether the client's periodic autosave (added in Murkmire/100025, capped at 50kB and a 4ms write budget) considers this addon's data.

**Dependency loading**
- Never manually load a dependency's files from within your own manifest's file list. Either declare it via `DependsOn`/`OptionalDependsOn` and let ESO resolve it, or bundle the dependency's folder properly in your `AddOns` directory. ESO checks for folder names that duplicate declared dependencies.

**Licensing boilerplate**
Standard disclosure most authors include:
```
# This Add-on is not created by, affiliated with, or sponsored by, ZeniMax Media Inc. or its affiliates.
# The Elder Scrolls® and related logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States
# and/or other countries. All rights reserved.
```

---

## 2. Before releasing a new addon or updating an existing one

**Addon review**
All submitted addons are subject to review. Problematic or inappropriate code, text, images, or missing required credits/attributions can get an addon placed into **"On Hold"** status. While on hold, the addon is unavailable for download. Check private messages regularly so issues get addressed promptly.

**AI disclosure**
- If AI generated code and you cannot personally verify it's correct, efficient, maintainable, and safe, you **must** disclose this at the top of your addon description.
- If AI was only used for brainstorming, research, or idea generation, and you personally wrote, reviewed, and validated the final code, disclosure is optional.
- Credit any code, concepts, assets, or information derived from other addons, developers, or external resources, whether you found the source directly or through AI-assisted research.

**Policy compliance**
Review ESOUI's and ZOS's rules on prohibited addon functionality before releasing. If your addon might fall into a prohibited category, don't release it until you've discussed it with ESOUI staff and gotten clarification from ZOS where appropriate.

**Dependencies**
If you add non-optional dependencies (`DependsOn`, `PCDependsOn`, `ConsoleDependsOn`), always list them clearly in your addon description, preferably at the top, so users know what to install.

---

## 3. Console-only addons

esoui.com is a PC addon repository. If you upload a console-only addon, you must:

1. Set the **main category** to **"Outdated & Discontinued"** so it doesn't appear in regular PC addon listings or in Minion, until a dedicated console-only category exists.
2. Set the **subcategories** to the addon's real categories.
3. **Disable** functionality for patches and addons built on top of this one.
4. State clearly, in the first line of the description, that this is a **console-only addon, not for PC use** (unless the reader is a developer testing via the force-console-flow command).

---

## 4. Intellectual property and malicious code

**Not acceptable, ever:**
- Stealing addon code or ideas without asking permission.
- Removing or changing author credits, i.e. taking someone's work and renaming it under your own name.
- Failing to credit the original addon and author(s) in your description.
- Skipping the step of contacting the original author to ask if your plan is okay.
- Publishing on console without permission, even if the original author simply hasn't released there themselves. **A no is a no.**

**Hidden features, blacklists, paywalls**
- Blacklisting other players is considered malicious with no legitimate use case. Block the individual player if needed; don't degrade the experience for everyone else.
- Paywalled addons aren't tolerated. Nobody should have to pay for addons built on stolen work.

**Licensing**
- Read the addon's license before touching its code. This isn't optional, it's a legal requirement.
- If the license prohibits copying or altering the code, that's final. Don't look for a workaround.
- If the license permits reuse, follow its terms and include the license text in your fork/copy if required.
- Never take code or ideas without asking. Always give proper credit.

---

## 5. Removing or discontinuing an addon/library

### If you are the author

Before deleting or discontinuing:
- If the addon is widely used, consider finding a maintainer instead. Post a request in the appropriate forum.
- If it's a library used by other addons, don't just remove it. Talk to the dependent developers and find a solution first.

**Process:**
1. Don't rely on forum threads or addon comments alone. Comments aren't monitored and won't get a response.
2. Update the addon's name, description, and changelog to show it's no longer to be used. State why, and link working alternatives if you know of any.
3. Optionally update the addon comments too, since many users check comments before description/changelog.
4. To move the addon to discontinued status: PM an esoui.com moderator (Dolby, Cairenn, Baertram) with the addon link, asking to set it to **"Discontinued & Outdated"**. This keeps Minion from finding it.
5. To remove the addon entirely: PM a moderator with the link, requesting deletion. **Deletion removes everything** — description, changelog, files, comments — permanently.

### If you are not the author

1. PM the addon author with the link, describing in detail (with an example if possible) why you want it removed.
2. If the author doesn't respond within **3 weeks**, send the same information to a moderator, noting you contacted the author and got no response in that window.
3. Wait for a reply. Don't repost the same request in the forums out of impatience.

---

## 6. Handling abandoned addons, patches, and forks

**Before creating a patch or copy**
- Language patches: ask the original author first if they'll include your translations. If the addon lacks multi-language support, ask them to add it. Only build your own patch addon if they explicitly say go ahead.
- Check the addon's comments first; someone may have already posted a fix or replacement.
- For GitHub-hosted addons, try contacting the author there. Forking the repo does not by itself grant permission to release it as your own addon.
- No response after **2–4 weeks**? You may ask in the appropriate forum for help.

**Taking over an abandoned addon**
Multiple patches and versions of the same addon confuse users and can cause errors (e.g. Minion file corruption). Maintain the original addon rather than creating a copy, if at all possible.

- With the original author's approval, you can be added to the addon's team and continue maintaining it directly.
- If creating a patch instead, check the addon's "Other files" tab for "Upload optional patch" or "Upload optional addon". Name the patch with the original addon's name first, followed by something like "Updated <DLC>", so users understand what it's for.
- Ask admins (Dolby, Cairenn) via PM to add you to the team, forwarding the other developer's approval.

---

## 7. Pre-release checklist

- [ ] `AddOnVersion` bumped as an integer
- [ ] `APIVersion` matches current live client (and PTS, if dual-testing)
- [ ] Manifest is UTF-8 without BOM, no line over 301 bytes
- [ ] SavedVariables names are addon-prefixed and created in `EVENT_ADD_ON_LOADED`
- [ ] No manual loading of declared dependencies from within the manifest file list
- [ ] `IsLibrary: true` set correctly if this is a library, not a standalone addon
- [ ] Non-optional dependencies listed at the top of the addon description
- [ ] AI-generated code disclosed if you can't personally vouch for it
- [ ] Credit given for any reused code, concepts, or assets, sourced directly or via AI research
- [ ] Addon checked against ZOS/ESOUI prohibited-functionality rules
- [ ] Changelog updated
- [ ] License terms stated and honored if this is a fork, patch, or derivative
- [ ] Platform compatibility (PC/console) tagged and described correctly, console-only addons filed under "Outdated & Discontinued" until a dedicated category exists

---

*Section 1 is sourced from the ESOUI Wiki. Sections 2 through 6 are sourced from the verbatim text of the ESOUI "Released AddOns" sticky threads. Re-check the original threads periodically, since moderators update them.*
