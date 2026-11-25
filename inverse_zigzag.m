1function [Y_q_rec, Cb_q_rec, Cr_q_rec] = inverse_zigzag(Y_seq, Cb_seq, Cr_seq, pad_r, pad_c)
% 1. Standart 8x8 Zig-Zag İndeksleri
zigzag_order = [1 2 9 17 10 3 4 11 18 25 33 26 19 12 5 6 13 20 27 34 41 49 42 35 28 21 14 7 8 15 22 29 36 43 50 57 58 51 44 37 30 23 16 24 31 38 45 52 59 60 53 46 39 32 40 47 54 61 62 55 48 56 63 64];

% Ters Eşleme (Inverse Mapping): 1D dizideki eleman 8x8'de hangi sıraya gidecek
inverse_zigzag_order = zeros(1, 64);
inverse_zigzag_order(zigzag_order) = 1:64;

% 2. Yardımcı Fonksiyon: 1D diziyi alıp 8x8 bloklar halinde matrise geri katlama
    function rec_channel = rebuild_channel(seq, rows, cols)
        rec_channel = zeros(rows, cols);
        seq_idx = 1;
        for r = 1:8:rows
            for c = 1:8:cols
                % 64 elemanlık parçayı (1 bloğu) diziden al
                zz_block = seq(seq_idx : seq_idx + 63);

                % Ters Zig-Zag uygulayarak orijinal 8x8 sıralamasına getir
                block_1d = zz_block(inverse_zigzag_order);

                % 1D vektörü 8x8 matrise çevir
                block_2d = reshape(block_1d, [8, 8]);

                % Geri kazanılan bloğu ana matristeki yerine yerleştir
                rec_channel(r:r+7, c:c+7) = block_2d;

                % Bir sonraki bloğa geç
                seq_idx = seq_idx + 64;
            end
        end
    end

fprintf('Ters Zig-Zag tarama uygulanıyor ve matrisler yeniden inşa ediliyor...\n');

% 3. Y, Cb ve Cr kanallarını yeniden oluşturma
% Hatırlatma: 4:2:0 alt örnekleme nedeniyle Cb ve Cr kanalları yatay ve dikeyde yarı boyuttadır
Y_q_rec = rebuild_channel(Y_seq, pad_r, pad_c);
Cb_q_rec = rebuild_channel(Cb_seq, pad_r/2, pad_c/2);
Cr_q_rec = rebuild_channel(Cr_seq, pad_r/2, pad_c/2);

fprintf('Matrisler başarıyla 8x8 bloklar halinde geri oluşturuldu.\n');
end