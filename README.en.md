# Clean Your Phone

[Русский](README.md) | **English**

Step-by-step removal of preinstalled bloatware and ads from an Android phone over ADB, guided by an
AI assistant. No root, no flashing, everything is reversible.

Built first for **Xiaomi / Redmi / POCO (HyperOS, MIUI)**, where the ads are worst, but it works on
almost any Android phone: Samsung, realme, OPPO, Motorola, Pixel and others.

> The assistant talks to you in your own language, whatever language you write in.

## What you get

- No ads in system apps, on the lock screen or in "recommendations".
- The phone stops downloading games and "partner" apps on its own.
- Preinstalled games and the manufacturer's ad-laden duplicates (browser, music, video, "Cleaner")
  are gone.
- Calls, SMS, camera, gallery, Play Store, your browser and everything you installed yourself stay.

## How it goes

The assistant walks you through 10 steps and waits for your answer after each one:

1. What you need (a computer, a cable or Wi-Fi, the adb tool)
2. Turn on developer mode, with instructions for your brand
3. Connect the phone by cable or by Wi-Fi pairing code
4. Back up and look around: what the manufacturer installed and what you installed
5. Which of the usual "bloat" you actually use
6. **How deep to go:** ads only / standard / maximum / your own list
7. Shows the list in plain words and waits for your "yes"
8. Removes it and checks that calls, SMS and the camera still work
9. Opens the right settings screens on the phone and tells you which switch to turn off
10. Optional: ad-blocking DNS, 60 Hz and shorter animations for battery; how to undo everything

It takes 20–40 minutes, with 4–6 questions to answer.

## How to run it

### Claude Code: one command

Paste into a terminal. It installs or updates the plugin, creates a folder for backups
(`Documents\cleanyourphone` or `~/cleanyourphone`) and starts the guided cleanup right away.

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/posp3h/cleanyourphone/main/start.ps1 | iex
```

macOS / Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/posp3h/cleanyourphone/main/start.sh | sh
```

Claude Code must be installed (if it isn't, the command tells you how). Run it again for the next
phone: the plugin gets updated on the way.

### Claude Code: by hand or in the Claude app

Install once:

```
/plugin marketplace add posp3h/cleanyourphone
/plugin install cleanyourphone@cleanyourphone
```

Run it (no need to connect the phone first, the assistant tells you when):

```
/cleanyourphone:debloat-phone
```

Or just say: "clean the ads off my Redmi phone".

> Without the plugin: clone the repo and copy `skills/debloat-phone` into `~/.claude/skills/`
> (Windows: `%USERPROFILE%\.claude\skills\`). The command is then `/debloat-phone`.

### Other AI assistants

Clone the repo, open your assistant (Codex, Gemini CLI, Cursor and so on) in its folder and paste:

```
I want to remove preinstalled bloatware and ads from my Android phone over ADB.
Phone: <brand and model, e.g. Redmi Note 14>. For: <myself / my mom / a child>.

Open skills/debloat-phone/SKILL.md in this folder and guide me through it strictly step by step,
from "Step 1 of 10" to "Step 10 of 10". Talk to me in English. I may never have used ADB, so explain
every action in plain words and wait for my answer after each step.

Rules you must not break:
- remove nothing until I have approved the list;
- never touch packages in skills/debloat-phone/lists/protected.txt;
- do not remove apps I installed myself unless I name them;
- remove only with `pm uninstall -k --user 0` (reversible), no root, no flashing;
- back up the package list first, and tell me at the end how to undo everything;
- never write my IP addresses, serial numbers, e-mails or Wi-Fi names into files or reports.
```

([PROMPT.md](PROMPT.md) has the same text in Russian.)

## Safety

- Apps are removed for the user only (`pm uninstall -k --user 0`): the file stays in the firmware, and
  one command or a factory reset brings it back.
- The "never touch" list is [protected.txt](skills/debloat-phone/lists/protected.txt). The script
  refuses to run if anything from it ends up in the plan.
- Nothing is removed without your confirmation. Apps you installed yourself are not offered for removal.
- Every action is logged; [restore](skills/debloat-phone/scripts/) puts everything back.

## Bring an app back

```
adb shell cmd package install-existing <package.name>   # removed
adb shell pm enable <package.name>                      # disabled
```

Or everything at once: `scripts/restore.ps1 -Serial <phone> -Log backups/.../uninstall-log.tsv`.

## What's inside

| Path | What it is |
|---|---|
| `skills/debloat-phone/SKILL.md` | The 10-step script the assistant follows |
| `skills/debloat-phone/lists/` | Package lists by level: Xiaomi, Google, partner apps, protected |
| `skills/debloat-phone/scripts/` | `apply` runs the plan, `restore` undoes it, `origin` tells who installed each app |
| `examples/` | Real phones that were cleaned: what was removed and what came up |
| `PROMPT.md` | The prompt for other AI assistants (Russian) |
| `start.ps1`, `start.sh` | One-command start in Claude Code |

To add your phone to `examples/`, follow [redmi-17-hyperos3.md](examples/redmi-17-hyperos3.md), without
IP addresses, serial numbers or account names.

## License

MIT, see [LICENSE](LICENSE). Use it, change it and share it freely.
