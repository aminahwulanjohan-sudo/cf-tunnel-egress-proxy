# Troubleshooting

## `tls: first record does not look like a TLS handshake`

**Penyebab:** cloudflared konek langsung ke IP palsu (DNS di VM memalsukan jawaban),
bukan lewat relay.

**Solusi:** pastikan menjalankan via script repo ini (mount namespace + hosts override),
jangan perintah `cloudflared` polos.

## `failed to request quick Tunnel`

**Penyebab:** `api.trycloudflare.com` tidak bisa dijangkau.

**Solusi:**
- Jika platform punya transparent proxy di `127.0.0.1:443` → biarkan mapping
  `127.0.0.1 api.trycloudflare.com` di hosts file.
- Jika tidak → hapus mapping itu, pastikan ada jalur ke API (DNS normal atau
  `HTTPS_PROXY` + CA bundle yang benar).

## `edge discovery: error looking up ... _v2-origintunneld`

**Tidak fatal.** cloudflared fallback ke `--edge` yang diberikan di script.
Selama precheck `TCP Connectivity ... PASS`, tunnel tetap terbentuk.

## `QUIC connection failed`

**Normal di VM ini.** UDP diblokir total → pakai `--protocol http2` (sudah di script).

## Tunnel terbuat tapi URL tidak bisa diakses

- Tunggu 10–30 detik (propagasi DNS Cloudflare untuk hostname baru).
- Pastikan service lokal memang listen di port yang diberikan ke `--url`.

## Cek socat relay jalan

```bash
ss -tlnp | grep 7844
# harus ada: 127.0.0.1:7844 ... users:(("socat",...))
```

## Cek tunnel terhubung

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://xxx.trycloudflare.com/
# dapat respon HTTP (200/404/dll) = tunnel hidup
# timeout / 1033 = tunnel mati
```
