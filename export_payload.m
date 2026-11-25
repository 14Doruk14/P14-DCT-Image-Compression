function export_payload(bitstream, filename)
% 10. İletim: Bitstream'i fiziksel bir .bin dosyasına yaz (Simüle edilmiş kanal için)
fileID = fopen(filename, 'w');
if fileID == -1
    error('Dosya oluşturulamadı. İzinleri kontrol edin.');
end

% Bitstream'deki her değer tam sayı (kuantize katsayılar, sıfır adetleri,
% header'da Q*2). Bu yüzden 8 baytlık double yerine 2 baytlık int16 yeterli:
% dosya 4 kat küçülür, hiçbir bilgi kaybolmaz.
% Güvenlik kontrolü: int16'ya sığmayan ya da ondalıklı değer varsa
% sessizce bozmak yerine hata ver.
if any(bitstream ~= round(bitstream))
    fclose(fileID);
    error('Bitstream''de ondalıklı değer var, int16 ile yazılamaz.');
end
if max(abs(bitstream)) > 32767
    fclose(fileID);
    error('Bitstream''de int16 aralığını aşan değer var (en büyük: %g).', max(abs(bitstream)));
end

fwrite(fileID, bitstream, 'int16');
fclose(fileID);

fprintf('--- Aşama 1 Tamamlandı ---\n');
fprintf('Payload başarıyla fiziksel kanala aktarıldı: %s\n', filename);
end