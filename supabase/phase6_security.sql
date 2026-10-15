-- Velloura Phase 6 security hardening
-- Run this migration once in the live Supabase SQL Editor.

-- 1. Customers must never be able to update their own role directly.
drop policy if exists "Users can update own profile" on public.profiles;
revoke insert, update, delete on table public.profiles from anon, authenticated;

create or replace function public.update_my_profile(
  p_full_name text,
  p_phone text
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.profiles
  set full_name = nullif(trim(p_full_name), ''),
      phone = nullif(trim(p_phone), '')
  where id = auth.uid()
  returning * into v_profile;

  if v_profile.id is null then
    raise exception 'Profile not found';
  end if;

  return v_profile;
end;
$$;
revoke all on function public.update_my_profile(text,text) from public;
grant execute on function public.update_my_profile(text,text) to authenticated;

-- 2. Block direct browser writes to order tables. Checkout remains through place_order().
revoke insert, update, delete on table public.orders from anon, authenticated;
revoke insert, update, delete on table public.order_items from anon, authenticated;

-- Remove direct admin UPDATE policy: order state changes go through a controlled RPC.
drop policy if exists "Admins update orders" on public.orders;

create or replace function public.admin_update_order_status(
  p_order_id uuid,
  p_status text,
  p_payment_status text
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  if p_status not in ('pending','confirmed','processing','shipped','completed','cancelled') then
    raise exception 'Invalid order status';
  end if;

  if p_payment_status not in ('unpaid','pending','paid','failed','refunded') then
    raise exception 'Invalid payment status';
  end if;

  update public.orders
  set status = p_status,
      payment_status = p_payment_status
  where id = p_order_id
  returning * into v_order;

  if v_order.id is null then
    raise exception 'Order not found';
  end if;

  return v_order;
end;
$$;
revoke all on function public.admin_update_order_status(uuid,text,text) from public;
grant execute on function public.admin_update_order_status(uuid,text,text) to authenticated;

-- 3. Restrict table privileges to only what the browser actually needs.
revoke insert, update, delete on table public.products from anon;
revoke insert, update, delete on table public.product_variants from anon;
revoke insert, update, delete on table public.order_items from authenticated;

-- Authenticated admins still use RLS for product management.
grant select on table public.products, public.product_variants, public.profiles, public.orders, public.order_items to authenticated;
grant select on table public.products, public.product_variants to anon;
grant insert, update, delete on table public.products, public.product_variants to authenticated;

-- 4. Tighten checkout input size and quantity limits while preserving transactional stock locking.
create or replace function public.place_order(
  p_email text,
  p_phone text,
  p_first_name text,
  p_last_name text,
  p_address text,
  p_city text,
  p_country text,
  p_items jsonb
)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare
  v_order_id uuid;
  v_reference text;
  v_subtotal numeric(10,2):=0;
  v_item jsonb;
  v_variant public.product_variants%rowtype;
  v_product public.products%rowtype;
  v_qty integer;
  v_user_id uuid:=auth.uid();
begin
  if coalesce(trim(p_email),'')='' or length(p_email)>254
     or coalesce(trim(p_phone),'')='' or length(p_phone)>40
     or coalesce(trim(p_first_name),'')='' or length(p_first_name)>100
     or coalesce(trim(p_last_name),'')='' or length(p_last_name)>100
     or coalesce(trim(p_address),'')='' or length(p_address)>300
     or coalesce(trim(p_city),'')='' or length(p_city)>100
     or length(coalesce(p_country,''))>100 then
    raise exception 'Delivery details are invalid';
  end if;

  if p_items is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then
    raise exception 'Your bag is empty';
  end if;
  if jsonb_array_length(p_items)>50 then
    raise exception 'Too many order items';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) x
    group by x->>'variant_id'
    having count(*) > 1
  ) then
    raise exception 'Duplicate product variants are not allowed';
  end if;

  begin
    perform 1
    from public.product_variants pv
    where pv.id in(select(x->>'variant_id')::uuid from jsonb_array_elements(p_items)x)
    order by pv.id
    for update;
  exception when invalid_text_representation then
    raise exception 'Invalid product variant';
  end;

  for v_item in select * from jsonb_array_elements(p_items) loop
    begin
      v_qty:=(v_item->>'quantity')::integer;
    exception when others then
      raise exception 'Invalid item quantity';
    end;
    if v_qty is null or v_qty<1 or v_qty>25 then
      raise exception 'Invalid item quantity';
    end if;

    begin
      select * into v_variant from public.product_variants
      where id=(v_item->>'variant_id')::uuid and active=true;
    exception when invalid_text_representation then
      raise exception 'Invalid product variant';
    end;
    if not found then raise exception 'A selected product variant is unavailable'; end if;

    select * into v_product from public.products where id=v_variant.product_id and active=true;
    if not found then raise exception 'A selected product is unavailable'; end if;
    if v_variant.stock<v_qty then raise exception 'Insufficient stock for %',v_product.name; end if;
    v_subtotal:=v_subtotal+(v_product.price*v_qty);
  end loop;

  v_reference:='VEL-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.orders(user_id,reference,email,phone,first_name,last_name,address,city,country,subtotal,status,payment_status)
  values(v_user_id,v_reference,trim(p_email),trim(p_phone),trim(p_first_name),trim(p_last_name),trim(p_address),trim(p_city),coalesce(nullif(trim(p_country),''),'Zimbabwe'),v_subtotal,'pending','unpaid')
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty:=(v_item->>'quantity')::integer;
    select * into v_variant from public.product_variants where id=(v_item->>'variant_id')::uuid;
    select * into v_product from public.products where id=v_variant.product_id;
    insert into public.order_items(order_id,product_id,product_name,size,color,quantity,unit_price)
    values(v_order_id,v_product.id,v_product.name,v_variant.size,v_variant.color,v_qty,v_product.price);
    update public.product_variants set stock=stock-v_qty where id=v_variant.id;
  end loop;

  return v_reference;
end;
$$;
revoke all on function public.place_order(text,text,text,text,text,text,text,jsonb) from public;
grant execute on function public.place_order(text,text,text,text,text,text,text,jsonb) to anon,authenticated;
