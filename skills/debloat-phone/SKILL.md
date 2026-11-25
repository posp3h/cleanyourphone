---
name: debloat-phone
description: Remove preinstalled bloatware and ads from an Android phone over ADB (Xiaomi/Redmi/POCO on HyperOS and MIUI first, works on most Android phones). Use when someone asks to debloat or clean up a phone, remove ads or unwanted preinstalled apps.
---

# Debloat an Android phone over ADB

Work on the real phone, verify everything you do, and ask only what depends on the person's
preferences.

Style
- Be brief. Short messages, no recaps of what you are about to do, no repeating these instructions
  back. One instruction block per message when the person has to act on the phone.
- Speak the person's language. Menu names below are English; use the phone's wording, or describe
  where the item is if unsure.
- Treat every phone as new. Don't carry assumptions from memory or earlier sessions; read the phone.
- At most three questions in the whole session, as checklists or buttons: how deep (Debloat), which
  of the found apps they use (Debloat), optional extras (Extras).
- Never write IP addresses, serial numbers, Wi-Fi names or account e-mails into files or reports.
  Keep artifacts in `backups/<model>-<YYYY-MM-DD>/` in the working folder.

Files here: `lists/protected.txt` (never touch), `lists/xiaomi.txt`, `lists/google.txt`,
`lists/partners.txt` (level `L1`–`L3` and action per package), `scripts/apply|restore|origin`
(`.sh` and `.ps1`).

Connect
- Check `adb version`. If missing, install it yourself: Windows `winget install
  Google.PlatformTools`, macOS `brew install android-platform-tools`, Linux the distro package;
  otherwise download platform-tools from developer.android.com/tools/releases/platform-tools into the
  working folder and use it from there.
- Developer mode: tap the build number 7 times (Xiaomi HyperOS: About phone → OS version; MIUI: MIUI
  version; Samsung: About phone → Software information → Build number; others: About phone → Build
  number), then Developer options → USB debugging on.
- Cable: USB mode "File transfer", accept "Allow USB debugging?". Wi-Fi (Android 11+): Developer
  options → Wireless debugging → Pair with pairing code; `adb pair <ip>:<pair port> <code>`, then
  `adb connect <ip>:<port>` with the port from the main Wireless debugging screen (a different one).
  "failed to connect" on an open port means not paired yet. The port changes each time Wireless
  debugging restarts; pairing doesn't need repeating.
- Xiaomi: "USB debugging (Security settings)" needs a SIM and a Mi account. Without it you can still
  remove and disable apps, but not `settings put global/secure` or input injection: the person flips
  those switches by hand and you open the screens. There is no workaround without root; don't push
  for an account.

Back up first
- Save `getprop`, `pm list packages -f -u`, `pm list packages -3`, `pm list packages -d` and the role
  holders (`cmd role get-role-holders android.app.role.{DIALER,SMS,HOME,BROWSER}`). Role holders are
  protected for this session.
- Run `scripts/origin.ps1 -Serial <s> -Out origin.tsv` (or `origin.sh <s>`). Apps with origin `user`
  or `sideload` were installed by the person: never offer them for removal. `setup-autoinstall` may
  include apps restored from their Google backup: list them separately.
- Probe permissions once: `settings put global cyp_probe 1 && settings delete global cyp_probe`.
  A `SecurityException` means protected settings are by hand only.

