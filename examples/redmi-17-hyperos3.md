# REDMI 17 — HyperOS 3.0, Android 16

- Модель: `2606FRN72Y` (`leedsa_n_eea`), прошивка `OS3.0.308.0.WDTEUXM`, ноябрь 2026
- Для кого: пожилой человек. Уровень: 3 (максимум) с исключениями
- Подключение: Wi-Fi с кодом сопряжения. Mi- и Google-аккаунтов нет, «Отладка по USB (настройки безопасности)» выключена
- Звонки/SMS по умолчанию: Google Телефон и Google Сообщения

## Итог

- Удалено 51 приложение, отключено 4 (защищены от удаления: `com.xiaomi.midrop`, `com.xiaomi.scanner`, `com.miui.compass`, `com.miui.screenrecorder` → `Failure [-1000]`)
- Оставлены по просьбе: Instagram, Gmail, Google Фото, Погода, FM-радио, Календарь, Заметки
- Руками: реклама в «Темах» (2 переключателя), рекламный ID Google, «-1 экран»
- В «Безопасности», «Проводнике», «Погоде» рекламных переключателей уже не было (ушли вместе с msa)
- 60 Гц через `settings put system` — сработало; анимации 0,5x — руками
- Private DNS AdGuard работал, но вернули «Автоматически»: телефон уезжал в другую страну

## Что всплыло

- Без «настроек безопасности»: `settings put global` и `input keyevent` запрещены; `settings put system`, `am start`, `pm` — работают
- После включения упрощённого режима выключился режим разработчика (`development_settings_enabled=0`), ADB по Wi-Fi при этом держался
- Вкладка «Обновление» в Настройках вела в удалённый `com.xiaomi.discover` — перестала открываться; обновление прошивки — через логотип HyperOS
- `screencap` отдавал почти пустой файл — проверяли через `dumpsys activity`
- Spotify упал в момент удаления — нормально

## Удалённые пакеты

```
com.zhiliaoapp.musically com.oakever.tiletrip com.mintgames.triplecrush.tile.fun
com.ordinaryjoy.woodblast com.block.puzzle.game.hippo.mi com.jewelsblast.ivygames.Adventure.free
com.logame.eliminateintruder3d com.sukhavati.gotoplaying.bubble.BubbleShooter.mint
com.mintgames.wordtrip com.vitastudio.mahjong com.block.juggle com.nf.snake com.spotify.music
com.facebook.katana com.facebook.appmanager com.facebook.services com.facebook.system
cn.wps.xiaomi.abroad.lite com.microsoftsdk.crossdeviceservicebroker com.orange.update
android.autoinstalls.config.Xiaomi.model com.miui.msa.global com.miui.analytics com.xiaomi.mipicks
com.xiaomi.discover com.miui.cotaservice com.mi.globalminusscreen com.miui.android.fashiongallery
com.miui.cleaner com.mi.globalbrowser com.miui.player com.miui.videoplayer com.miui.yellowpage
com.xiaomi.glgm com.mi.global.shop com.xiaomi.smarthome com.miui.huanji com.miui.bugreport
com.miui.miservice com.xiaomi.barrage com.miui.thirdappassistant com.android.egg
com.google.android.apps.bard com.google.android.apps.docs com.google.android.apps.subscriptions.red
com.google.android.apps.tachyon com.google.android.apps.youtube.music com.google.android.videos
com.google.android.apps.magazines com.google.android.projection.gearhead com.google.ambient.streaming
```
