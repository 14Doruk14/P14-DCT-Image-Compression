function [Y_seq, Cb_seq, Cr_seq, pad_r, pad_c, optimal_Q] = decode_rle(filename)
% 1. Fiziksel Dosyayı Oku
fileID = fopen(filename, 'r');
if fileID == -1
    error('Dosya bulunamadı. Lütfen dosya adını ve yolunu kontrol edin.');
end

% Verici int16 (2 bayt) yazıyor, aynı tiple okumalıyız.
% fread sonucu yine double dizi olarak verir, sonraki adımlar değişmez.
data = fread(fileID, inf, 'int16');
fclose(fileID);

% 2. Header (Başlık) Bilgilerini Çıkar
original_rows = data(1);
original_cols = data(2);
optimal_Q = data(3) / 2;   % verici Q*2 yazdı (int16'ya sığsın diye)

% Başlıktan sonraki asıl sıkıştırılmış veriyi (bitstream) ayır
encoded_stream = data(4:end);

fprintf('--- Alıcı (Receiver) Başladı ---\n');
fprintf('Okunan Header: Orijinal Boyut %dx%d, Optimum Q = %.1f\n', original_rows, original_cols, optimal_Q);

% 3. Ters RLE (Inverse RLE) İşlemi
fprintf('Ters RLE ile sıfır serileri genişletiliyor...\n');
decoded_seq = [];
i = 1;











while i <= length(encoded_stream)
    if encoded_stream(i) == 0
        % Eğer 0 gördüysek, bir sonraki sayı sıfırların adedidir
        zero_count = encoded_stream(i+1);
        decode
           d_seq = [decoded_seq, zeros(1, zero_count)];
        i = i + 2; % İki adım atla (0 ve adedini geç)
    else
        % Sıfır değilse sayıyı doğrudan diziye ekle
        decoded_seq = [decoded_seq, encoded_stream(i)];
        i = i + 1;
    end
end

% 4. Kanalları Ayırma (Y, Cb, Cr)
% Matris uyumsuzluğu yaşamamak için vericide yaptığımız 16'nın katı hesabını tekrarla
pad_r = floor(original_rows / 16) * 16;
pad_c = floor(original_cols / 16) * 16;

% Y kanalı tam boyut, Cb ve Cr ise 4:2:0 alt örnekleme nedeniyle çeyrek (1/4) alana sahiptir
y_len = pad_r * pad_c;
c_len = y_len / 4;

Y_seq = decoded_seq(1 : y_len);
Cb_seq = decoded_seq(y_len + 1 : y_len + c_len);
Cr_seq = decoded_seq(y_len + c_len + 1 : end);

fprintf('Ters RLE Tamamlandı. Veri başarıyla Y, Cb ve Cr dizilerine ayrıldı.\n');
end