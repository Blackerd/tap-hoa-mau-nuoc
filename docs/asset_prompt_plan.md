# Kế Hoạch Tổng Thể Bộ Prompt Tạo Asset (Chuẩn Mobile/iPad - Góc Nhìn Chính Diện)

Tài liệu này là **Danh mục Prompt chuẩn hóa cuối cùng** để bạn lần lượt tạo từng tấm Asset và gửi cho mình xử lý tự động (tách nền trong suốt, cắt Sprite theo kích thước ô gạch và gắn vào Godot 4).

> [!TIP]
> **Mẹo tạo đồng bộ 100% nét vẽ:**
> Khi chạy các Prompt từ **Tấm số 0** đến **Tấm số 5**, bạn có thể đính kèm bức ảnh nền `Tạp Hóa Màu Nước` bạn vừa tạo làm **Style Reference (Ảnh mẫu phong cách)** trong công cụ AI để mọi kệ hàng, nhân vật và UI đều có chung một nét bút mực và màu nước!

---

## 📋 Danh Sách 6 Tấm Ảnh Cần Tạo (Checklist)

| STT | Tên gói Asset | Trạng thái | Mục đích sử dụng trong Godot 4 |
| :--- | :--- | :--- | :--- |
| **Tấm 0** | **Hình Tổng Quát Gameplay** | ⏳ *Cần tạo* | Làm hình mẫu tổng thể (Key Art) tập trung vào hoạt động mua bán nhộn nhịp + UI Mobile/iPad. |
| **Tấm 1** | **Background Mặt Bằng Trống** | ✅ *Đã có & Đã gắn vào game* | Mặt sàn `10x5` ô vuông, tường bảng hiệu, cây bàng, bàn trà đá, vỉa hè ngang. |
| **Tấm 2** | **Sheet Kệ Hàng & Quầy Thu Ngân** | ⏳ *Cần tạo* | Cắt rời thành Kệ gỗ, Tủ kem, Giá treo đồ mưa, Quầy thu ngân (đặt lên ô gạch `72x78 px`). |
| **Tấm 3** | **Sheet Icon Hàng Hóa & Thời Tiết** | ⏳ *Cần tạo* | Cắt rời 6 món hàng + Icon Tiền, Tim, Hũ kẹo, Nắng/Mưa/Gió cho HUD & Sổ Cái. |
| **Tấm 4** | **Sheet Nhân Vật Chibi** | ⏳ *Cần tạo* | Cắt rời 6 nhân vật khách hàng + Chủ quán + Mèo tam thể. |
| **Tấm 5** | **Sheet Khung UI/UX Cảm Ứng** | ⏳ *Cần tạo* | Cắt rời làm khung giấy HUD, Quầy thu ngân, Sổ cái, Nút bấm to chuẩn Mobile/iPad & Dấu mộc. |

---

## 🎯 Tấm số 0: Hình Tổng Quát Gameplay Tập Trung Hoạt Động (Gameplay Overview)
* **Mục đích:** Nhìn tổng thể toàn bộ màn hình game trên Mobile/iPad khi quán đang đông khách, đầy đủ kệ hàng, nhân vật và HUD.
* **Tỉ lệ:** `16:9`
* **Prompt copy-paste:**
```text
Full 2D mobile & iPad management game screenshot in cozy hand-drawn ink linework and watercolor wash style, strictly front-facing top-down orthographic view (NOT isometric, straight horizontal and vertical square floor grid). Center features the rectangular square-tiled grocery shop bustling with gameplay activity: 4 front-facing wooden shelves stocked with colorful snack packs, mung bean popsicles, soda bags, and blue raincoats; a brown wooden cashier counter at the bottom-left corner of the room with a pink glass candy jar and a friendly shopkeeper checking out customers. Cute chibi Vietnamese schoolkids with red scarves and neighborhood aunties walking between shelves with small floating item thought bubbles above their heads. On the left courtyard under the green banyan tree, an old neighbor is sipping iced tea at the small blue table with red plastic stools. Clean touch-friendly mobile UI tucked neatly at the 4 corners: top-left cream paper status badge, top-right level upgrade badge, bottom-left cashier checkout card with 3 touch buttons (green, yellow, pink), and a centered bottom horizontal toolbar. Warm Dordogne watercolor aesthetic --ar 16:9
```

