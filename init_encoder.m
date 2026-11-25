function [Y, Cb_sub, Cr_sub, original_rows, original_cols] = init_encoder(image_path)
% 1. Sıkıştırılmamış RGB Görüntüyü Oku
img_rgb = imread(image_path);
img_rgb = im2double(img_rgb); 

[original_rows, original_cols, ~] = size(img_rgb);

% 8x8 DCT blokları için boyutları ayarla
pad_r = floor(original_rows / 16) * 16;
pad_c = floor(original_cols / 16) * 16;
img_rgb = img_rgb(1:pad_r, 1:pad_c, :);

% 2. YCbCr Dönüşümü
img_ycbcr = rgb2ycbcr(img_rgb);
Y = img_ycbcr(:,:,1);
Cb = img_ycbcr(:,:,2);
Cr = img_ycbcr(:,:,3);

% 3. 4:2:0 Chroma Subsampling
Cb_sub = Cb(1:2:end, 1:2:end);
Cr_sub = Cr(1:2:end, 1:2:end);

% --- GÖZLEM VE TEST BLOĞU (DEBUGGING) ---
fprintf('Orijinal RGB Boyutu: %dx%dx3\n', pad_r, pad_c);
fprintf('Y (Luminance) Kanalı Boyutu: %dx%d\n', size(Y,1), size(Y,2));
fprintf('Alt Örneklenmiş Cb/Cr Boyutu: %dx%d (%%50 Alan Tasarrufu)\n', size(Cb_sub,1), size(Cb_sub,2));

figure('Name', 'Stage 1: YCbCr Separation and Subsampling', 'NumberTitle', 'off');

subplot(2,2,1);
imshow(img_rgb);
title('Orijinal RGB');

subplot(2,2,2);
imshow(Y);
title('Y Kanalı (Parlaklık - Tam Çözünürlük)');

subplot(2,2,3);
imshow(Cb_sub);
title('Cb Kanalı (Mavi Farkı - Alt Örneklenmiş)');

subplot(2,2,4);
imshow(Cr_sub);
title('Cr Kanalı (Kırmızı Farkı - Alt Örneklenmiş)');
end