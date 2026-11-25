---
name: debloat-phone
description: Step-by-step removal of preinstalled bloatware and ads from an Android phone over ADB (Xiaomi/Redmi/POCO on HyperOS and MIUI first, but works on almost any Android). Use when someone asks to clean up or debloat a phone, remove ads or unwanted apps, or set up a phone for a parent or an elderly person.
---

# Debloating an Android phone over ADB, step by step

You are guiding someone who may never have used ADB. They see the phone; you see only what `adb`
returns. Work like a patient technician at the kitchen table.

## How to run the session (mandatory)

- **Speak the user's language.** Commands stay in English; explanations are in their language.
  Menu names below are given as they appear on an English-language phone: translate them to how
  they appear on the user's phone, and if unsure, describe where the item is rather than guessing a
  label.
- **Format every step the same way:** a heading `Step N of 10: <name>`, one or two sentences on why,
  then the actions as a numbered list, then "what you should see". Do not move to the next step until
  the current one is confirmed.
- **Ask multiple-choice questions** with a button tool (AskUserQuestion or similar) if you have one;
  otherwise as a numbered list ("reply with a number").
- **Remove nothing until the person has approved the list.** Approval of one list does not carry over
  to the next.
- **Check, don't assume.** After every action look at the result (`pm list packages`, `dumpsys`,
  launching the app). Only call something done once you have checked it.
- **Never invent what a package does.** If you don't know, read `dumpsys package <pkg>` (activities,
  services, permissions) and ask. Unknown means hands off.
- **Secrets.** Never put IP addresses, serial numbers, Wi-Fi names or account e-mails into reports or
  files. Use `<phone ip>` in files.
- Save every artifact under `backups/<model>-<YYYY-MM-DD>/` in the working directory.

Files next to this SKILL.md:

| File | What it is |
|---|---|
| `lists/protected.txt` | **Never touch.** Removing these breaks booting, calls, SMS or Play. |
| `lists/xiaomi.txt` | Xiaomi/Redmi/POCO (HyperOS/MIUI), with a level and a note for every package. |
| `lists/google.txt` | Google apps that can usually go. |
| `lists/partners.txt` | Partner apps and games that manufacturers are paid to preinstall. |
| `scripts/apply.sh`, `scripts/apply.ps1` | Applies the approved list, writes a log, falls back to "disable" when removal is refused. |
| `scripts/restore.sh`, `scripts/restore.ps1` | Puts everything back from the log. |
| `scripts/origin.sh`, `scripts/origin.ps1` | Splits non-system apps into: shipped with the phone / pulled in during setup / installed by the user. |

---

## Step 1 of 10: What you need

Explain and check:

