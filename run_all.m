% run_all.m
% 'images' klasöründeki her görüntüyü, 'hedefler' listesindeki her PSNR
% değeri için sıkıştırır. Her sonuç için bir .bin dosyası yazar ve bütün
% sonuçları 'outputs/sonuclar.xlsx' tablosuna kaydeder.

clear; clc;

%% Ayarlar
giris_klasoru = 'images';     % Görüntülerin olduğu klasör
cikis_klasoru = 'outputs';    % .bin dosyaları ve tablo buraya yazılır
hedefler      = [30 35 40];   % Denenecek hedef PSNR değerleri (dB)

%% Görüntüleri bul
if ~exist(giris_klasoru, 'dir')
    error('"%s" klasörü bulunamadı. Görüntüleri bu klasöre koyun.', giris_klasoru);
end
if ~exist(cikis_klasoru, 'dir')
    mkdir(cikis_klasoru);
end

uzantilar = {'*.png', '*.jpg', '*.jpeg', '*.bmp', '*.tif', '*.tiff'};
dosyalar = [];
for k = 1:numel(uzantilar)
    dosyalar = [dosyalar; dir(fullfile(giris_klasoru, uzantilar{k}))]; %#ok<AGROW>
end
if isempty(dosyalar)
    error('"%s" klasöründe görüntü bulunamadı.', giris_klasoru);
end
fprintf('%d görüntü bulundu, %d hedef PSNR denenecek.\n', numel(dosyalar), numel(hedefler));

%% Figürleri gizle (yoksa her görüntü için onlarca pencere açılır)
eski_gorunurluk = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');

%% Ana döngü
sonuc = cell(0, 9);

for i = 1:numel(dosyalar)
    yol = fullfile(dosyalar(i).folder, dosyalar(i).name);
    [~, ad, ~] = fileparts(dosyalar(i).name);
    fprintf('\n========== %s ==========\n', dosyalar(i).name);

    try
        % Bu iki adım hedef PSNR'ye bağlı değil, her görüntü için bir kez yeter
        [Y, Cb_sub, Cr_sub, orj_satir, orj_sutun] = init_encoder(yol);
        [Y_dct, Cb_dct, Cr_dct] = apply_2d_dct(Y, Cb_sub, Cr_sub);

        for h = hedefler
            [Y_q, Cb_q, Cr_q, opt_Q, psnr_deger] = quantize_and_optimize( ...
                Y, Cb_sub, Cr_sub, Y_dct, Cb_dct, Cr_dct, h);

            bitstream = rle_encode(Y_q, Cb_q, Cr_q, orj_satir, orj_sutun, opt_Q);

            bin_adi = fullfile(cikis_klasoru, sprintf('%s_psnr%g.bin', ad, h));
            export_payload(bitstream, bin_adi);

            % Gerçek dosya boyutuna göre sıkıştırma oranı
            bilgi      = dir(bin_adi);
            ham_bayt   = orj_satir * orj_sutun * 3;          % uint8 RGB
            cr_deger   = ham_bayt / numel(bitstream);         % sayı adedine göre
            cr_gercek  = ham_bayt / bilgi.bytes;              % bayta göre

            sonuc(end+1, :) = {dosyalar(i).name, ...
                               sprintf('%dx%d', orj_satir, orj_sutun), ...
                               h, opt_Q, psnr_deger, numel(bitstream), ...
                               cr_deger, bilgi.bytes / 1024, cr_gercek}; %#ok<SAGROW>
        end
    catch hata
        warning('%s atlandı: %s', dosyalar(i).name, hata.message);
    end

    close all;   % Bu görüntünün figürlerini kapat
end

set(0, 'DefaultFigureVisible', eski_gorunurluk);

%% Sonuç tablosu
T = cell2table(sonuc, 'VariableNames', ...
    {'Goruntu', 'Boyut', 'HedefPSNR', 'Q', 'PSNR', ...
     'DegerSayisi', 'CR_Deger', 'Dosya_KB', 'CR_Gercek'});

disp(T);
writetable(T, fullfile(cikis_klasoru, 'sonuclar.xlsx'));
fprintf('\nTablo kaydedildi: %s\n', fullfile(cikis_klasoru, 'sonuclar.xlsx'));
