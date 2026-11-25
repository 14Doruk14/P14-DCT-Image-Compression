function P14_arayuz
%P14_ARAYUZ  P14 DCT tabanlı görüntü sıkıştırma - grafik arayüz.
%
%   MATLAB'de bu klasördeyken komut penceresine  P14_arayuz  yazın
%   (ya da bu dosyayı açıp Run'a basın).
%
%   1) "Görüntü Yükle" ile bir görüntü seçin
%   2) Hedef PSNR'yi ayarlayın
%   3) "Sıkıştır ve Geri Aç" ile encoder + decoder zinciri çalışır
%   4) Sonuç görüntü, fark haritası, yakın plan ve ölçümler gösterilir
%
%   Hesaplamayı p14_pipeline.m yapar; bu dosya sadece pencereyi kurar.

proje = fileparts(mfilename('fullpath'));
addpath(proje);

%% Pencere ve yerleşim
fig = uifigure('Name', 'P14 - DCT Tabanlı Görüntü Sıkıştırma', ...
               'Position', [60 60 1300 760]);
ana = uigridlayout(fig, [1 2]);
ana.ColumnWidth = {330, '1x'};

% --- Sol panel: kontroller ve sonuçlar ---
sol = uigridlayout(ana, [11 1]);
sol.RowHeight = {28, 36, 40, 20, 30, 40, 34, '1x', 34, 20, 140};
sol.Padding = [8 8 8 8];

uilabel(sol, 'Text', 'P14 · DCT Görüntü Sıkıştırma', ...
        'FontSize', 16, 'FontWeight', 'bold');

ui.btnYukle = uibutton(sol, 'Text', 'Görüntü Yükle...', 'FontSize', 13);

ui.lblDosya = uilabel(sol, 'Text', 'Henüz görüntü seçilmedi.', ...
                      'WordWrap', 'on', 'FontColor', [0.4 0.4 0.4]);

uilabel(sol, 'Text', 'Hedef PSNR (Y kanalı):');
ui.spnHedef = uispinner(sol, 'Limits', [20 50], 'Value', 35, 'Step', 1, ...
                        'ValueDisplayFormat', '%.0f dB');

ui.btnCalistir = uibutton(sol, 'Text', 'Sıkıştır ve Geri Aç', ...
                          'FontSize', 14, 'FontWeight', 'bold', 'Enable', 'off', ...
                          'BackgroundColor', [0.20 0.45 0.80], 'FontColor', [1 1 1]);

ui.btnEgri = uibutton(sol, 'Text', 'Oran–Kalite Eğrisi (JPEG ile karşılaştır)', ...
                      'Enable', 'off', ...
                      'Tooltip', 'Hedef 22–42 dB taranır, MATLAB JPEG ile karşılaştırılır (~1 dk)');

ui.tablo = uitable(sol, 'ColumnName', {'Ölçüm', 'Değer'}, ...
                   'ColumnWidth', {175, '1x'}, 'RowName', {}, 'Data', cell(0, 2));

ui.btnKaydet = uibutton(sol, 'Text', 'Sonuç Görüntüsünü Kaydet...', 'Enable', 'off');

uilabel(sol, 'Text', 'İşlem kaydı:');
ui.txtLog = uitextarea(sol, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 10);

% --- Sağ panel: dört görüntü alanı ---
sag = uigridlayout(ana, [2 2]);
sag.Padding = [4 4 4 4];
ui.axOrj   = goruntu_alani(sag, 'Orijinal');
ui.axGeri  = goruntu_alani(sag, 'Alıcıda geri açılan');
ui.axFark  = goruntu_alani(sag, 'Fark haritası (|orijinal - geri açılan|)');
ui.axYakin = goruntu_alani(sag, 'Yakın plan 64x64 (sol: orijinal, sağ: geri açılan)');

%% Durum ve geri çağırmalar (callback)
fig.UserData = struct('ui', ui, 'proje', proje, 'yol', '', 'sonuc', []);

