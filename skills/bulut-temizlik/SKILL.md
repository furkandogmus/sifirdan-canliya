---
name: bulut-temizlik
description: Bir demo ya da proje için açılan her şeyi bulur ve kullanıcı onaylarsa siler - Terraform katmanları, AWS'de etiketli kaynaklar (tüm region'lar), Netlify sitesi, GitHub reposu, Supabase projesi. "temizle", "her şeyi sil", "fatura gelmesin", "unutulan kaynak", "destroy" geçtiğinde kullan.
---

# Bulut temizliği

İki aşama, arada kullanıcı onayı: **envanter**, sonra **silme**. Envanter aşamasında hiçbir şey silinmez.

## 1. Envanter

Proje adını sor (varsayılan `demo`). Her satırı kontrol et, bulduğunu tek tabloda topla: sağlayıcı, kaynak, nasıl silinir.

**Terraform:** repoda `infra/site` ve `infra/bootstrap` var mı? Varsa silme Terraform'la yapılır (`aws-statik-site` › Silme), elle değil.

**AWS, tüm region'lar** (`project` etiketiyle):

```bash
export AWS_PROFILE=demo
aws sts get-caller-identity
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  aws resourcegroupstaggingapi get-resources --region "$r" \
    --tag-filters Key=project,Values=<proje> \
    --query 'ResourceTagMappingList[].ResourceARN' --output text
done | tr '\t' '\n' | sort -u
```

CloudFront globaldir ve `us-east-1` altında listelenir. Etiketsiz açılmış kaynakları bu sorgu bulamaz; harcamayla çapraz kontrol et (`aws-hesap-guvenligi` adım 4) ve sıfır olmayan her servisi tabloya ekle.

**Netlify:** `netlify sites:list --json | jq -r '.[] | "\(.id)  \(.name)  \(.ssl_url)"'`

**GitHub:** `gh repo list --limit 50`

**Supabase:** `supabase projects list`

## 2. Onay

Tabloyu göster ve kullanıcıdan satır satır seçmesini iste. Varsayılan: hiçbiri. "Hepsini sil" derse listeyi bir kez daha, silinecek adlarla birlikte göster ve tekrar onay al. Silme geri alınamaz; özellikle repo ve veritabanı silinince içerik de gider.

## 3. Silme, bu sırayla

1. **Terraform katmanları:** önce `infra/site`, sonra `infra/bootstrap` (`aws-statik-site` › Silme). Her biri `plan -destroy` → onay → `destroy`.
2. **Netlify:** `netlify sites:delete <site-id> --force`
3. **Supabase:** panelden Project Settings › General › Delete project (kullanıcı yapar).
4. **GitHub repo:** silme izni gerekir: kullanıcı `! gh auth refresh -h github.com -s delete_repo` çalıştırsın, sonra `gh repo delete <sahip>/<repo> --yes`. Repo silinince Actions değişkenleri ve secret'ları da gider.
5. **Terraform dışı kalan AWS kaynakları:** her biri kendi servisinin silme komutuyla; komutu göster, onay al, çalıştır.

## 4. Kontrol

Envanter komutlarını tekrar çalıştır. Hepsi boş dönünce bitti. Kullanıcıya şunu söyle: AWS faturası günlük güncellenir; ertesi gün Billing ekranında harcamanın durduğunu kontrol etsin.
