function s = p14_pipeline(goruntu_yolu, hedef_psnr, bin_yolu, ilerleme)
%P14_PIPELINE  Bir görüntüyü encoder + decoder zincirinin tamamından geçirir.
%
%   s = p14_pipeline('images/peppers.png', 35, 'outputs/peppers.bin')
%
%   Grubun yazdığı fonksiyonları sırayla çağırır, hiçbirini değiştirmez.
%   Ara adımların açtığı figürleri gizler ve kapatır, konsol çıktılarını
%   s.log içinde toplar. Arayüz (P14_arayuz) ve toplu çalıştırma bu
%   fonksiyonu kullanır.
%
%   ilerleme (isteğe bağlı): @(mesaj, oran) biçiminde bir fonksiyon;
%   her adımda çağrılır (arayüzdeki ilerleme çubuğu için).

if nargin < 4 || isempty(ilerleme)
    ilerleme = @(mesaj, oran) [];
end
zaman = tic;

%% 0. Görüntüyü oku ve standart RGB (uint8, 3 kanal) haline getir
% init_encoder sadece renkli RGB görüntüyle çalışıyor. Siyah-beyaz,
% indeksli (paletli) veya 4 kanallı görüntüleri burada RGB'ye çevirip
% geçici bir PNG'ye yazıyoruz; zincir bu geçici dosyayla çalışıyor.
[img, harita] = imread(goruntu_yolu);
if ~isempty(harita)
    img = ind2rgb(img, harita);          % paletli görüntü
end
img = im2uint8(img);
if size(img, 3) == 1
    img = repmat(img, [1 1 3]);          % siyah-beyaz -> 3 kanal
elseif size(img, 3) > 3
    img = img(:, :, 1:3);                % fazla kanalı at
end
[satir, sutun, ~] = size(img);
if satir < 16 || sutun < 16
    error('Görüntü en az 16x16 piksel olmalı (seçilen: %dx%d).', satir, sutun);
end

gecici = [tempname '.png'];
imwrite(img, gecici);
temizlik_dosya = onCleanup(@() gecici_sil(gecici)); %#ok<NASGU>

%% Ara adımların figürlerini gizle, bitince kapat
eski_gorunurluk = get(groot, 'DefaultFigureVisible');
onceki_figurler = findall(groot, 'Type', 'figure');
set(groot, 'DefaultFigureVisible', 'off');
temizlik_fig = onCleanup(@() figurleri_kapat(eski_gorunurluk, onceki_figurler)); %#ok<NASGU>

%% VERİCİ (Encoder)
% evalc: fonksiyonların fprintf çıktılarını yakalayıp log'a ekler.
log = '';

ilerleme('1/9  Renk uzayı dönüşümü ve 4:2:0 alt örnekleme...', 0.02);
log = [log evalc('[Y, Cb_sub, Cr_sub, orj_satir, orj_sutun] = init_encoder(gecici);')];

ilerleme('2/9  8x8 blok 2D-DCT...', 0.08);
log = [log evalc('[Y_dct, Cb_dct, Cr_dct] = apply_2d_dct(Y, Cb_sub, Cr_sub);')];

ilerleme(sprintf('3/9  Hedef %g dB için Q aranıyor (en uzun adım)...', hedef_psnr), 0.15);
log = [log evalc(['[Y_q, Cb_q, Cr_q, opt_Q, psnr_y] = quantize_and_optimize(' ...
                  'Y, Cb_sub, Cr_sub, Y_dct, Cb_dct, Cr_dct, hedef_psnr);'])];

ilerleme('4/9  Zig-zag tarama ve RLE...', 0.55);
log = [log evalc('bitstream = rle_encode(Y_q, Cb_q, Cr_q, orj_satir, orj_sutun, opt_Q);')];

ilerleme('5/9  .bin dosyasına yazılıyor...', 0.65);
log = [log evalc('export_payload(bitstream, bin_yolu);')];

%% ALICI (Decoder) - sadece .bin dosyasından çalışır
ilerleme('6/9  .bin okunuyor, ters RLE...', 0.70);
log = [log evalc('[Y_seq, Cb_seq, Cr_seq, pad_r, pad_c, Q_alinan] = decode_rle(bin_yolu);')];

ilerleme('7/9  Ters zig-zag...', 0.80);
log = [log evalc('[Y_q_rec, Cb_q_rec, Cr_q_rec] = inverse_zigzag(Y_seq, Cb_seq, Cr_seq, pad_r, pad_c);')];

ilerleme('8/9  Ters kuantizasyon ve IDCT...', 0.85);
log = [log evalc('[Y_rec, Cb_rec, Cr_rec] = apply_inverse_dct(Y_q_rec, Cb_q_rec, Cr_q_rec, Q_alinan);')];
log = [log evalc('final_rgb = reconstruct_image(Y_rec, Cb_rec, Cr_rec, orj_satir, orj_sutun);')];

ilerleme('9/9  Performans analizi...', 0.95);
log = [log evalc('[mse_son, psnr_son] = analyze_performance(gecici, final_rgb);')];

%% Sonuçları topla
dosya = dir(bin_yolu);
ham_bayt = satir * sutun * 3;                 % sıkıştırılmamış uint8 RGB

s = struct();
s.orijinal      = img;                        % yüklenen görüntü (RGB uint8)
s.geri          = im2uint8(final_rgb);        % alıcıda oluşan görüntü
s.boyut         = [satir, sutun];
s.islenen_boyut = [pad_r, pad_c];             % 16'nın katına kırpılmış boyut
s.hedef_psnr    = hedef_psnr;
s.Q             = opt_Q;
s.psnr_y        = psnr_y;                     % encoder'ın Y kanalında ölçtüğü
s.psnr          = psnr_son;                   % uçtan uca, RGB
s.mse           = mse_son;
s.deger_sayisi  = numel(bitstream);
s.dosya_bayt    = dosya.bytes;
s.cr_deger      = ham_bayt / numel(bitstream);   % rle_encode'un yazdığı oran
s.cr_gercek     = ham_bayt / dosya.bytes;        % gerçek dosya boyutuna göre
s.bin_yolu      = bin_yolu;
s.sure          = toc(zaman);
s.log           = log;
ilerleme('Bitti.', 1);
end


function gecici_sil(yol)
if exist(yol, 'file')
    delete(yol);
end
end


function figurleri_kapat(eski_gorunurluk, onceki_figurler)
% Varsayılan görünürlüğü geri al ve bu çalıştırmada açılan figürleri kapat
set(groot, 'DefaultFigureVisible', eski_gorunurluk);
tum = findall(groot, 'Type', 'figure');
for k = 1:numel(tum)
    if ~any(tum(k) == onceki_figurler)
        delete(tum(k));
    end
end
end
