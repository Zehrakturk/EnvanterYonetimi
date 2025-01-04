#!/bin/bash

# Konfigürasyon değişkenleri
LOW_STOCK_THRESHOLD=50
CSV_FILE="/home/btu59049/envanter_yonetimi/product/products.csv"
REPORT_DIR="/tmp/stock_reports"

# Rapor dizini oluşturma
create_report_directory() {
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    local report_dir="$REPORT_DIR/report_$timestamp"
    mkdir -p "$report_dir"
    echo "$report_dir"
}

# Kategori bazlı grafik oluşturma fonksiyonu
generate_category_stock_graph() {
    local report_dir=$1
    local data_file="$report_dir/category_stock.dat"
    local graph_file="$report_dir/category_stock.png"
    
    # Kategori bazlı stok verisi
    echo "Kategori bazlı stok verisi oluşturuluyor..."
    awk -F, '
    NR>1 {
        stock[$5] += $3
    }
    END {
        for (cat in stock) {
            print cat, stock[cat]
        }
    }
    ' "$CSV_FILE" > "$data_file"

    if [ $? -ne 0 ]; then
        echo "Hata: Kategori bazlı stok verisi oluşturulamadı."
        return 1
    fi
    
    echo "Kategori bazlı grafik oluşturuluyor..."
    gnuplot <<EOF
    set terminal png size 800,600
    set output '$graph_file'
    set title 'Kategori Bazlı Stok Miktarları'
    set style data histograms
    set style fill solid
    set ylabel 'Stok Miktarı'
    set xlabel 'Kategoriler'
    set xtic rotate by -45
    plot '$data_file' using 2:xtic(1) title 'Stok Miktarı' with boxes
EOF

    if [ $? -ne 0 ]; then
        echo "Hata: Grafik oluşturulamadı."
        return 1
    fi

    # Grafik dosyasının oluşturulduğuna dair bilgi mesajı
    if [ -f "$graph_file" ]; then
        echo "Grafik başarıyla oluşturuldu: $graph_file"
        # PNG dosyasını xdg-open ile aç
        xdg-open "$graph_file"
    else
        echo "Hata: Grafik dosyası oluşturulamadı."
    fi
}

generate_stock_value_graph() {
    local report_dir=$1
    local data_file="$report_dir/stock_value.dat"
    local graph_file="$report_dir/stock_value.png"
    
    # Yüksek stok değerleri
    echo "Stok değeri verisi oluşturuluyor..."
    awk -F, '
    NR>1 {
        stock_value = $3 * $4
        print $2, stock_value
    }
    ' "$CSV_FILE" | sort -k2,2nr | head -n 10 > "$data_file"

    if [ $? -ne 0 ]; then
        echo "Hata: Stok değeri verisi oluşturulamadı."
        return 1
    fi
    
    echo "Stok değeri grafiği oluşturuluyor..."
    gnuplot <<EOF
    set terminal png size 800,600
    set output '$graph_file'
    set title 'En Yüksek Stok Değerine Sahip 10 Ürün'
    set style data histograms
    set style fill solid
    set ylabel 'Stok Değeri (TL)'
    set xlabel 'Ürünler'
    set xtic rotate by -45
    plot '$data_file' using 2:xtic(1) title 'Stok Değeri' with boxes
EOF

    if [ $? -ne 0 ]; then
        echo "Hata: Grafik oluşturulamadı."
        return 1
    fi

    # Grafik dosyasının oluşturulduğuna dair bilgi mesajı
    if [ -f "$graph_file" ]; then
        echo "Grafik başarıyla oluşturuldu: $graph_file"
        zenity --info --text="En Yüksek Stok Değeri Grafiği" --title="Grafik" --image="$graph_file"
          # PNG dosyasını xdg-open ile aç
        xdg-open "$graph_file"
    else
        echo "Hata: Grafik dosyası oluşturulamadı."
    fi
}

list_low_stock_products() {
    local report_dir=$1
    local report_file="$report_dir/low_stock_report.txt"
    local product_list=""
    
    echo "=== STOĞU 50'NİN ALTINDA OLAN ÜRÜNLER ===" > "$report_file"
    echo "Tarih: $(date "+%Y-%m-%d %H:%M:%S")" >> "$report_file"
    echo "----------------------------------------" >> "$report_file"
    
    while IFS=, read -r id name stock category price; do
        if [ "$stock" -lt "$LOW_STOCK_THRESHOLD" ]; then
            # Stok miktarını tam sayı olarak formatla
            stock_int=$(printf "%.0f" "$stock")
            product_list="$product_list\nÜrün ID: $id\nÜrün Adı: $name\nKategori: $category\nStok Miktarı: $stock_int\nBirim Fiyat: $price TL\n----------------------------------------"
            printf "Ürün ID: %d\nÜrün Adı: %s\nKategori: %s\nStok Miktarı: %d\nBirim Fiyat: %.2f TL\n----------------------------------------\n" "$id" "$name" "$category" "$stock_int" "$price" >> "$report_file"
        fi
    done < <(tail -n +2 "$CSV_FILE")
    
    # Zenity ile yeni bir pencere açarak ürünleri gösterme
    zenity --info --title="Stoğu 50'nin Altında Olan Ürünler" --text="Stoğu 50'nin altında olan ürünler:\n$product_list"
}


# Menü ekranı (Zenity ile GUI menüsü)
show_menu() {
    choice=$(zenity --list --title="Stok Raporları Menü" --column="Seçim" \
                    "Kategori Bazlı Rapor" \
                    "Yüksek Stok Değeri Raporu" \
                    "Stoğu 50'nin Altında Olan Ürünler" \
                    "Çıkış")
    echo $choice
}

# Ana menü fonksiyonu
main() {
    while true; do
        choice=$(show_menu)

        case $choice in
            "Kategori Bazlı Rapor")
                echo "Kategori Bazlı Rapor Seçildi."
                report_dir=$(create_report_directory)
                
                # Grafik oluştur
                generate_category_stock_graph "$report_dir"
                ;;

            "Yüksek Stok Değeri Raporu")
            	report_dir=$(create_report_directory)
                
                # Grafik oluştur
                generate_stock_value_graph "$report_dir"
                ;;
            "Stoğu 50'nin Altında Olan Ürünler")
            	report_dir=$(create_report_directory)
                
                
                list_low_stock_products "$report_dir"
                ;;
            
            "Çıkış")
                /home/btu59049/envanter_yonetimi/script/main_menu.sh 1
                break
                ;;

            *)
                echo "Geçersiz seçenek, tekrar deneyin."
                ;;

        esac
    done
}

# Scripti çalıştır
main