ui.btnYukle.ButtonPushedFcn    = @(~, ~) goruntu_yukle(fig);
ui.btnCalistir.ButtonPushedFcn = @(~, ~) calistir(fig);
ui.btnKaydet.ButtonPushedFcn   = @(~, ~) sonuc_kaydet(fig);
ui.btnEgri.ButtonPushedFcn     = @(~, ~) egri_ciz(fig);
end


%% ===================== Yardımcı fonksiyonlar =====================

function ax = goruntu_alani(ebeveyn, baslik)
ax = uiaxes(ebeveyn);
title(ax, baslik);
ax.XTick = [];
ax.YTick = [];
ax.Box = 'on';
end


function goruntu_yukle(fig)
d = fig.UserData;
ui = d.ui;

baslangic = fullfile(d.proje, 'images');
if ~exist(baslangic, 'dir')
    baslangic = d.proje;
end
[ad, klasor] = uigetfile( ...
    {'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Görüntü dosyaları'}, ...
    'Sıkıştırılacak görüntüyü seçin', baslangic);
figure(fig);                         % pencereyi tekrar öne getir
if isequal(ad, 0)
    return;                          % kullanıcı iptal etti
end
yol = fullfile(klasor, ad);

try
    bilgi = imfinfo(yol);
    bilgi = bilgi(1);
    imshow(yol, 'Parent', ui.axOrj);
catch hata
    uialert(fig, hata.message, 'Görüntü açılamadı');
    return;
end
title(ui.axOrj, sprintf('Orijinal (%dx%d)', bilgi.Width, bilgi.Height));

% Önceki sonuçları temizle
for ax = [ui.axGeri, ui.axFark, ui.axYakin]
    cla(ax);
end
title(ui.axGeri, 'Alıcıda geri açılan');
ui.tablo.Data = cell(0, 2);
ui.txtLog.Value = {''};

ui.lblDosya.Text = sprintf('%s\n%d x %d piksel, %.0f KB', ...
                           ad, bilgi.Height, bilgi.Width, bilgi.FileSize / 1024);
ui.lblDosya.FontColor = [0 0 0];
ui.btnCalistir.Enable = 'on';
ui.btnEgri.Enable = 'on';
ui.btnKaydet.Enable = 'off';

d.yol = yol;
d.sonuc = [];
fig.UserData = d;
end


function calistir(fig)
d = fig.UserData;
ui = d.ui;
hedef = ui.spnHedef.Value;

cikis = fullfile(d.proje, 'outputs');
if ~exist(cikis, 'dir')
    mkdir(cikis);
end
[~, ad] = fileparts(d.yol);
bin_yolu = fullfile(cikis, sprintf('%s_psnr%g.bin', ad, hedef));

butonlar = [ui.btnYukle, ui.btnCalistir, ui.btnKaydet];
set(butonlar, 'Enable', 'off');
dlg = uiprogressdlg(fig, 'Title', 'İşleniyor', 'Message', 'Başlatılıyor...');

try
    s = p14_pipeline(d.yol, hedef, bin_yolu, @(m, o) ilerle(dlg, m, o));
catch hata
    close(dlg);
    set([ui.btnYukle, ui.btnCalistir], 'Enable', 'on');
    ui.txtLog.Value = splitlines(getReport(hata, 'basic'));
    uialert(fig, hata.message, 'Hata');
    return;
end
close(dlg);

sonuclari_goster(ui, s);

set([ui.btnYukle, ui.btnCalistir, ui.btnKaydet], 'Enable', 'on');
d.sonuc = s;
fig.UserData = d;
end


function egri_ciz(fig)
d = fig.UserData;
ui = d.ui;
butonlar = [ui.btnYukle, ui.btnCalistir, ui.btnEgri, ui.btnKaydet];
eski = get(butonlar, 'Enable');
set(butonlar, 'Enable', 'off');
dlg = uiprogressdlg(fig, 'Title', 'Oran–kalite eğrisi', 'Message', 'Başlatılıyor...');

