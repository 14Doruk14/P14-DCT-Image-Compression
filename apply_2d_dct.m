function [Y_dct, Cb_dct, Cr_dct] = apply_2d_dct(Y, Cb_sub, Cr_sub)
% 8x8 DCT dönüşümünü uygulayacak fonksiyon (block processing için)
dct_func = @(block_struct) dct2(block_struct.data);

% Y, Cb ve Cr kanallarını örtüşmeyen 8x8 bloklara ayır ve 2D-DCT uygula
Y_dct = blockproc(Y, [8 8], dct_func);
Cb_dct = blockproc(Cb_sub, [8 8], dct_func);
Cr_dct = blockproc(Cr_sub, [8 8], dct_func);

% --- GÖZLEM VE TEST BLOĞU ---
% DCT'nin enerjiyi nasıl sol üst köşede (düşük frekanslar) topladığını görmek için
figure('Name', 'Stage 1: 8x8 2D-DCT Transformation', 'NumberTitle', 'off');

subplot(1,2,1);
imshow(Y(1:64, 1:64)); % Y kanalından 64x64'lük bir kesit (8 adet 8x8 blok)
title('Uzamsal Alan (Pikseller)');

subplot(1,2,2);
% DCT katsayılarının logaritmik dönüşümü (görselleştirmeyi kolaylaştırmak için)
imshow(log(abs(Y_dct(1:64, 1:64)) + 1), []);
title('Frekans Alanı (DCT Katsayıları)');
colormap(gca, jet);
colorbar;
end