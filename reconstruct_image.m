function [final_rgb] = reconstruct_image(Y_rec, Cb_rec, Cr_rec, original_rows, original_cols)
fprintf('YCbCr kanalları birleştirilip RGB görüntüsü oluşturuluyor...\n');

% 1. Cb ve Cr kanallarını orijinal çözünürlüklerine geri büyüt (Upsampling)
% Vericide (Stage 1) boyutlarını yarıya düşürmüştük, şimdi 2 katına çıkarıyoruz
Cb_full = imresize(Cb_rec, 2, 'bicubic');
Cr_full = imresize(Cr_rec, 2, 'bicubic');

% Boyutların Y kanalı ile milimetrik eşleştiğinden emin olmak için güvenlik adımı
[h, w] = size(Y_rec);
Cb_full = Cb_full(1:h, 1:w);
Cr_full = Cr_full(1:h, 1:w);

% 2. Y, Cb ve Cr kanallarını tek bir 3 Boyutlu (3D) matriste birleştir
img_ycbcr_rec = cat(3, Y_rec, Cb_full, Cr_full);

% 3. YCbCr'den standart RGB renk uzayına geri dön
final_rgb_padded = ycbcr2rgb(img_ycbcr_rec);

% 4. Vericide görüntü 16'nın katına KIRPILDI (doldurulmadı), yani kenardaki
% pikseller hiç gönderilmedi. Bu yüzden görüntü orijinalden küçük olabilir ve
% orijinal boyuta geri getirilemez. Kırpılmış boyutu olduğu gibi döndürüyoruz;
% analyze_performance orijinali zaten bu boyuta kırparak karşılaştırır.
% (Eski satır 16'nın katı olmayan görüntülerde "Index exceeds" hatası veriyordu.)
% original_rows / original_cols girdileri arayüz uyumu için duruyor.
final_rgb = final_rgb_padded;

fprintf('Görüntü başarıyla RGB formatında yeniden oluşturuldu.\n');
end