---

## 🏡 Tấm số 1: Background Mặt Bằng Quán Trống (`bg_store_ortho.jpg`)
*(✅ Bạn đã tạo xong tấm này rất chuẩn và mình đã tích hợp vào game. Giữ lại prompt ở đây nếu về sau bạn muốn tạo thêm bản Ban Đêm hoặc bản Tết).*
```text
Front-facing top-down 2D orthographic game background illustration in hand-drawn ink linework and soft watercolor wash on cream cold-press paper (NOT isometric, NO diagonal walls, all lines strictly horizontal and vertical parallel to the screen edges). In the center is a wide rectangular grocery shop floor made of a 10x5 grid of flat square cream tiles, completely EMPTY inside with no furniture, bordered at the top by a straight horizontal wooden back wall featuring a centered signboard "TAP HOA MAU NUOC". On the left outside the shop is a green banyan tree and a small blue sidewalk tea table with two tiny red stools. Along the bottom runs a straight horizontal sidewalk from left to right. Generous cream watercolor paper negative space around the outer margins, no UI, no characters --ar 16:9
```

---

## 🗄️ Tấm số 2: Sprite Sheet Kệ Hàng & Quầy Thu Ngân Nhìn Thẳng (`sheet_furniture.png`)
* **Yêu cầu kỹ thuật:** Nền trắng tinh `#FFFFFF`, các kệ đứng **nhìn thẳng chính diện (Front-facing)**, tách rời nhau để mình cắt từng cái đặt vào ô gạch vuông của quán.
* **Tỉ lệ:** `16:9`
* **Prompt copy-paste:**
```text
Front-facing top-down 2D orthographic game furniture sprite sheet in hand-drawn ink outline and watercolor wash style (strictly front-facing view parallel to screen, NOT isometric, NOT angled diagonally), isolated on pure flat solid white background #FFFFFF. Arranged in a neat 2x3 grid with wide empty white spacing between items, no overlapping, no text labels:
1) Front-facing wooden 3-tier grocery shelf rack filled with yellow crunchy noodle packs,
2) Front-facing light-blue ice cream freezer chest with green popsicles visible inside,
3) Front-facing sage-green display rack hanging folded raincoats and peanut candy packs,
4) Front-facing wooden shelf rack stocked with orange soda bags and coffee boxes,
5) Front-facing brown wooden cashier counter desk with a vintage cash register, an open ledger book, and a pink glass candy jar on top,
6) Front-facing empty wooden 3-tier grocery shelf rack (out-of-stock state) and a sleeping calico cat on a small cushion.
Crisp dark brown ink outlines, flat horizontal bottom edges, clean silhouettes for automatic cutout --ar 16:9
```

---

## 🍬 Tấm số 3: Sprite Sheet Icon Hàng Hóa & Biểu Tượng HUD (`sheet_items.png`)
* **Yêu cầu kỹ thuật:** Nền trắng tinh `#FFFFFF`, lưới `3x4` (12 icon tách biệt) bao gồm 6 mặt hàng tạp hóa + 6 icon trạng thái cho HUD Mobile/iPad.
* **Tỉ lệ:** `16:9`
* **Prompt copy-paste:**
```text
2D game item and HUD icon sprite sheet in hand-drawn ink and watercolor illustration style, front-facing flat icons isolated on pure flat solid white background #FFFFFF. Arranged in a clean 3x4 grid (12 icons total) with wide white spacing between icons, no overlapping, no text:
Row 1 (Grocery items):
1) Yellow retro Vietnamese crunchy snack noodle pack,
2) Green mung bean popsicle ice cream bar on wooden stick,
3) Orange soda in a clear plastic bag tied with red rubber band and straw,
4) Peanut candy bar wrapped pack,
Row 2 (More items & currency):
5) Folded blue polka-dot raincoat pack,
6) Instant coffee sachet with a small cup noodle,
7) Glass jar filled with colorful fruit candies,
8) Stack of vintage paper banknotes and coins,
Row 3 (HUD status icons):
9) Red watercolor heart icon (neighbor reputation),
10) Bright warm sun icon (sunny weather),
11) Raincloud with raindrops icon (rainy weather),
12) Vintage wooden wall clock / calendar icon.
Clean dark ink outlines, vibrant warm watercolor washes, easy to crop --ar 16:9
```

