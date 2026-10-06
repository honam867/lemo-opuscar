---
name: ref-image
description: Dùng NGAY KHI bắt đầu một phim Lemo-Opuscar (bước 1 · Brief, lúc chốt style/chủ đề), trước khi viết TREATMENT hay vẽ bất cứ gì. Hỏi người dùng muốn duyệt ảnh mẫu tạo bằng ChatGPT (gpt-image qua Codex CLI, không API key, không trình duyệt) hay để Claude tự thiết kế bằng code; nếu chọn ảnh mẫu thì kiểm tra/cài Codex, tạo ảnh ở bước 3 · Look, chờ duyệt, rồi dựng lại bằng code. Cũng dùng khi người dùng nói "ảnh mẫu", "ref", "tạo ảnh bằng ChatGPT", "cho mình xem trước hình".
---

# Ảnh mẫu trước, code sau

Mặc định, ở bước Look Claude tự hình dung rồi vẽ thẳng bằng code. Skill này cho người dùng chọn thêm một trạm duyệt bằng hình:
**prompt → ảnh gpt-image → người dùng duyệt → Claude dựng lại bằng code (hoặc dùng thẳng ảnh)**.

## Bước 0 · Ở Brief: hỏi và kiểm tra (một lần cho mỗi phim)

1. Chạy `sh .claude/skills/ref-image/gen.sh --check` cùng lúc với `setup.sh deps` của Brief.
2. Thêm câu hỏi này vào **chính tin nhắn hỏi Brief** (AGENTS.md chỉ cho hỏi một lần, không hỏi riêng):

   > **Ảnh mẫu trước khi vẽ?**
   > (a) Tạo ảnh mẫu bằng ChatGPT để bạn duyệt nhân vật/bối cảnh trước. Mỗi ảnh khoảng 2 phút, tính vào gói ChatGPT.
   > (b) Claude tự thiết kế, bạn duyệt model sheet/still vẽ bằng code.
   > (c) Bạn tự có ảnh, thả vào `refs/`.

   Nếu `--check` báo lỗi, ghi luôn trong câu (a) cái gì còn thiếu (xem bảng dưới).
3. Theo câu trả lời:
   - **(a)**: chạy các bước "Cài trên máy mới" nếu còn thiếu, rồi đến bước Look làm "Quy trình".
   - **(b)**: không đụng tới skill này nữa.
   - **(c)**: đọc ảnh trong `refs/`, làm từ bước 5 của "Quy trình".

   Người dùng không trả lời câu này thì mặc định là (b).

## Cài trên máy mới (chỉ khi chọn (a))

| `--check` báo | Việc cần làm |
|---|---|
| `MISSING_CODEX` | Xin phép rồi chạy `npm i -g @openai/codex`. Cần Node.js; nếu chưa có Node thì bảo người dùng cài từ nodejs.org. |
| `NOT_LOGGED_IN` | Bảo người dùng tự chạy `codex login` và đăng nhập tài khoản ChatGPT trên trình duyệt. Claude **không bao giờ** nhập mật khẩu hay token. |

Chạy lại `--check` cho tới khi ra `ok`.

Nếu cài không được (máy công ty, không có quyền…), hạ xuống (c): người dùng tự tạo ảnh trên chatgpt.com rồi thả vào `refs/`.

## Công cụ

```sh
sh .claude/skills/ref-image/gen.sh films/<name>/refs/<slot>_v1.png 1024x1536 "<prompt>" [ảnh-tham-chiếu.png ...]
```

- Chạy từ thư mục gốc thư viện.
- Mỗi ảnh mất khoảng 1–3 phút. Khi tạo nhiều ảnh, chạy nền (`run_in_background`), tối đa 2–3 ảnh song song.
- Kích thước: `1024x1536` (dọc, cho 9:16), `1536x1024` (ngang), `1024x1024`.
- Truyền ảnh đã duyệt làm tham chiếu để các ảnh sau giữ đúng nhân vật.
- Model: script tự thử model mặc định của Codex. Nếu tài khoản ChatGPT không cho dùng model đó, script lần lượt thử các model trong `~/.codex/models_cache.json`. Muốn cố định model thì đặt `CODEX_IMAGE_MODEL`.
- Ảnh tốn hạn mức gói ChatGPT nhiều hơn 3–5 lần một lượt chat chữ. Đừng tạo thừa.

## Quy trình (bước 3 · Look)

1. **Chọn slot** từ `TREATMENT.md`:
   - nhân vật chính (toàn thân, 1 ảnh mỗi nhân vật);
   - mỗi bối cảnh lớn;
   - các khoảnh khắc khó vẽ (bàn tay, tư thế ôm/bê, đạo cụ đặc trưng).

   Thường có 3–6 slot. Báo danh sách cho người dùng trong một dòng rồi chạy luôn.
2. **Viết prompt** bằng tiếng Anh:
   - Phong cách lấy từ `styles/<slug>/STYLE.md`: chất liệu, nét, bảng màu, tỉ lệ giấy trắng.
   - Nội dung lấy từ `TREATMENT.md`: trang phục, tuổi, bối cảnh (Việt Nam nếu có), góc máy, cảm xúc.
   - Không có chữ trong ảnh, trừ khi cần.
3. **Tạo** vào `films/<name>/refs/<slot>_v1.png`. Làm nhân vật trước. Cảnh có nhân vật thì truyền ảnh nhân vật đã duyệt làm tham chiếu.
4. **Duyệt.** Gửi ảnh bằng `SendUserFile` (display: render), mỗi ảnh một dòng mô tả. Người dùng chọn:
   - **duyệt**;
   - **sửa** (ghi rõ sửa gì): tạo `_v2` với prompt mới, ảnh cũ làm tham chiếu;
   - **bỏ**.

   Đây là điểm DỪNG: chờ trả lời rồi mới dựng.
5. **Ghi `films/<name>/refs/REFS.md`**: mỗi slot ghi bản đã duyệt, prompt cuối và cách dùng.
   - `trace` (mặc định): dựng lại bằng code, bám tỉ lệ, dáng, trang phục, bố cục và màu của ảnh. Giữ được mọi chuyển động của style (nét hiện dần, boil, camera, wash loang).
   - `plate`: dùng thẳng ảnh trong phim. Chỉ hợp với nền tĩnh, poster, title card hay ảnh chèn. Ảnh không "vẽ dần" được như nét vẽ bằng code, chỉ hiện ra bằng mask wash/loang. Phải chỉnh màu giấy và độ đậm mực cho khớp phần vẽ bằng code.
6. **Dựng.** Khi viết code, mở lại ảnh `trace` bằng Read để đối chiếu. Render still cùng khung, ghép cạnh ảnh mẫu vào `review/` để người dùng thấy độ khớp. Sau đó tiếp tục quy trình phim bình thường.
7. **CREDITS**: thêm dòng "Reference / plate images generated with OpenAI gpt-image via the user's ChatGPT account".

## Lưu ý

- Không tạo ảnh giống một người thật cụ thể, logo hay nhân vật có bản quyền, trừ khi người dùng sở hữu hoặc có quyền.
- Giữ các bản `_v1`, `_v2`… để so sánh, không xoá.
