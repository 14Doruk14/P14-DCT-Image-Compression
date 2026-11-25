function sonuc = oran_kalite_egrisi(goruntu_yolu, ilerleme)
%ORAN_KALITE_EGRISI  Farklı sıkıştırma oranlarında P14 sistemini MATLAB JPEG
%   ile karşılaştırır (rate-distortion / oran-kalite eğrisi).
%
%   oran_kalite_egrisi                         % images/peppers.png ile
%   oran_kalite_egrisi('images/baska.png')
%
%   Ne yapar:
%   1) P14 sistemini hedef PSNR = 22, 23, ..., 42 dB ile çalıştırır
%      (her hedef farklı bir Q, yani farklı bir sıkıştırma oranı verir)
%   2) Aynı görüntüyü MATLAB'in JPEG'iyle 12 farklı kalitede sıkıştırır
%   3) İki grafik çizer ve outputs/ klasörüne PNG + Excel tablosu yazar:
%      - Sol: bit/piksel - PSNR  (aynı dosya boyutunda hangisi daha kaliteli?)
%      - Sağ: hedef PSNR - ölçülen PSNR (Y kanalı ve uçtan uca RGB)
%
%   Bit/piksel (bpp): dosyadaki toplam bit / piksel sayısı. Sıkıştırılmamış
%   RGB 24 bpp'dir; CR = 24 / bpp.

proje = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(goruntu_yolu)
    goruntu_yolu = fullfile(proje, 'images', 'peppers.png');
end
if nargin < 2 || isempty(ilerleme)
    ilerleme = @(mesaj, oran) fprintf('%s\n', mesaj);
end

cikis = fullfile(proje, 'outputs');
if ~exist(cikis, 'dir')
    mkdir(cikis);
end
[~, ad] = fileparts(goruntu_yolu);

% Ara .bin ve .jpg dosyaları geçici klasöre, iş bitince silinir
gecici = tempname;
mkdir(gecici);
temizlik = onCleanup(@() rmdir(gecici, 's')); %#ok<NASGU>

hedefler        = 22:42;                                  % dB
jpeg_kaliteleri = [5 10 15 20 30 40 50 60 70 80 90 95];   % MATLAB JPEG 'Quality'
toplam_adim     = numel(hedefler) + numel(jpeg_kaliteleri);

%% 1) P14 sistemi: her hedef PSNR için tüm zincir (encoder + .bin + decoder)
n = numel(hedefler);
[Q, psnr_y, psnr_rgb, dosya_kb, bpp, cr] = deal(zeros(n, 1));

for i = 1:n
    ilerleme(sprintf('P14 sistemi: hedef %d dB  (%d/%d)', hedefler(i), i, n), ...
             (i - 1) / toplam_adim);
    s = p14_pipeline(goruntu_yolu, hedefler(i), ...
                     fullfile(gecici, sprintf('hedef%d.bin', hedefler(i))));
    piksel      = s.boyut(1) * s.boyut(2);
    Q(i)        = s.Q;
    psnr_y(i)   = s.psnr_y;
    psnr_rgb(i) = s.psnr;
    dosya_kb(i) = s.dosya_bayt / 1024;
    bpp(i)      = s.dosya_bayt * 8 / piksel;
    cr(i)       = s.cr_gercek;
end

bizim = table(hedefler(:), Q, psnr_y, psnr_rgb, dosya_kb, bpp, cr, ...
    'VariableNames', {'HedefPSNR', 'Q', 'PSNR_Y', 'PSNR_RGB', ...
                      'Dosya_KB', 'BitPerPiksel', 'CR_Gercek'});

%% 2) Karşılaştırma: MATLAB'in kendi JPEG kodlayıcısı
img = s.orijinal;                        % p14_pipeline'ın RGB uint8 hali
m = numel(jpeg_kaliteleri);
[j_psnr, j_kb, j_bpp, j_cr] = deal(zeros(m, 1));
jpg = fullfile(gecici, 'karsilastirma.jpg');

