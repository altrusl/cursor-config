Проблему с зависанием `Install in SSH` на `altay-mini-pc` поднял и починил без `iptables`.

Что сделал:
- Обновил `proxyctl` в `/home/altay/.local/bin/proxyctl`:
  - `on/off` теперь переключает не только SOCKS-туннель, но и прокси-настройки самого Remote Cursor Server.
  - `proxyctl` теперь также поддерживает управляемый wrapper `~/.local/bin/git`, который перед каждым вызовом `git` автоматически применяет текущее состояние `~/.config/proxyctl/proxy-env.sh` (чтобы `git push` не застревал на старом proxy env после `off`).
  - На `on` пишет в `/home/altay/.cursor-server/data/Machine/settings.json`:
    - `http.proxy = socks5://127.0.0.1:1080`
    - `http.proxySupport = override`
    - `http.noProxy = [localhost, 127.0.0.1, ::1]`
  - На `off` восстанавливает прошлые значения из бэкапа.
- Добавил fallback-утилиту `/home/altay/.local/bin/cursor-ext-install` для установки расширений через прокси из SSH, если UI снова подвиснет.
- Проверил туннель: `proxyctl test` показывает выход через Istanbul (`185.207.3.9`).
- Проблемные расширения реально установились:
  - `mkxml.vscode-filesize@3.2.2`
  - `blono.git-last-commit-message-fork@1.9.2`

Что делать тебе сейчас:
- В SSH-сессии держать режим включенным: `proxyctl on`
- В Cursor (Windows) сделать `Developer: Reload Window`  
  (лучше: `Remote-SSH: Kill VS Code Server on Host...` и переподключиться к `altay-mini-pc`)
- После этого снова пробовать `Install in SSH`

Если UI опять зависнет:
- Ставь напрямую командой:
  - `cursor-ext-install <publisher.extension>`
  - пример: `cursor-ext-install ms-python.python`

Отключение режима:
- `proxyctl off`

Важно:
- Для `git` ручной `source ~/.config/proxyctl/proxy-env.sh` больше не нужен (wrapper применяет режим автоматически).
- Для остальных CLI-инструментов (`curl`, `gh`, etc.) ручной `source` все еще нужен в уже открытой shell-сессии.