function [Y_q, Cb_q, Cr_q, optimal_Q, current_psnr] = quantize_and_optimize(Y, Cb_sub, Cr_sub, Y_dct, Cb_dct, Cr_dct, target_psnr)
% Standart JPEG Parlaklık (Luminance) Kuantizasyon Matrisi
Q_lum = [16 11 10 16 24 40 51 61;
    12 12 14 19 26 58 60 55;
    14 13 16 24 40 57 69 56;
    14 17 22 29 51 87 80 62;
    18 22 37 56 68 109 103 77;
    24 35 55 64 81 104 113 92;
    49 64 78 87 103 121 120 101;
    72 92 95 98 112 100 103 99] / 255;

% Standart JPEG Renk (Chrominance) Kuantizasyon Matrisi
Q_chrom = [17 18 24 47 99 99 99 99;
    18 21 26 66 99 99 99 99;
    24 26 56 99 99 99 99 99;
    47 66 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99] / 255;

% Kuantizasyon işlemi için yardımcı fonksiyon
quantize_block = @(block, Q_mat, scale) round(block.data ./ (Q_mat * scale));

% Ters Kuantizasyon ve IDCT işlemleri (Optimizasyon döngüsünde test için)
dequantize_block = @(block, Q_mat, scale) block.data .* (Q_mat * scale);
idct_func = @(block) idct2(block.data);

optimal_Q = 1; % Başlangıç Q faktörü (en düşük sıkıştırma, en yüksek kalite)
current_psnr = inf;

fprintf('Hedef PSNR: %.2f dB\nOptimizasyon başlatılıyor...\n', target_psnr);

% Kapalı Döngü Optimizasyonu: Hedef PSNR'nin altına düşene kadar Q'yu artır
while current_psnr > target_psnr && optimal_Q < 50
    % 1. Kuantizasyon uygula
    Y_q = blockproc(Y_dct, [8 8], @(b) quantize_block(b, Q_lum, optimal_Q));
    Cb_q = blockproc(Cb_dct, [8 8], @(b) quantize_block(b, Q_chrom, optimal_Q));
    Cr_q = blockproc(Cr_dct, [8 8], @(b) quantize_block(b, Q_chrom, optimal_Q));

    % 2. Görüntüyü geri oluştur (Döngü içinde test amaçlı)
    Y_rec_dct = blockproc(Y_q, [8 8], @(b) dequantize_block(b, Q_lum, optimal_Q));
    Y_rec = blockproc(Y_rec_dct, [8 8], idct_func);

    % 3. Geçerli PSNR'yi hesapla (Sadece Y kanalı üzerinden hızlı test)
    mse_val = mean((Y(:) - Y_rec(:)).^2);
    if mse_val == 0
        current_psnr = inf;
    else
        current_psnr = 10 * log10(1^2 / mse_val); % Y değerleri double (0-1) olduğu için tepe değer 1
    end

    fprintf('Denendi Q = %d, Bulunan PSNR = %.2f dB\n', optimal_Q, current_psnr);

    % Eğer hala hedefin üstündeysek, Q'yu artır (daha fazla sıkıştır)
    if current_psnr > target_psnr
        optimal_Q = optimal_Q + 0.5;
    end
end

fprintf('\n--- Optimizasyon Tamamlandı ---\n');
fprintf('Optimum Q Faktörü: %.1f\n', optimal_Q);
fprintf('Elde Edilen PSNR: %.2f dB\n', current_psnr);

% --- GÖZLEM VE TEST BLOĞU ---
% Kuantizasyonun etkisini görmek için 8x8 bir bloğun öncesi ve sonrası
figure('Name', 'Stage 1: Quantization Effect', 'NumberTitle', 'off');

subplot(1,2,1);
imshow(log(abs(Y_dct(1:8, 1:8)) + 1), []);
title('Kuantizasyon Öncesi (DCT Katsayıları)');
colormap(gca, jet); colorbar;

subplot(1,2,2);
imshow(log(abs(Y_q(1:8, 1:8)) + 1), []);
title(sprintf('Kuantizasyon Sonrası (Q=%.1f)', optimal_Q));
colormap(gca, jet); colorbar;
end