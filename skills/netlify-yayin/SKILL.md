---
name: netlify-yayin
description: Statik bir siteyi Netlify'da yayına alır ve GitHub Actions'tan yönetilir hale getirir - PR'da önizleme linki, main'e merge'de production. "netlify", "siteyi yayınla", "canlıya al", "önizleme linki" geçtiğinde ya da hızlı bir landing page / portfolyo istendiğinde kullan.
---

# Netlify + GitHub Actions

Sonuç: Netlify sitesi **sadece GitHub'dan** yönetilir. Kod `main`'e girince production'a çıkar, her PR kendi önizleme linkini alır. Netlify panelinde repo bağlantısı kurulmaz; deploy'u Actions yapar, böylece süreç tek yerde görünür.

Ön koşul: `gh` ve `netlify` girişli (`arac-kontrol`).

## 1. Site

- Klasörde site yoksa `site/` altına `index.html` ve `style.css` yaz: framework yok, build yok, mobil uyumlu, tek sayfa. Kullanıcının verdiği içeriği kullan; vermediyse yer tutucu metin koy ve bunu söyle.
- Mevcut proje build istiyorsa (`package.json` içinde `build`), yayın klasörü build çıktısıdır (`dist/`, `build/`, `out/`). Dosyalara bakıp hangisi olduğunu bul; aşağıda `site` geçen her yerde onu kullan ve workflow'daki build satırını aç.

## 2. Repo

`github-cicd` skill'inin 1. adımı: repo, `.gitignore`, ilk push. `.gitignore`'a `.netlify/` de ekle.

## 3. Siteyi oluştur, ilk yayın

Site adı Netlify genelinde benzersiz olmalı: `<repo-adı>-<4 rastgele harf>` öner.

```bash
netlify deploy --prod --dir site --no-build --site-name <site-adı> --json | jq '{site_id, url}'
```

Bu komut siteyi açar, klasöre bağlar ve yayınlar; `site_id` sonraki adımda lazım. Birden fazla Netlify takımı varsa `--team <slug>` ister: `netlify status --json | jq '.account.Teams'` takımları listeler, kullanıcıya hangisi olduğunu sor. Site ID'si sonradan da `.netlify/state.json` içindeki `siteId` alanında durur.

## 4. GitHub'a bağla

Workflow: bu skill'in `templates/netlify.yml` dosyasını `.github/workflows/netlify.yml` olarak kopyala.

Değişken ve secret (`github-cicd` adım 2):

```bash
gh variable set NETLIFY_SITE_ID --body "<site-id>"
```

`NETLIFY_AUTH_TOKEN` kullanıcının kendi tokenıdır; senin görmemen gerekir. Kullanıcıdan şunu yapmasını iste:
1. Netlify › User settings › Applications › Personal access tokens › New access token (süreli olsun).
2. Kendi terminalinde: `! gh secret set NETLIFY_AUTH_TOKEN` ve tokenı istemde yapıştırsın.

Sonra `gh secret list` ile adın göründüğünü doğrula.

## 5. Akışı dene

```bash
git checkout -b ilk-degisiklik
# site/index.html içinde küçük bir değişiklik
git commit -am "başlık güncellendi" && git push -u origin ilk-degisiklik
gh pr create --fill
gh run watch
```

PR'a "Önizleme: https://pr-<n>--<site-adı>.netlify.app" yorumu düşer. Kullanıcı önizlemeyi beğenince:

```bash
gh pr merge --squash --delete-branch
gh run watch
curl -sI https://<site-adı>.netlify.app | head -1
```

`200` ve yeni içerik görünüyorsa bitti.

## Kullanıcıya teslim

Canlı URL, repo URL'i, akışın tek cümlelik özeti (PR = önizleme, merge = yayın) ve silme komutları: `netlify sites:delete <site-id>`, `gh repo delete <sahip>/<repo>` (ayrıntı: `bulut-temizlik`).
