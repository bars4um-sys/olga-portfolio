# Инструкция: размещение сайта на GitHub Pages

> Этот сайт — статический (HTML + CSS + JS, без сервера и базы данных).
> GitHub Pages позволяет бесплатно публиковать такие сайты и удобно обновлять их.

---

## Шаг 1. Создайте репозиторий на GitHub

1. Зайдите на [github.com](https://github.com) и войдите в аккаунт.
2. Нажмите зелёную кнопку **New** (или «+» → «New repository»).
3. В поле **Repository name** введите, например: `olga-portfolio`.
4. Выберите **Public** (для бесплатного GitHub Pages обязательно).
5. **НЕ ставьте** галочки «Add a README» или «.gitignore».
6. Нажмите **Create repository**.

На следующей странице GitHub покажет инструкцию. Скопируйте оттуда ссылку вида:
```
https://github.com/ВАШ-НИК/olga-portfolio.git
```

---

## Шаг 2. Подготовьте проект локально

Откройте терминал и перейдите в папку проекта:

```bash
cd /Users/admin/Documents/Vibing/Сайты/ОляПорт
```

Инициализируйте Git и загрузите файлы:

```bash
git init
git add .
git commit -m "Initial commit: portfolio website"
git branch -M main
git remote add origin https://github.com/ВАШ-НИК/olga-portfolio.git
git push -u origin main
```

> **Важно:** замените `ВАШ-НИК` и `olga-portfolio` на ваши данные.

---

## Шаг 3. Включите GitHub Pages

1. Откройте ваш репозиторий на GitHub.
2. Перейдите во вкладку **Settings** (вверху).
3. В левом меню выберите **Pages**.
4. В разделе **Build and deployment** → **Source** выберите **Deploy from a branch**.
5. В секции **Branch** выберите:
   - Branch: `main`
   - Folder: `/ (root)`
6. Нажмите **Save**.

---

## Шаг 4. Проверьте результат

- Через **1–2 минуты** сайт станет доступен по адресу:
  ```
  https://ВАШ-НИК.github.io/olga-portfolio
  ```
- Ссылку также можно найти на той же странице **Settings → Pages** (зелёный баннер сверху).

---

## Как обновлять сайт в будущем

Когда внесёте изменения в файлы:

```bash
cd /Users/admin/Documents/Vibing/Сайты/ОляПорт
git add .
git commit -m "Обновление: новые проекты"
git push
```

Изменения появятся на сайте автоматически через пару минут.

---

## Советы

- Чтобы лишние файлы (например, `.DS_Store`) не попадали на GitHub, можно добавить файл `.gitignore` со строкой `.DS_Store`.
- Позже можно привязать свой домен в разделе **Settings → Pages → Custom domain**.
