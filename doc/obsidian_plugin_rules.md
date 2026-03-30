# Obsidian Plugin Technical Rules

Источники: официальные гайдлайны Obsidian, PR #6427, #6313, #6603 в obsidian-releases.

---

## Безопасность

| Запрещено | Требуется |
|---|---|
| `innerHTML`, `outerHTML`, `insertAdjacentHTML` с user input | `createEl()`, `createDiv()`, `createSpan()`, `el.empty()` |
| Blind casting через `any` | `instanceof TFile`, `instanceof TFolder` |

---

## API

| Запрещено | Требуется |
|---|---|
| `global app` / `window.app` | `this.app` из plugin instance |
| `workspace.activeLeaf` напрямую | `workspace.getActiveViewOfType(MarkdownView)` |
| `Vault.modify()` на активном файле | `Editor` API для открытых файлов |
| `Vault.modify()` для фоновых правок | `Vault.process()` (атомарно, без race conditions) |
| Ручной парсинг YAML frontmatter | `app.fileManager.processFrontMatter()` |
| `app.vault.adapter` (Adapter API) | `app.vault` (Vault API, есть кэш и сериализация) |
| `vault.getFiles().find(f => f.path === ...)` | `vault.getFileByPath()`, `vault.getFolderByPath()` |
| Хранить ссылку на custom view в `this.view` | Доступ через `workspace.getActiveLeavesOfType()` |
| `leaf.detach()` в `onunload()` | Ничего не делать — Obsidian сам восстановит листья |
| `delete file` напрямую | `app.fileManager.trashFile(file)` |

---

## Пути

| Запрещено | Требуется |
|---|---|
| Хардкод `.obsidian` как папки конфига | `app.vault.configDir` |
| User-provided пути без нормализации | `normalizePath(path)` из `obsidian` |

```typescript
import { normalizePath } from 'obsidian';
const path = normalizePath('//my-folder\\file'); // → "my-folder/file"
```

---

## Ресурсы и очистка

- Все event listeners — только через `this.registerEvent()`
- Все команды — только через `this.addCommand()`
- Обновление editor extensions: мутировать существующий массив + `app.workspace.updateOptions()` (не создавать новый массив)

---

## Платформа

| Запрещено | Требуется |
|---|---|
| `navigator.userAgent` для OS detection | `Platform` class из `obsidian` |
| `NodeJS.Timeout` как тип таймера | `window.setTimeout()` (возвращает `number`) |
| Bare `setTimeout`/`setInterval` без `window.` | `window.setTimeout`, `window.setInterval`, `window.clearTimeout`, `window.clearInterval` |
| Node.js модули (`path`, `fs`, `util`) если плагин не desktop-only | Только Web API |
| Lookbehind regex `(?<=...)` на mobile | Проверить совместимость или избегать |
| Свой `sleep()` хелпер | `import { sleep } from 'obsidian'` |

---

## Логирование

- **Запрещено**: оверрайдить `console.log`, `console.error` и другие методы
- **Запрещено**: оставлять debug-логи включёнными в production — только ошибки

---

## Стили

| Запрещено | Требуется |
|---|---|
| `element.style.color = ...` (inline JS styles) | Всё в CSS файлах |
| Оверрайд core Obsidian стилей | Собственные CSS классы / data attributes |
| Хардкод цветов и размеров | CSS переменные Obsidian |

---

## UI и настройки

| Запрещено | Требуется |
|---|---|
| Top-level заголовок в settings tab | Без заголовка или через `setHeading()` |
| Слово "settings" в заголовках секций | "Advanced" вместо "Advanced settings" |
| Title Case в UI тексте | Sentence case ("Template folder location") |
| `<h1>`, `<h2>` теги в settings | `new Setting(el).setName('...').setHeading()` |

---

## Команды

- **Запрещено**: устанавливать default hotkeys
- Правильные типы callback:
  - `callback` — безусловные команды
  - `checkCallback` — команды с preconditions
  - `editorCallback` / `editorCheckCallback` — команды, требующие активный Markdown editor

---

## Manifest и релиз

| Требование | Детали |
|---|---|
| Версия в `manifest.json` == тег GitHub release | Без `v` префикса |
| `id` в `manifest.json` == `id` в `community-plugins.json` | |
| В каждом релизе: `main.js` + `manifest.json` | `styles.css` опционально |
| `LICENSE` файл обязателен | При заимствовании кода — сохранить оригинальную лицензию и указать attribution в README |
| `README.md` с описанием и инструкциями | |
| Описание в `manifest.json` не начинается с "This is a plugin that..." | |
| Описание в `manifest.json` заканчивается на `.`, `?`, `!` или `)` | |
| Все зависимости публично доступны для code review | Нельзя использовать пакеты за private auth |

---

## Качество кода

- Запрещён `var` — только `const`/`let`
- `async/await` вместо `.then()/.catch()`
- Переименовать placeholder классы (`MyPlugin`, `MyPluginSettings`, `SampleSettingTab`)
- Удалить неиспользуемые/нефункциональные провайдеры и интеграции
- При более чем одном `.ts` файле — организовать по папкам
