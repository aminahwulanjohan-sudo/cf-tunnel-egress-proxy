# Opsi Hostname Cloudflare Tunnel

## 1. Quick Tunnel — `*.trycloudflare.com`

```bash
./scripts/run-quick-tunnel.sh 8080
# → https://kata-acak-di-sini.trycloudflare.com
```

| Aspek | Keterangan |
|-------|-----------|
| Harga | Gratis |
| Akun | Tidak perlu |
| Permanen? | ❌ **Tidak** — hostname acak baru setiap restart |
| Uptime | Tanpa garansi |
| Cocok untuk | Demo cepat, share sementara, testing |

> Cloudflare sendiri bilang: *"account-less Tunnels have no uptime guarantee"*.

## 2. Named Tunnel + `*.cfargotunnel.com` — GRATIS & PERMANEN

Jalan tengah terbaik kalau mau permanen tanpa beli domain:

1. Buat akun Cloudflare (gratis)
2. Zero Trust → Networks → Tunnels → Create tunnel → beri nama (misal `milikku`)
3. Salin token tunnel
4. Route hostname: tambahkan Public Hostname `web.cfargotunnel.com`
   (ganti `web` dengan nama pilihanmu — Cloudflare yang sediakan domainnya)
5. Jalankan:
   ```bash
   TUNNEL_TOKEN="xxx" PROXY_URL="http://user:pass@proxy:3128" ./scripts/run-named-tunnel.sh
   ```

| Aspek | Keterangan |
|-------|-----------|
| Harga | Gratis |
| Akun | Perlu (gratis) |
| Permanen? | ✅ Ya — terikat akunmu |
| Uptime | Standar Cloudflare |
| Cocok untuk | Service pribadi yang butuh URL tetap |

## 3. Named Tunnel + Domain Sendiri

Sama seperti opsi 2, tapi hostname-nya `panel.milikku.id`:
- Perlu beli domain + pindahkan nameserver ke Cloudflare
- Keuntungan: URL profesional, banyak subdomain, kontrol DNS penuh

## Ringkasan

```
trycloudflare.com  = gratis + sementara  (coba-coba)
cfargotunnel.com   = gratis + permanen   (pribadi/serius tanpa domain)
domain sendiri     = bayar  + permanen + profesional
```
