# 麵包未眠｜Cloudflare Pages 上線說明

## 一、網站內容
- `index.html`：顧客預訂頁面，到店取貨及宅配
- `admin.html`：店家登入、瀏覽訂單、改狀態與匯出 CSV
- `config.js`：商品、參考價格、運費及 Supabase 公開設定
- `schema.sql`：訂單資料庫、權限控管及伺服器端核價

## 二、建立接單資料庫
1. 到 https://supabase.com/ 建立專案。
2. 在 SQL Editor 完整執行 `schema.sql`。
3. 到 Project Settings / API Keys 取得 Project URL 與 Publishable key（或舊版 anon key），填入 `config.js`。**切勿使用 secret 或 service_role key。**
4. 在 Authentication > Users 建立店家管理者電子郵件帳號及密碼，取得使用者 UUID。
5. 在 SQL Editor 執行：`insert into public.admin_users (user_id) values ('填入UUID');`。絕對不要把管理員 UUID 或密碼填在前端頁面。
6. 如使用 Supabase 郵件登入或重設密碼，於 Authentication > URL Configuration 設定正式網站網域。請啟用 MFA 並檢查 Auth 安全設定（若可用）。

## 三、Cloudflare Pages 發布
1. 前往 https://dash.cloudflare.com/ ，進入 Workers & Pages。
2. 選擇 Create application > Get started > Drag and drop your files。
3. 建立 `mianbao-weimian` 專案並上傳本資料夾（或其 ZIP）。
4. 點選 Deploy site，即可取得 `mianbao-weimian.pages.dev` 類型的網站網址（實際名稱以 Cloudflare 顯示為準）。
5. 顧客頁為網站根目錄；後台網址為 `/admin.html`。
6. 日後若需更新，仍可在 Pages 專案中重新上傳檔案。注意：Direct Upload 專案之後無法直接切換 Git Integration，需另建專案。

## 四、上線前必做
- 本包產品品項、圖片圖示、商品價格、宅配運費 160 元及取貨時段均為範例。請把 `config.js` 與 `schema.sql` 中的**商品 ID、價格、名稱與運費同步修改**，再實際測試。若變更後已有訂單，請保留原訂單記錄與價格。
- 補齊店家地址、客服電話、營業日期、宅配範圍、食品與過敏原資訊、保存與配送說明、取消退費、個資告知事項。
- 測試顧客下單、後台查看訂單、狀態更新、匯出及錯誤情況。
- 建議使用測試專案先完成驗收，不要在測試時收集真實個資。
- 沒有整合線上付款或訂單通知：接單後需店家主動登入後台查看，也沒有即時庫存扣量、預訂截止時間、排休日及運費試算規則。
- 匿名訪客可透過公開下單函式產生訂單，建議正式營運時加入 Cloudflare Turnstile / rate limiting，以及限制購買數量、防垃圾單、資料保存和刪除政策。
- 目前的後台是初版：對授權管理員開放更新整筆訂單的資料庫權限，正式多人營運前應進一步收斂為僅可更新 `status` 的 RPC。
- 免費方案額度及條款可能變動，需以各服務商最新公告為準。

## 五、注意
網站檔案目前已備妥，但是**尚未部署至任何 Cloudflare 帳號，也尚未連線真實 Supabase 專案**。在完成 Supabase 設定前，顧客頁會明確提示無法送出真實訂單，以避免誤以為接單成功。
