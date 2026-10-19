-- 在 Supabase SQL Editor 執行。價格與商品必須和 config.js 一致。
create extension if not exists pgcrypto;
create table if not exists public.admin_users (user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(), created_at timestamptz not null default now(),
 customer_name text not null check(length(customer_name) between 1 and 60),
 phone text not null check(length(phone) between 7 and 25),
 method text not null check(method in ('pickup','delivery')),
 requested_date date not null, pickup_slot text, address text,
 note text not null default '' check(length(note)<=500),
 items jsonb not null, subtotal integer not null, delivery_fee integer not null, total integer not null,
 status text not null default 'new' check(status in ('new','confirmed','preparing','ready','shipped','completed','cancelled'))
);
create index if not exists orders_created_at_idx on public.orders(created_at desc);
alter table public.orders enable row level security;
alter table public.admin_users enable row level security;
revoke all on public.orders from public,anon,authenticated;
revoke all on public.admin_users from public,anon,authenticated;
grant select,update on public.orders to authenticated;
grant select on public.admin_users to authenticated;
create policy "admins read orders" on public.orders for select to authenticated using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins update orders" on public.orders for update to authenticated using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid()))) with check (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));
create policy "admins read themselves" on public.admin_users for select to authenticated using (user_id=(select auth.uid()));
-- 唯一能讓訪客新增訂單的入口：伺服器核對產品、價格與運費。
create or replace function public.place_order(p_customer_name text,p_phone text,p_method text,p_requested_date date,p_pickup_slot text,p_address text,p_note text,p_items jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_item jsonb; v_id text; v_qty int; v_price int; v_name text; v_subtotal int:=0; v_items jsonb:='[]'::jsonb; v_order_id uuid; v_n int:=0;
begin
 if length(trim(coalesce(p_customer_name,''))) not between 1 and 60 or length(trim(coalesce(p_phone,''))) not between 7 and 25 then raise exception '姓名或電話格式不正確'; end if;
 if p_method not in ('pickup','delivery') then raise exception '無效的配送方式'; end if;
 if p_requested_date is null or p_requested_date<current_date+1 or p_requested_date>current_date+90 then raise exception '請選擇未來90天內的日期'; end if;
 if p_method='pickup' and p_pickup_slot not in ('11:00–13:00','13:00–16:00','16:00–19:00') then raise exception '取貨時段不正確'; end if;
 if p_method='delivery' and length(trim(coalesce(p_address,'')))<8 then raise exception '請填完整地址'; end if;
 if length(coalesce(p_note,''))>500 then raise exception '備註過長'; end if;
 if jsonb_typeof(p_items)!='array' or jsonb_array_length(p_items) not between 1 and 20 then raise exception '訂單商品不正確'; end if;
 for v_item in select value from jsonb_array_elements(p_items) loop
  v_id:=v_item->>'id';
  if coalesce(v_item->>'quantity','') !~ '^[0-9]{1,2}$' then raise exception '數量錯誤'; end if;
  v_qty:=(v_item->>'quantity')::integer;
  if v_qty<1 or v_qty>99 then raise exception '數量超出範圍'; end if;
  select x.price,x.name into v_price,v_name from (values
   ('croissant',65,'經典奶油可頌'),('sourdough',180,'鄉村酸種麵包'),('bagel',55,'原味貝果'),('roll',60,'海鹽奶油捲'),('toast',180,'北海道生吐司'),('bun',75,'巧克力麵包')
  ) as x(id,price,name) where x.id=v_id;
  if not found then raise exception '未知商品'; end if;
  v_n:=v_n+v_qty; v_subtotal:=v_subtotal+v_price*v_qty;
  v_items:=v_items||jsonb_build_array(jsonb_build_object('id',v_id,'name',v_name,'price',v_price,'quantity',v_qty));
 end loop;
 if v_n>100 then raise exception '單筆商品總數不得超過100'; end if;
 insert into public.orders(customer_name,phone,method,requested_date,pickup_slot,address,note,items,subtotal,delivery_fee,total)
 values(trim(p_customer_name),trim(p_phone),p_method,p_requested_date,case when p_method='pickup' then p_pickup_slot else null end,case when p_method='delivery' then trim(p_address) else null end,coalesce(p_note,''),v_items,v_subtotal,case when p_method='delivery' then 160 else 0 end,v_subtotal+case when p_method='delivery' then 160 else 0 end)
 returning id into v_order_id;
 return v_order_id;
end $$;
revoke all on function public.place_order(text,text,text,date,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.place_order(text,text,text,date,text,text,text,jsonb) to anon,authenticated;
-- 先在 Supabase Authentication > Users 建立你的管理員帳號，再執行：
-- insert into public.admin_users(user_id) values ('你的管理員UUID');
