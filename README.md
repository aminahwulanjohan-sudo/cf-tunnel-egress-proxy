# Cloudflare Tunnel dari VM Tanpa IP Publik

Metode **reverse tunnel** (Cloudflare Tunnel / Quick Tunnel) + **egress proxy traversal** via socat relay dan hosts hijacking dalam mount namespace.

Cocok untuk VM/container yang:
- ❌ Tidak punya IP publik
- ❌ Tidak bisa buka inbound port
- ✅ Hanya bisa koneksi **keluar** lewat HTTP proxy (egress proxy)
- ❌ DNS memalsukan jawaban / tidak bisa resolve domain eksternal
- ❌ UDP diblokir total (hanya TCP)

## Cara Kerja

```
cloudflared
  ├─ daftar tunnel → api.trycloudflare.com:443
  │    → /etc/hosts (override): itu 127.0.0.1
  │    → transparent proxy lokal → API Cloudflare asli
  │    → dapat hostname gratis *.trycloudflare.com ✓
  │
  └─ buka tunnel → region1.v2.argotunnel.com:7844
       → /etc/hosts (override): itu 127.0.0.1
       → socat relay 127.0.0.1:7844
       → HTTP CONNECT via egress proxy → edge Cloudflare asli
       → TUNNEL TERBENTUK ✓
```

### 4 Komponen

| # | Komponen | Fungsi |
|---|----------|--------|
| 1 | **socat relay** | Dengarkan `127.0.0.1:7844`, teruskan via `HTTP CONNECT` lewat egress proxy ke IP edge Cloudflare |
| 2 | **hosts override** | Belokkan `region1.v2.argotunnel.com` & `api.trycloudflare.com` ke `127.0.0.1` |
| 3 | **mount namespace** | `unshare --mount` + `mount --bind` — override hosts hanya untuk proses cloudflared, tidak ganggu sistem |
| 4 | **transparent proxy** | Beberapa platform punya intercepting proxy di `127.0.0.1:443` — dipakai untuk registrasi API |

## Pilihan Hostname

| Jenis | Gratis? | Permanen? | Syarat |
|-------|---------|-----------|--------|
| `*.trycloudflare.com` (Quick Tunnel) | ✅ | ❌ acak tiap restart | Tanpa akun |
| `*.cfargotunnel.com` (Named Tunnel) | ✅ | ✅ | Akun Cloudflare gratis |
| Domain sendiri | ❌ bayar domain | ✅ + profesional | Akun Cloudflare + domain |

> **Urutan rekomendasi:** `trycloudflare.com` = gratis + sementara (coba-coba) → `cfargotunnel.com` = gratis + permanen → domain sendiri = permanen + profesional.

## Struktur Repo

```
├── README.md                 # dokumentasi ini
├── scripts/
│   ├── run-quick-tunnel.sh   # Quick Tunnel (hostname gratis, sementara)
│   ├── run-named-tunnel.sh   # Named Tunnel (butuh token)
│   └── hosts.cf.example      # template hosts override
└── docs/
    ├── HOSTNAME-OPTIONS.md   # perbandingan detail opsi hostname
    └── TROUBLESHOOTING.md    # masalah umum & solusi
```

## Quick Start

```bash
# 1. Isi config
cp scripts/hosts.cf.example /tmp/hosts.cf
# edit PROXY_URL di script sesuai proxy kamu

# 2. Jalankan Quick Tunnel (expose port 8080 lokal)
./scripts/run-quick-tunnel.sh 8080
# → dapat URL https://xxx.trycloudflare.com
```

Lihat [docs/HOSTNAME-OPTIONS.md](docs/HOSTNAME-OPTIONS.md) untuk opsi permanen.

## Keamanan

⚠️ **Jangan commit secret ke repo ini.** Semua token/password diganti placeholder:
- `CLOUDFLARE_TUNNEL_TOKEN` — token named tunnel
- `http://user:pass@proxy:3128` — URL egress proxy