for k = 1:m
    ilerleme(sprintf('MATLAB JPEG: kalite %d  (%d/%d)', jpeg_kaliteleri(k), k, m), ...
             (n + k - 1) / toplam_adim);
    imwrite(img, jpg, 'Quality', jpeg_kaliteleri(k));
    geri = imread(jpg);
    mse = mean((double(img(:)) - double(geri(:))).^2);   % analyze_performance ile aynı formül
    j_psnr(k) = 10 * log10(255^2 / mse);
    bilgi = dir(jpg);
    j_kb(k)  = bilgi.bytes / 1024;
    j_bpp(k) = bilgi.bytes * 8 / piksel;
    j_cr(k)  = numel(img) / bilgi.bytes;
end

jpeg = table(jpeg_kaliteleri(:), j_psnr, j_kb, j_bpp, j_cr, ...
    'VariableNames', {'Kalite', 'PSNR_RGB', 'Dosya_KB', 'BitPerPiksel', 'CR_Gercek'});

%% 3) Tabloları kaydet
xlsx = fullfile(cikis, [ad '_oran_kalite.xlsx']);
try
    writetable(bizim, xlsx, 'Sheet', 'P14', 'WriteMode', 'overwritesheet');
    writetable(jpeg,  xlsx, 'Sheet', 'JPEG', 'WriteMode', 'overwritesheet');
catch
    % Excel yazılamazsa (dosya açık vb.) CSV'ye düş
    xlsx = fullfile(cikis, [ad '_oran_kalite_P14.csv']);
    writetable(bizim, xlsx);
    writetable(jpeg, fullfile(cikis, [ad '_oran_kalite_JPEG.csv']));
end

%% 4) Grafikler
ilerleme('Grafik çiziliyor...', 0.98);
fig = ciz(bizim, jpeg, ad);
png = fullfile(cikis, [ad '_oran_kalite.png']);
exportgraphics(fig, png, 'Resolution', 200);

disp(bizim);
disp(jpeg);
fprintf('Kaydedildi:\n  %s\n  %s\n', png, xlsx);

sonuc = struct('bizim', bizim, 'jpeg', jpeg, 'figur', fig, 'png', png, 'tablo', xlsx);
ilerleme('Bitti.', 1);
end


function fig = ciz(bizim, jpeg, ad)
% Renkler: P14 = mavi, JPEG = turuncu, Y kanalı = yeşil-mavi.
% Aynı büyüklük (P14 uçtan uca PSNR) iki grafikte de aynı renkte.
mavi     = [42 120 214] / 255;
turuncu  = [235 104 52] / 255;
camgobegi = [27 175 122] / 255;
yazi     = [0.32 0.32 0.31];
izgara   = [0.88 0.88 0.87];

fig = figure('Name', sprintf('Oran-kalite eğrisi: %s', ad), ...
             'Color', 'w', 'Position', [80 120 1200 500], 'NumberTitle', 'off');
t = tiledlayout(fig, 1, 2, 'TileSpacing', 'loose', 'Padding', 'compact');

% ---------------- Sol: bit/piksel - PSNR ----------------
ax1 = nexttile(t);
hold(ax1, 'on');

% Hedef 40+ dB'de Q hep 1'de takılıyor; aynı noktayı tekrar çizmemek için
[~, tek] = unique(bizim.Q, 'stable');
b = sortrows(bizim(tek, :), 'BitPerPiksel');
j = sortrows(jpeg, 'BitPerPiksel');

p1 = plot(ax1, b.BitPerPiksel, b.PSNR_RGB, '-o', 'Color', mavi, 'LineWidth', 2, ...
          'MarkerSize', 6, 'MarkerFaceColor', mavi, 'MarkerEdgeColor', 'none');
p2 = plot(ax1, j.BitPerPiksel, j.PSNR_RGB, '-s', 'Color', turuncu, 'LineWidth', 2, ...
          'MarkerSize', 6, 'MarkerFaceColor', turuncu, 'MarkerEdgeColor', 'none');

