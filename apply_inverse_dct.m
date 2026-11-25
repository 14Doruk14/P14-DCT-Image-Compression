function [Y_rec, Cb_rec, Cr_rec] = apply_inverse_dct(Y_q_rec, Cb_q_rec, Cr_q_rec, optimal_Q)
% Standart JPEG Kuantizasyon Matrisleri (Vericideki ile aynı, 0-1 ölçekli)
Q_lum = [16 11 10 16 24 40 51 61;
    12 12 14 19 26 58 60 55;
    14 13 16 24 40 57 69 56;
    14 17 22 29 51 87 80 62;
    18 22 37 56 68 109 103 77;
    24 35 55 64 81 104 113 92;
    49 64 78 87 103 121 120 101;
    72 92 95 98 112 100 103 99] / 255;

Q_chrom = [17 18 24 47 99 99 99 99;
    18 21 26 66 99 99 99 99;
    24 26 56 99 99 99 99 99;
    47 66 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99] / 255;

% 1. Ters Kuantizasyon İşlemi (Dequantization)
% Vericide bölme (./) yapmıştık, şimdi eski genliğe dönmek için çarpma (.*) yapıyoruz
dequantize_block = @(block, Q_mat, scale) block.data .* (Q_mat * scale);

fprintf('Q=%.1f faktörü ile Ters Kuantizasyon uygulanıyor...\n', optimal_Q);
Y_dct_rec = blockproc(Y_q_rec, [8 8], @(b) dequantize_block(b, Q_lum, optimal_Q));
Cb_dct_rec = blockproc(Cb_q_rec, [8 8], @(b) dequantize_block(b, Q_chrom, optimal_Q));
Cr_dct_rec = blockproc(Cr_q_rec, [8 8], @(b) dequantize_block(b, Q_chrom, optimal_Q));

% 2. Ters 2D-DCT İşlemi (IDCT)
idct_func = @(block) idct2(block.data);

fprintf('Frekans uzayından uzamsal alana (piksellere) dönülüyor (2D-IDCT)...\n');
Y_rec = blockproc(Y_dct_rec, [8 8], idct_func);
Cb_rec = blockproc(Cb_dct_rec, [8 8], idct_func);
Cr_rec = blockproc(Cr_dct_rec, [8 8], idct_func);

fprintf('Ters Kuantizasyon ve IDCT başarıyla tamamlandı.\n');
end