# appstorrent — данные для публикации

## Поля формы

- **Название:** Verto
- **Разработчик:** Павел Бобро (Pavel Bobro)
- **Категория:** Утилиты / Перевод
- **Языки интерфейса:** русский, английский
- **Системные требования:** macOS 26 и новее
- **Архитектурная совместимость:** ARM (Apple Silicon), x86_64 (Intel), universal binary
- **Репозиторий:** https://github.com/PavelBobro/Verto
- **Changelog:** https://github.com/PavelBobro/Verto/releases/tag/v0.3.1
- **Скачивание (DMG):** https://github.com/PavelBobro/Verto/releases/latest/download/Verto-0.3.1.dmg
- **Скачивание (ZIP, запасной вариант):** https://github.com/PavelBobro/Verto/releases/latest/download/Verto-0.3.1.zip
- **Иконка:** `assets/icon-1024.png` (RGBA); `assets/icon-1024-flat.png` (RGB, без прозрачности)
- **Фон:** `assets/background-742x360.png` (есть версия 1484×720)
- **Скриншоты:** `screenshots/01-ru-to-en.png`, `02-en-to-ru.png`, `03-settings.png`
- **Реклама и платежи:** отсутствуют. Приложение бесплатное, без встроенных покупок и скрытых платежей.
- **Описание:** `description-ru.txt` (чистый текст, без ссылок и эмодзи)

## Что важно знать перед отправкой

- Приложение подписано ad-hoc, без платного сертификата Apple. При первом запуске macOS может попросить **System Settings → Privacy & Security → Open Anyway**.
- ZIP — исторически рекомендуемый формат для неподписанного Verto: он распаковывается, а предупреждение Gatekeeper появляется уже при запуске. DMG нужен, если каталог требует именно его.
- Скриншоты сделаны из приложения; все три — 720×600, RGB, без альфа-канала.
- Иконка 1024×1024 RGBA; если каталог не принимает прозрачность, используйте `icon-1024-flat.png`.

## Текст описания

См. `description-ru.txt`.