---

## 🧒 Tấm số 4: Sprite Sheet Nhân Vật Khách Hàng & Chủ Quán (`sheet_customers.png`)
* **Yêu cầu kỹ thuật:** Nền trắng tinh `#FFFFFF`, 6 nhân vật đứng nhìn thẳng chính diện trên 1 hàng ngang, khoảng cách rộng để mình cắt tự động.
* **Tỉ lệ:** `16:9`
* **Prompt copy-paste:**
```text
Front-facing top-down 2D RPG character sprite sheet in cozy hand-drawn ink and watercolor chibi style (Stardew Valley character perspective, strictly facing straight forward), isolated on pure flat solid white background #FFFFFF. 6 distinct Vietnamese neighborhood characters arranged in a single horizontal row with wide empty white spacing between each character, no overlapping:
1) Cute schoolboy wearing white shirt and red scarf,
2) Cute schoolgirl with pigtails and yellow backpack,
3) Young male architecture student with glasses and blue shirt,
4) Friendly middle-aged neighbor uncle in sage-green polo shirt,
5) Neighborhood housewife auntie in purple blouse holding a small basket,
6) Kind grocery shopkeeper wearing a brown apron over cream shirt.
Clean dark brown ink outlines, full chibi body from head to shoes, no shadows touching neighbors --ar 16:9
```

---

## 📱 Tấm số 5: Bộ Khung Giao Diện UI/UX Chuẩn Cảm Ứng Mobile/iPad (`sheet_ui_frames.png`)
* **Yêu cầu kỹ thuật:** Nền trắng tinh `#FFFFFF`, bên trong các khung giấy và nút bấm **hoàn toàn để trống (không có chữ hay số)** để mình cắt làm `StyleBoxTexture` co giãn theo mọi chữ tiếng Việt trong Godot 4.
* **Tỉ lệ:** `16:9`
* **Prompt copy-paste:**
```text
2D mobile game UI/UX frame and touch button asset kit in hand-drawn watercolor and ink sketchbook style, isolated on pure flat solid white background #FFFFFF. Arranged in a neat non-overlapping layout with wide white spacing, completely BLANK inside every frame (NO text, NO numbers, NO icons inside):
1) Medium rounded rectangular cream paper card frame with dark brown ink border (for top status HUD),
2) Medium rounded rectangular cream paper card frame with red ink border and masking tape at top corners (for cashier checkout popup),
3) Long horizontal cream paper toolbar strip with deckled edges and dark ink border (for bottom touch bar),
4) Tall vertical open notebook page frame with spiral rings on the left edge (for right-side ledger menu),
5) Four blank chunky rounded pill button frames (sage green, warm yellow, soft coral pink, and cream paper) with dark ink outlines,
6) Small blank rectangular paper speech bubble frame with a tiny bottom pointer, and a circular red rubber stamp ring frame.
Crisp dark ink borders on solid #FFFFFF white background for NinePatch UI slicing --ar 16:9
```

---

## 🚀 Cách Bạn Gửi Asset Cho Mình Xử Lý

Bạn có thể tạo từng tấm hoặc tạo hết 1 lượt rồi:
* **Cách 1:** Tải ảnh trực tiếp lên khung chat này (giống như bạn vừa gửi tấm Background).
* **Cách 2:** Bỏ ảnh vào thư mục [`c:\cty\tap_hoa_mau_nuoc\assets\raw`](file:///c:/cty/tap_hoa_mau_nuoc/assets/raw/DROP_IMAGES_HERE.txt) rồi nhắn mình.

Ngay khi nhận được ảnh của bạn, mình sẽ:
1. Chạy script tự động **xóa nền trắng `#FFFFFF` sang nền trong suốt (Alpha PNG)** mượt mà không bị viền răng cưa.
2. **Tự động cắt rời (Slice)** từng kệ hàng, từng nhân vật, từng icon và từng khung giấy UI lưu vào `res://assets/sprites/`.
3. **Cập nhật code Godot 4** để thay thế toàn bộ các khối vẽ tạm bằng bộ Asset màu nước xịn của bạn!
