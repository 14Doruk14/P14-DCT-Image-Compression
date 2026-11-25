# P14 — DCT-Based Image Compression (MATLAB)

Communication Systems II group project: a JPEG-like image codec that reaches a target PSNR, writes a binary payload for a simulated channel, and decodes it back.

## Pipeline

**Encoder:** RGB → YCbCr + 4:2:0 chroma subsampling (`init_encoder`) → 8×8 block DCT (`apply_2d_dct`) → quantization with a scaled JPEG table, binary search on the scale to hit the target PSNR (`quantize_and_optimize`) → zig-zag + run-length coding with a header (`rle_encode`) → int16 `.bin` payload (`export_payload`).

**Decoder:** `decode_rle` → `inverse_zigzag` → dequantization + inverse DCT (`apply_inverse_dct`) → upsampling and YCbCr → RGB, crop to the original size (`reconstruct_image`) → MSE / PSNR (`analyze_performance`).

## Tools

| File | What it does |
|---|---|
| `p14_pipeline.m` | Runs the whole encoder + decoder chain for one image and target PSNR |
| `run_all.m` | Batch run over `images/` and several PSNR targets, results to `outputs/` |
| `P14_arayuz.m` | GUI (uifigure): load an image, choose PSNR, compress, save, plot the rate–quality curve |
| `oran_kalite_egrisi.m` | Rate–distortion curve: P14 vs. MATLAB JPEG at the same bits per pixel |

Run in MATLAB from this folder: `P14_arayuz` or `run_all`.

## Status

- [x] Encoder, decoder, GUI, rate–quality comparison with JPEG
- [ ] Huffman coding
- [ ] Channel simulation (bit errors)
