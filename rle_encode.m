function [bitstream] = rle_encode(Y_q, Cb_q, Cr_q, original_rows, original_cols, optimal_Q)
% 1. Başlık (Metadata Header) Oluşturma
% Alıcı PC'nin görüntüyü geri çizebilmesi için gereken temel bilgiler
% Q 0.5'in katı (3.5, 18.5 ...) olduğu için 2 ile çarpıp tam sayı yapıyoruz;
% dosya int16 (sadece tam sayı) olarak yazılıyor. Alıcı 2'ye bölüp geri alır.
header = [original_rows, original_cols, optimal_Q * 2];

% 2. Standart 8x8 Zig-Zag Tarama İndeksleri
zigzag_order = [1 2 9 17 10 3 4 11 18 25 33 26 19 12 5 6 13 20 27 34 41 49 42 35 28 21 14 7 8 15 22 29 36 43 50 57 58 51 44 37 30 23 16 24 31 38 45 52 59 60 53 46 39 32 40 47 54 61 62 55 48 56 63 64];

% Yardımcı Fonksiyon: Bir kanalı blok blok zig-zag tarayıp 1D diziye çevir
    function seq = process_channel(channel)
        [h, w] = size(channel);
        seq = [];
        for r = 1:8:h
            for c = 1:8:w
                block = channel(r:r+7, c:c+7);
                % 8x8 bloğu Zig-Zag sırasına göre 1D vektöre çevir
                zz_block = block(zigzag_order);
                seq = [seq, zz_block];
            end
        end
    end

fprintf('Zig-Zag tarama uygulanıyor...\n');
Y_seq = process_channel(Y_q);
Cb_seq = process_channel(Cb_q);
Cr_seq = process_channel(Cr_q);

% Tüm kanalları tek bir 1D veri akışında birleştir
full_seq = [Y_seq, Cb_seq, Cr_seq];

% 3. Run-Length Encoding (RLE) Uygulama
fprintf('RLE (Run-Length Encoding) ile sıfırlar sıkıştırılıyor...\n');
bitstream = [];
zero_count = 0;

for i = 1:length(full_seq)
    if full_seq(i) == 0
        zero_count = zero_count + 1;
    else
        if zero_count > 0
            % Ardışık sıfırları [0, adet] şeklinde işaretle
            bitstream = [bitstream, 0, zero_count];
            zero_count = 0;
        end
        % Sıfır olmayan sayıyı doğrudan ekle
        bitstream = [bitstream, full_seq(i)];
    end
end

% Sonda kalan sıfırlar varsa bitir
if zero_count > 0
    bitstream = [bitstream, 0, zero_count];
end

% 4. Paketleme: Header'ı bitstream'in en başına ekle
bitstream = [header, bitstream];

% --- GÖZLEM VE TEST BLOĞU ---
% Sıkıştırma başarısını (Compression Ratio) hesapla
orj_boyut = (original_rows * original_cols * 3); % Orijinal piksel sayısı
yeni_boyut = length(bitstream);
cr_ratio = orj_boyut / yeni_boyut;

fprintf('\n--- İletim Paketi (Payload) Hazır ---\n');
fprintf('Orijinal Veri Boyutu: %d değer\n', orj_boyut);
fprintf('Sıkıştırılmış Bitstream Boyutu: %d değer\n', yeni_boyut);
fprintf('Elde Edilen Sıkıştırma Oranı (CR): %.2fx (Veri %%%.1f küçüldü)\n', cr_ratio, (1 - (yeni_boyut/orj_boyut))*100);
end