1. A computer (Windows / macOS / Linux) and a phone charged to at least 50%.
2. **Android Platform Tools (adb).** Check `adb version`. If missing:
   - Windows: `winget install Google.PlatformTools`
   - macOS: `brew install android-platform-tools`
   - Linux: `sudo apt install adb` (or your distribution's package)
   - Or by hand: https://developer.android.com/tools/releases/platform-tools
3. A USB cable **that carries data** (some cables only charge), or a shared Wi-Fi network for a
   wireless connection (Android 11+).
4. Make clear: everything is done for the phone's main user only, with no root and no flashing.
   A factory reset brings everything back, and each removed app can also be restored with one command.

## Step 2 of 10: Turn on developer mode

Ask for the phone's brand if you don't know it, and give the instructions for that brand:

| Brand | Tap 7 times on | Then "Developer options" is at |
|---|---|---|
| Xiaomi / Redmi / POCO (HyperOS) | Settings → About phone → **OS version** (on some: "Detailed info and specs" → "OS version") | Settings → Additional settings → Developer options |
| Xiaomi (MIUI 12–14) | About phone → **MIUI version** | Additional settings → Developer options |
| Samsung | About phone → Software information → **Build number** | at the bottom of the main Settings list |
| Google Pixel, Motorola, Nokia | About phone → **Build number** | System → Developer options |
| OnePlus / OPPO / realme | About device → Version → **Build number** | Additional settings → Developer options |
| Honor / Huawei | About phone → **Build number** | System & updates → Developer options |

Then turn on **"USB debugging"** in Developer options.

**On Xiaomi, explain "USB debugging (Security settings)" separately:**
- Without it you CAN remove and disable apps. You CANNOT change protected settings
  (`settings put global/secure`), tap the screen over ADB or revoke permissions. That is fine: the
  person flips those switches by hand and you open the right screen for them.
- To turn it on, Xiaomi requires a SIM card and a signed-in Mi account. There is no way around it
  without root (`setprop persist.security.adbinput 1` is refused from the shell). Don't push the
  person into creating an account.

## Step 3 of 10: Connect the phone

Ask which is easier and walk through one option:

**A. Cable (most reliable).**
1. Plug it in; in the notification shade pick USB mode "File transfer".
2. The phone shows "Allow USB debugging?" → tick "Always allow from this computer" → "Allow".
3. You: `adb devices -l` → it must say `device` (not `unauthorized`).
   - Empty on Windows: check `Get-PnpDevice -PresentOnly | ? FriendlyName -match 'Android|ADB'`;
     try another cable or port, and "File transfer" mode.

**B. Wi-Fi (Android 11+, no cable).**
1. Developer options → **"Wireless debugging"** → on.
2. Inside it → **"Pair device with pairing code"**. The person reads out the IP:port **from that
   dialog** and the 6-digit code.
3. You: `adb pair <ip>:<pairing port> <code>`.
4. Then the port shown on the main "Wireless debugging" screen (it's a different one!):
   `adb connect <ip>:<port>`.
5. "failed to connect" while the port is open means the computer hasn't been paired yet. The port
   changes each time Wireless debugging is switched on; pairing again is not needed after that, only
   the new port.

With more than one device connected, always use `adb -s <serial>`.

## Step 4 of 10: Get to know the phone and back it up

```
adb shell getprop ro.product.marketname   # or ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.mi.os.version.name    # HyperOS; for MIUI: ro.miui.ui.version.name
adb shell getprop ro.build.version.incremental
adb shell pm list packages -f -u   > packages-all-before.txt
adb shell pm list packages -3      > packages-3rd-before.txt
adb shell pm list packages -d      > packages-disabled-before.txt
adb shell cmd role get-role-holders android.app.role.DIALER
adb shell cmd role get-role-holders android.app.role.SMS
adb shell cmd role get-role-holders android.app.role.HOME
adb shell cmd role get-role-holders android.app.role.BROWSER
```

Then split the non-system apps by origin: `scripts/origin.ps1 -Serial <s> -Out origin.tsv`
(or `origin.sh <s> > origin.tsv`):

| origin | Meaning | What to do |
|---|---|---|
| `preinstalled` | in the firmware, or installed by the manufacturer's or carrier's store | candidate for removal by level |
| `setup-autoinstall` | pulled in during the first 2 hours (first setup: GetApps, Play "recommended apps") | candidate, but show it as its own group and ask |
| `user` | the person installed it from the Play Store | **never offer for removal.** Show it as "your apps"; touch it only if the person names it |
| `sideload` | installed from an APK file | don't touch, ask |
| `unknown` | could not tell | ask |

On a phone that is already in use (accounts signed in, games installed by the person), this is the
main rule: **games and apps the person installed are theirs, not bloat**, even when they look
preinstalled. Be careful with `setup-autoinstall`: if the person restored apps from a Google backup
during setup, their own apps land here too. App data is not visible over ADB without root, so ask
whenever in doubt.

Check what ADB is allowed to do (steps 9–10 depend on it):
```
adb shell settings put global cyp_probe 1 && adb shell settings delete global cyp_probe
```
Success: "Security settings" are on (or this isn't a Xiaomi), so DNS, animations and the like can be
changed by command. `SecurityException`: by hand only, and you open the screens. Also find out
whether accounts exist: `dumpsys account | grep -E 'Accounts:|Account \{'` (account types only; keep
addresses out of reports). With a Google account, the apps needed at the end can be installed from
Play right away; with a Mi account, "Security settings" can be turned on and more done over ADB.

Save everything to `backups/<model>-<date>/`. Give the person a short summary: model, Android and
skin version, how many packages in total, how many non-system ones, and which apps currently handle
calls, SMS, the home screen and the browser. **Packages holding these roles are protected** for the
rest of the session (for example, if the dialer is `com.google.android.dialer`, it stays even if a
list names it).

## Step 5 of 10: What matters to the person (before any list)

Ask (with buttons, several answers allowed):

1. **Who is the phone for?** Myself / an elderly person / a child. For an elderly person: fewer apps,
   but change nothing they are used to (launcher, dialer) without asking.
2. **Which of the usual "bloat" do they actually use?** Build the list from what is really installed:
   social networks (Instagram, Facebook, TikTok), music (Spotify, YouTube Music), Mi Fitness / a
   fitness band, FM radio, weather, the manufacturer's calendar, Gmail, Google Photos, Google Drive,
   Gemini, ShareMe / Quick Share, Mi Home and so on. Anything ticked becomes an exception.
3. **May accounts be signed in** (Google, Mi)? This decides what can be installed at the end.

## Step 6 of 10: Choose how deep to go

Offer four options (with buttons) and explain the difference in plain words:

| Level | What we do | For whom |
|---|---|---|
| **1. Ads only** | Disable (not remove) ad and analytics services, automatic app installs, the lock-screen wallpaper carousel and recommendation feeds. Every app stays. | People afraid of breaking something, or who use the manufacturer's apps |
| **2. Standard** (recommended) | Level 1 + remove preinstalled games and partner apps and the manufacturer's ad-laden duplicates (browser, music, video, "Cleaner", app store). | Most people |
| **3. Maximum** | Level 2 + unneeded Google apps and manufacturer services the phone works without (data transfer, scanner, compass, feedback, built-in app updates). | Minimalists; a "calls + camera + messengers" phone |
| **4. Your own list** | Show everything found by category; the person ticks what goes. | Experienced users |

The exceptions from step 5 and the protected list apply at every level.

## Step 7 of 10: Build the list and agree on it

1. Take every installed package (`pm list packages`) and match it against:
   - `lists/protected.txt`: drop from consideration entirely;
   - `lists/xiaomi.txt`, `lists/google.txt`, `lists/partners.txt`: each line has a level `L1/L2/L3`
     and an action `disable`/`uninstall`; take the lines with a level ≤ the chosen one;
   - non-system apps (`-3`) that are in no list are usually partner games/apps: describe each one by
     name (`dumpsys package <pkg> | grep -m1 versionName`, the package name) and treat it as L2;
   - for other manufacturers (Samsung, Oppo, realme, Transsion…) classify by the same categories
     yourself. You may cross-check the Universal Android Debloater Next Generation list
     (https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation,
     file `resources/assets/uad_lists.json`): take only packages marked `Recommended`; `Advanced`,
     `Expert` and `Unsafe` only at level 4, with the risks explained.
2. Remove the exceptions from step 5, the role holders from step 4 and everything with
   `origin = user` / `sideload`. If a package is on a bloat list but `origin = user` (the person
   installed TikTok themselves), it stays.
3. Write the result to `backups/.../plan.txt` (one package per line, `#` for group comments).
4. Show it to the person **in groups, with human names**, not just package names:
   "Games (11): Mahjong, Wood Blast…", "Xiaomi ads: msa, the ad service that shows banners in every
   Xiaomi app", and so on. Add a separate "Keeping" block with what definitely stays.
5. Ask 1–3 follow-up questions on the debatable items (weather, calendar, radio…) and wait for "yes".

Explain up front that the manufacturer's Weather app is better kept: the "clock + weather" widget and
the weather on the lock screen depend on it, and its ads disappear together with the ad service.

## Step 8 of 10: Remove and check

1. Apply with the script: `scripts/apply.sh <serial> plan.txt` (macOS/Linux) or
   `scripts/apply.ps1 -Serial <serial> -Plan plan.txt` (Windows). It:
   - removes with `pm uninstall -k --user 0` (reversible: `cmd package install-existing <pkg>`),
     and lines marked `disable` with `pm disable-user --user 0`;
   - disables instead when removal is refused (`Failure [-1000]`, Xiaomi's protection);
   - runs one package per call and writes `uninstall-log.tsv` next to the plan.
   Split big lists into 2–3 batches (ads → games → the rest) and check between them.
2. After each batch, check that the essentials still work:
   ```
   adb shell monkey -p <pkg> -c android.intent.category.LAUNCHER 1
   ```
   for the dialer, SMS, camera, gallery, Play Store, browser and home screen (`am start -a
   android.intent.action.MAIN -c android.intent.category.HOME`). `Events injected: 1` means OK.
   Look at `adb shell logcat -d -b crash | grep 'Process:'`: apps crashing while they are being
   removed (Spotify and the like) are normal; system apps crashing are not, so restore the last batch.
3. Report: N removed, M disabled, K failed (with the reason).

## Step 9 of 10: Ads in the remaining system apps

Some switches can only be flipped by hand. Don't recite menu paths: **open the screen yourself** and
say what to tap. To find a screen:
`dumpsys package <pkg> | grep -o '<pkg>/[A-Za-z0-9_.$]*Setting[A-Za-z0-9_.$]*'`; to open it:
`am start -n <pkg>/<activity>`. If `am start` returns `Permission Denial`, the screen can only be
opened from the phone, so describe the path in words.

Xiaomi (HyperOS 3, tested):

| App | Screen | What to turn off |
|---|---|---|
| Themes | `com.android.thememanager/.activity.ThemeSettingsActivity` | "Show ads", "Personalized recommendations" |
| Security | `com.miui.securitycenter/com.miui.securityscan.ui.settings.SettingsActivity` | "Receive recommendations" (may be gone once msa is removed, which is fine) |
| Weather | `com.miui.weather2/.ActivityWeatherMain` → ⋮ → Settings | anything about news/content (recent versions no longer have it) |
| File Manager | open the app → ☰ → Settings | "Receive recommendations" |
| Home screen | `com.miui.home/.settings.MiuiHomeSettingActivity` | recommendations in folders, the "-1 screen"/feed (Simple mode doesn't have these items) |
| Google ads | `com.google.android.gms/.adsidentity.settings.AdsIdentitySettingsActivity` | "Delete advertising ID"; "Ad privacy" → everything off |
| Lock screen | Settings → Lock screen | if a carousel icon/feed is left, set an ordinary wallpaper |

Samsung: Settings → Privacy → Customization Service (off); Galaxy Store → Settings → marketing
notifications (off); disable Samsung Free / Samsung Daily. Other brands: look for "recommendations",
"personalized content" and "ads" in the settings of the system apps.

## Step 10 of 10: Extras and wrapping up

Offer as options (each as its own question):

- **Ad-blocking DNS** (AdGuard): Settings → Connection & sharing (or "Network & internet") → Private
  DNS → `dns.adguard-dns.com`. **Always warn:** in "hostname" mode, if the server becomes unreachable
  (blocked in a country, by a carrier, while travelling), the internet stops working altogether;
  calls and SMS still work. For elderly people with no helper nearby, recommend leaving it on
  "Automatic". To check it works: `dumpsys connectivity | grep -o 'PrivateDnsServerName: [^ ]*'` and
  `ValidatedPrivateDnsAddresses`. It can be set over ADB only with "Security settings" on
  (`settings put global private_dns_mode hostname` + `private_dns_specifier`); otherwise open
  `com.android.settings/.network.PrivateDnsSettingsActivity`.
- **Battery and smoothness:**
  - 60 Hz screen (works without "Security settings" on Xiaomi):
    `settings put system miui_refresh_rate 60`, `user_refresh_rate 60`, `peak_refresh_rate 60`,
    `min_refresh_rate 60`, `is_smart_fps 0`; check with `dumpsys display | grep mActiveRenderFrameRate`.
    Other brands: `settings put system peak_refresh_rate 60` and `min_refresh_rate 60`;
  - animations at 0.5x: Developer options → Drawing → the three "animation scale" items → 0.5x
    (or `settings put global window_animation_scale 0.5` and so on, if permitted);
  - don't restrict background activity unless asked: messengers start delivering notifications late.
- **Simple mode** (Xiaomi: Settings → Special features / Simple mode) for elderly people. Note that
  it can switch developer mode off (`settings get global development_settings_enabled` = 0); the
  person then taps 7 times again.
- **Launcher:** don't replace it if the person is used to the stock one. It barely adds speed (the
  stock launcher keeps running under gestures and Recents) and it breaks habits.

Wrapping up:

1. A final summary: what was removed/disabled, what was set by hand, what is left to do (accounts,
   installing the needed apps from Play).
2. How to undo: `scripts/restore.ps1 -Serial <serial> -Log uninstall-log.tsv` / `restore.sh`, or a
   single app: `adb shell cmd package install-existing <pkg>` (a disabled one:
   `adb shell pm enable <pkg>`). A factory reset brings everything back.
3. Offer to switch off "Wireless debugging" (and "USB debugging" if the phone is going to someone else).

---

## Known pitfalls (from real sessions)

- **Xiaomi `Failure [-1000]`** when removing ShareMe, Scanner, Compass or Screen recorder: that's a
  protection. The script disables them instead; they disappear from the screen.
- **The "Update" tab in Xiaomi Settings** updates the built-in apps (`com.xiaomi.discover`), not the
  firmware. If discover is removed (level 3), the tab no longer opens. Firmware still updates via the
  HyperOS logo in "About phone" (`com.android.updater` is never touched). Without discover, Xiaomi's
  built-in apps only update together with the firmware. Warn about this in advance.
- **`settings put global …` → SecurityException, `input keyevent` → INJECT_EVENTS**: no "Security
  settings". `settings put system …`, `am start` and `pm uninstall/disable-user` still work.
- **`screencap` can return an empty or cropped frame.** Don't rely on screenshots: ask the person
  what they see, or check with `dumpsys activity activities | grep topResumedActivity`.
- **Without a Google account the Play Store installs nothing.** Don't suggest downloading APKs from
  third-party sites for someone else's phone: such apps don't update themselves.
- **Wi-Fi ADB drops** after the adb server restarts or the phone sleeps: run `adb connect <ip>:<port>`
  again; if the port changed, ask for the new one.
- **Never remove on Xiaomi** (bootloop or lost functions): `com.miui.securitycenter`,
  `com.lbe.security.miui`, `com.miui.securitycore`, `com.miui.guardprovider`, `com.miui.home`
  (unless another launcher is installed), `com.miui.system`, `com.miui.rom`, `com.miui.core`,
  `com.xiaomi.xmsf` (push notifications), `com.miui.powerkeeper`, `com.android.updater`. All of these
  are in `lists/protected.txt`.