try
    s = oran_kalite_egrisi(d.yol, @(m, o) ilerle(dlg, m, o));
    close(dlg);
    ui.txtLog.Value = {'Oran–kalite eğrisi kaydedildi:'; s.png; s.tablo};
    % İlerleme penceresi kapanınca odak arayüze dönüyor ve grafik penceresi
    % arayüzün ARKASINA düşüyordu. Grafiği tekrar öne getir.
    drawnow;
    figure(s.figur);
catch hata
    close(dlg);
    uialert(fig, hata.message, 'Hata');
end
for k = 1:numel(butonlar)
    butonlar(k).Enable = eski{k};
end
end


function ilerle(dlg, mesaj, oran)
dlg.Message = mesaj;
dlg.Value = oran;
drawnow;
end


function sonuclari_goster(ui, s)
% Geri açılan görüntü
imshow(s.geri, 'Parent', ui.axGeri);
title(ui.axGeri, sprintf('Alıcıda geri açılan (PSNR %.2f dB)', s.psnr));

% Fark haritası: orijinal geri açılanın boyutuna kırpılır (16'nın katı)
[h, w, ~] = size(s.geri);
orj = s.orijinal(1:h, 1:w, :);
fark = mean(abs(double(orj) - double(s.geri)), 3);
imshow(fark, [0, max(fark(:)) + eps], 'Parent', ui.axFark);
colormap(ui.axFark, hot);
title(ui.axFark, sprintf('Fark haritası (en büyük hata: %.0f / 255)', max(fark(:))));

% Yakın plan: görüntünün ortasından 64x64, 8x8 blok etkisi görünsün diye
% yakınlaştırma 'nearest' ile yapılır (yumuşatma yok)
k = min([64, h, w]);
r0 = floor((h - k) / 2) + 1;
c0 = floor((w - k) / 2) + 1;
parca_orj  = orj(r0:r0+k-1, c0:c0+k-1, :);
parca_geri = s.geri(r0:r0+k-1, c0:c0+k-1, :);
ayrac = 255 * ones(k, 2, 3, 'uint8');
yakin = [parca_orj, ayrac, parca_geri];
imshow(imresize(yakin, 6, 'nearest'), 'Parent', ui.axYakin);

% Ölçüm tablosu
ui.tablo.Data = {
    'Görüntü boyutu',            sprintf('%d x %d', s.boyut(1), s.boyut(2));
    'İşlenen boyut (16 katı)',   sprintf('%d x %d', s.islenen_boyut(1), s.islenen_boyut(2));
    'Hedef PSNR (Y)',            sprintf('%g dB', s.hedef_psnr);
    'Bulunan Q faktörü',         sprintf('%.1f', s.Q);
    'PSNR - Y kanalı (verici)',  sprintf('%.2f dB', s.psnr_y);
    'PSNR - uçtan uca (RGB)',    sprintf('%.2f dB', s.psnr);
    'MSE - uçtan uca',           sprintf('%.2f', s.mse);
    'Bitstream değer sayısı',    sprintf('%d', s.deger_sayisi);
    '.bin dosya boyutu',         sprintf('%.1f KB', s.dosya_bayt / 1024);
    'CR (değer sayısına göre)',  sprintf('%.2fx', s.cr_deger);
    'CR (gerçek dosya)',         sprintf('%.2fx', s.cr_gercek);
    'Süre',                      sprintf('%.1f sn', s.sure)};

ui.txtLog.Value = splitlines(strtrim(s.log));
scroll(ui.txtLog, 'bottom');
end


function sonuc_kaydet(fig)
d = fig.UserData;
if isempty(d.sonuc)
    return;
end
[~, ad] = fileparts(d.yol);
oneri = fullfile(d.proje, 'outputs', sprintf('%s_geri_psnr%g.png', ad, d.sonuc.hedef_psnr));
[dosya, klasor] = uiputfile({'*.png', 'PNG görüntü'}, 'Sonucu kaydet', oneri);
figure(fig);
if isequal(dosya, 0)
    return;
end
imwrite(d.sonuc.geri, fullfile(klasor, dosya));
uialert(fig, sprintf('Kaydedildi:\n%s', fullfile(klasor, dosya)), 'Tamam', 'Icon', 'success');
end