Debloat
- Ask how deep, with buttons: 1 Ads only (disable ad/analytics/auto-install services, nothing
  removed), 2 Standard (+ preinstalled games, partner apps, the maker's ad-laden duplicates),
  3 Maximum (+ unneeded Google apps and maker services), 4 Pick from the list.
- Build the plan from the lists up to that level, plus preinstalled non-system apps that are in no
  list (treat as L2, name each). Other brands: classify by the same categories; you may cross-check
  `uad_lists.json` from Universal Android Debloater Next Generation, taking only `Recommended`
  entries below level 4.
- Then one checklist question: which of the found apps they use (social networks, music, fitness
  band app, FM radio, weather, notes, calendar, cloud drives…). Ticked ones stay. Mention that the
  maker's Weather feeds the clock widget and lock screen.
- Show the final list grouped, with human names, in a few lines; apply after a "yes".
- Never touch `lists/protected.txt`; `scripts/apply` refuses such a plan. If a package's purpose is
  unclear, read `dumpsys package <pkg>` before deciding, and leave it if still unclear.
- Apply with `scripts/apply.ps1 -Serial <s> -Plan plan.txt` (or `apply.sh`; `-DisableOnly` for level
  1). It removes with `pm uninstall -k --user 0`, disables when removal is refused (Xiaomi
  `Failure [-1000]`), and logs to `uninstall-log.tsv`. Do it in 2–3 batches.
- After each batch, launch the dialer, SMS, camera, gallery, Play Store, browser and Home
  (`monkey -p <pkg> -c android.intent.category.LAUNCHER 1`) and check `logcat -d -b crash`. Crashes
  of apps being removed are normal; a system crash means restore the last batch.

Ads by hand
- Open each screen with `am start -n <pkg>/<activity>` and say only what to switch off. Find
  activities with `dumpsys package <pkg> | grep -o '<pkg>/[A-Za-z0-9_.$]*Setting[A-Za-z0-9_.$]*'`.
  `Permission Denial` means the screen opens only from the phone: give the path.
- Xiaomi (HyperOS 3): Themes `com.android.thememanager/.activity.ThemeSettingsActivity` (Show ads,
  Personalized recommendations); Security
  `com.miui.securitycenter/com.miui.securityscan.ui.settings.SettingsActivity` (Receive
  recommendations); Home `com.miui.home/.settings.MiuiHomeSettingActivity` (folder recommendations,
  -1 screen); Google ads `com.google.android.gms/.adsidentity.settings.AdsIdentitySettingsActivity`
  (Delete advertising ID). Weather and File Manager had no ad switches left once msa was gone.
- Samsung: Privacy → Customization Service off; Galaxy Store marketing notifications off.

Extras (one optional checklist)
- Private DNS `dns.adguard-dns.com` blocks most remaining ads. Warn: in hostname mode the internet
  stops if the server is unreachable (blocked country or carrier, travel); calls and SMS still work.
  For someone without a helper nearby recommend leaving it on Automatic. Screen:
  `com.android.settings/.network.PrivateDnsSettingsActivity`; by command only with permissions.
- 60 Hz: `settings put system` `peak_refresh_rate 60`, `min_refresh_rate 60` (Xiaomi also
  `miui_refresh_rate 60`, `user_refresh_rate 60`, `is_smart_fps 0`); check
  `dumpsys display | grep mActiveRenderFrameRate`. Animations 0.5x in Developer options → Drawing.
- Don't restrict background activity or replace the launcher unless asked.

Finish
- A short summary: removed, disabled, set by hand, left to do.
- How to undo: `scripts/restore.ps1 -Serial <s> -Log uninstall-log.tsv` (or `restore.sh`), one app
  `cmd package install-existing <pkg>` / `pm enable <pkg>`, or a factory reset.
- Offer to switch Wireless debugging off.

Pitfalls seen on real phones
- Xiaomi Settings "Update" tab is `com.xiaomi.discover` (built-in app updates), not the firmware.
  Removing it (level 3) kills the tab; firmware still updates via the HyperOS logo in About phone.
- After removing `com.mi.appfinder`, swipe-down on the Xiaomi home screen says "App not found": set
  `settings put system com.miui.home.preferences.launcher_pulldown_gesture no_action` (works without
  Security settings). The notification shade still opens from the top edge.
- Without AdGuard DNS, Xiaomi search showed ads again; that's why appfinder is L1.
- Xiaomi Simple mode can switch developer mode off (`development_settings_enabled` = 0).
- `screencap` may return an empty frame: ask what the person sees or check
  `dumpsys activity activities | grep topResumedActivity`.
- Without a Google account Play installs nothing; don't fetch APKs from third-party sites instead.
- Wi-Fi ADB drops after an adb server restart or phone sleep: `adb connect` again, ask for the new
  port if it changed.
