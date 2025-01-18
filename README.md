# Envanter Yönetim Sistemi

Bu proje, e-ticaret platformları için kullanılabilecek kapsamlı bir envanter yönetim sistemidir. Sistem, ürün yönetimi, stok takibi, kullanıcı yönetimi ve detaylı raporlama özellikleri sunmaktadır.

## Özellikler

- 🔐 Güvenli Giriş Sistemi
- 📦 Ürün Yönetimi (Ekleme/Silme/Güncelleme/Filtreli Listeleme)
- 👥 Kullanıcı Yönetimi
- 📊 Detaylı Raporlama Sistemi
- 🔄 Program Yönetimi
- 🎥 Proje kullanımını anlatan video [▶𝚈𝚘𝚞𝚝𝚞𝚋𝚎](https://youtu.be/XhOqW-PPLNo)

### Ön Koşullar

- Linux tabanlı işletim sistemi
- Bash shell
- gnuplot (grafik oluşturma için)

### Kurulum

1. Projeyi klonlayın:
```bash
git clone [repository-url]
cd [proje-dizini]
```

2. Çalıştırma izinlerini verin:
```bash
chmod +x login.sh
```

### Kullanım

1. Programı başlatmak için:
```bash
./login.sh
```

2. Giriş ekranında kullanıcı adı ve şifrenizi girin:
   - Normal kullanıcı veya yönetici olarak giriş yapabilirsiniz
   - 3 başarısız deneme sonrası hesabınız 1 saat süreyle bloke edilir

     ![Ekran görüntüsü 2025-01-05 122625](https://github.com/user-attachments/assets/984f6ee3-fbac-4d66-9b07-d0f287888adf)


### Yönetici Menüsü

Yönetici girişi yapıldığında aşağıdaki menülere erişim sağlanır:
   - ![image](https://github.com/user-attachments/assets/e81fb214-71c4-4100-9a2d-8cad2694c3d6)

1. **Ürün İşlemleri**
   - Ürün Ekleme
   - Ürün Silme
   - Ürün Güncelleme
   - Ürün Listeleme
   - ![Ekran görüntüsü 2025-01-05 124220](https://github.com/user-attachments/assets/4b59c916-46ca-47fd-8eeb-49f8cc6bdfa6)


2. **Program Yönetimi**
   - Sistem Ayarları
   - Yedekleme İşlemleri
   - ![Ekran görüntüsü 2025-01-05 124406](https://github.com/user-attachments/assets/635eabd1-db5e-493f-b524-9f2a88584f69)


3. **Kullanıcı İşlemleri**
   - Kullanıcı Ekleme
   - Kullanıcı Silme
   - Kullanıcı Düzenleme
   - Kullanıcı Listeleme
   - ![Ekran görüntüsü 2025-01-05 124700](https://github.com/user-attachments/assets/b39c378c-e6dc-4377-b977-e7fcca9577db)


4. **Program Raporu**
   - Stok Durum Raporu
   - Kategori Bazlı Raporlar
   - Satış Raporları

   
### Kullanıcı Menüsü

Kullanıcı girişi yapıldığında aşağıdaki menülere erişim sağlanır:
   - ![Ekran görüntüsü 2025-01-05 123323](https://github.com/user-attachments/assets/ba04ad15-f4bf-4ffe-8494-77ea51fa0194)

1. **Ürün İşlemleri**
   - Ürün Listeleme
2. **Kullanıcı İşlemleri**
   - Şifre Değiştirme
   - Profil Bilgisi Görüntüleme


## Güvenlik

- Başarısız giriş denemeleri kaydedilir
- 3 başarısız denemeden sonra hesap 1 saat süreyle bloke edilir
- Tüm işlemler log dosyalarında kayıt altına alınır

## Raporlama Sistemi
Sistem aşağıdaki raporları otomatik olarak oluşturur:

- Kategori bazlı stok raporları
  
-<img src="https://github.com/user-attachments/assets/875e5d76-90e0-4eb9-8c3d-bc9b48e5b27d" width="300" height="auto" alt="Ekran görüntüsü 2025-01-04 180814">

- Ürün değer analizleri

- <img src="https://github.com/user-attachments/assets/0e6ac053-7d4e-4bf7-a7d4-fa57c060ab7b" width="300" height="auto" alt="Ekran görüntüsü 2025-01-04 180833">

- En çok satılan ürünler

## Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun


## İletişim

Zehra Aktürk - [@LinkedIn](https://www.linkedin.com/in/zehra-akt%C3%BCrk/) - zehra.akturk15@gmail.com

Proje Linki: [https://github.com/Zehrakturk/EnvanterYonetimi](https://github.com/Zehrakturk/EnvanterYonetimi)
