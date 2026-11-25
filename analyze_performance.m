function [mse_val, psnr_val] = analyze_performance(original_image_path, final_rgb)
% 1. Orijinal Görüntüyü Yeniden Oku ve Boyutlarını Eşitle
img_orj = imread(original_image_path);

% En başta 16'nın katlarına göre kırptığımız için, orijinal resmi de aynı boyuta getiriyoruz
[h, w, ~] = size(final_rgb);
img_orj = img_orj(1:h, 1:w, :);

% 2. PSNR hesabı için iki görüntüyü de standart 8-bit (0-255) formatına sabitle
img_orj_8 = im2uint8(img_orj);
final_rgb_8 = im2uint8(final_rgb);

% Matematiksel taşmaları önlemek için double üzerinden fark al
diff = double(img_orj_8) - double(final_rgb_8);

% 3. MSE (Ortalama Karesel Hata) Hesaplama
mse_val = mean(diff(:).^2);

% 4. PSNR (Piksel Sinyal-Gürültü Oranı) Hesaplama
% Veriyi tekrar 0-255 ölçeğine çektiğimiz için tepe değer artık 255'tir
if mse_val == 0
    psnr_val = inf;
else
    psnr_val = 10 * log10((255^2) / mse_val);
end

% 5. Sistemin Nihai Karnesini Komut Penceresine Yazdır
fprintf('\n======================================================\n');
fprintf('       SİSTEMİN NİHAİ PERFORMANS ANALİZİ (AŞAMA 3)      \n');
fprintf('======================================================\n');
fprintf('Final Uçtan Uca MSE (Hata)   : %.2f\n', mse_val);
fprintf('Final Uçtan Uca PSNR (Kalite): %.2f dB\n', psnr_val);
fprintf('======================================================\n');

% --- GÖZLEM VE TEST BLOĞU ---
figure('Name', 'Stage 3: Final Performance Analysis', 'NumberTitle', 'off');

subplot(1,2,1);
imshow(img_orj_8);
title('Orijinal Sıkıştırılmamış Görüntü');

subplot(1,2,2);
imshow(final_rgb_8);
title(sprintf('Alıcıda Yeniden Oluşturulan\n(Final PSNR: %.2f dB)', psnr_val));
end