% Seçili Q etiketleri (en az, orta, en çok sıkıştırma)
secili = unique([1, round(height(b) / 2), height(b)]);
for k = secili
    text(ax1, b.BitPerPiksel(k), b.PSNR_RGB(k), sprintf('  Q=%g', b.Q(k)), ...
         'Color', yazi, 'FontSize', 9, 'VerticalAlignment', 'top');
end
% Doğrudan seri etiketleri (çizgilerin sonunda)
text(ax1, j.BitPerPiksel(end), j.PSNR_RGB(end), '  JPEG', 'Color', yazi, ...
     'FontWeight', 'bold', 'FontSize', 10);
text(ax1, b.BitPerPiksel(end), b.PSNR_RGB(end), '  P14', 'Color', yazi, ...
     'FontWeight', 'bold', 'FontSize', 10, 'VerticalAlignment', 'bottom');

stil(ax1, izgara, yazi);
xlabel(ax1, 'Bit / piksel (gerçek dosya boyutu, ham RGB = 24)');
ylabel(ax1, 'PSNR, uçtan uca RGB (dB)');
title(ax1, 'Oran – kalite: aynı boyutta hangisi daha kaliteli?');
legend(ax1, [p1 p2], {'P14 sistemi', 'MATLAB JPEG'}, 'Location', 'southeast', 'Box', 'off');
xlim(ax1, [0, max([b.BitPerPiksel; j.BitPerPiksel]) * 1.15]);

% ---------------- Sağ: hedef PSNR - ölçülen PSNR ----------------
ax2 = nexttile(t);
hold(ax2, 'on');
h = bizim.HedefPSNR;

p0 = plot(ax2, h, h, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
p3 = plot(ax2, h, bizim.PSNR_Y, '-o', 'Color', camgobegi, 'LineWidth', 2, ...
          'MarkerSize', 6, 'MarkerFaceColor', camgobegi, 'MarkerEdgeColor', 'none');
p4 = plot(ax2, h, bizim.PSNR_RGB, '-o', 'Color', mavi, 'LineWidth', 2, ...
          'MarkerSize', 6, 'MarkerFaceColor', mavi, 'MarkerEdgeColor', 'none');

% Q=1 sınırına ilk takıldığı nokta
ilk = find(bizim.Q == 1, 1);
if ~isempty(ilk) && ilk < height(bizim)
    xline(ax2, h(ilk), ':', 'Color', yazi, 'LineWidth', 1);
    text(ax2, h(ilk), min(bizim.PSNR_RGB), ...
         sprintf('Q=1 sınırı: %g dB üstüne  \nçıkılamıyor  ', h(ilk)), ...
         'Color', yazi, 'FontSize', 9, 'VerticalAlignment', 'bottom', ...
         'HorizontalAlignment', 'right');
end
text(ax2, h(end), bizim.PSNR_Y(end), '  Y kanalı', 'Color', yazi, 'FontWeight', 'bold', 'FontSize', 10);
text(ax2, h(end), bizim.PSNR_RGB(end), '  RGB', 'Color', yazi, 'FontWeight', 'bold', 'FontSize', 10);

stil(ax2, izgara, yazi);
xlabel(ax2, 'Hedef PSNR (dB)');
ylabel(ax2, 'Ölçülen PSNR (dB)');
title(ax2, 'Hedef ve ölçülen PSNR (P14)');
legend(ax2, [p0 p3 p4], {'hedef = ölçülen', 'Y kanalı (verici)', 'Uçtan uca RGB (alıcı)'}, ...
       'Location', 'northwest', 'Box', 'off');
xlim(ax2, [h(1) - 1, h(end) + 3]);

title(t, sprintf('P14 DCT sıkıştırma – %s', ad), 'FontWeight', 'bold');
end


function stil(ax, izgara, yazi)
grid(ax, 'on');
ax.GridColor = izgara;
ax.GridAlpha = 1;
ax.Box = 'off';
ax.XColor = yazi;
ax.YColor = yazi;
ax.FontSize = 10;
ax.TickDir = 'out';
ax.Toolbar.Visible = 'off';   % dışa aktarılan PNG'de araç çubuğu görünmesin
end
