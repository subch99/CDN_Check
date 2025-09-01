# CDN_Check
---

### 🎯 Fitur Enhanced:

1. **Deteksi 50+ CDN Provider**:
   - Cloudflare, Akamai, Fastly, AWS CloudFront
   - Azure CDN, Google Cloud CDN, Imperva/Incapsula
   - StackPath, KeyCDN, BunnyCDN, CDN77
   - ChinaCache, Tencent Cloud, Alibaba Cloud, Huawei Cloud
   - Dan 30+ lainnya

2. **Multi-Layer Detection**:
   - DNS Lookup (anycast pattern)
   - Reverse DNS (50+ pattern matching)
   - HTTP Headers (40+ header patterns)
   - ASN Lookup (whois information)

3. **Better Timeout Handling**:
   - Fallback HTTP jika HTTPS gagal
   - Timeout untuk menghindari hanging

4. **User-Agent Spoofing**:
   - Menggunakan realistic UA untuk avoid blocking

---

### 🚀 Cara Penggunaan:

```bash
chmod +x cdn_detector.sh
./cdn_detector.sh example.com
./cdn_detector.sh google.com
./cdn_detector.sh alibaba.com
```

---

### 📊 Contoh Output:

**Untuk Cloudflare**:
```
[✅] Domain is protected by: cloudflare
[🛡️] CDN detected via: Multiple methods
```

**Untuk AWS CloudFront**:
```
[✅] Domain is protected by: cloudfront  
[🛡️] CDN detected via: Headers
```

**Tanpa CDN**:
```
[🚨] NO CDN DETECTED - Domain may be exposing ORIGIN IP
[⚠️] Recommendation: Implement CDN protection immediately
```

---

### 💡 Tips:

1. **Untuk hasil maksimal**, pastikan Anda terhubung ke internet yang tidak memblokir whois dan DNS queries.
2. **Beberapa CDN enterprise** mungkin menggunakan custom domain yang tidak terdeteksi.

---
