-- Kingstyle booking schema (Supabase / Postgres)

-- 1) UUID extension (required for uuid_generate_v4)
create extension if not exists "uuid-ossp";

-- 2) Time Slots table
create table if not exists public.time_slots (
  id uuid primary key default uuid_generate_v4(),
  slot_date date not null,
  slot_time time not null,
  is_open boolean default true,
  created_at timestamp with time zone default now(),

  unique (slot_date, slot_time)
);

-- 3) Appointments table
create table if not exists public.appointments (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text not null,
  slot_id uuid not null references public.time_slots(id) on delete cascade,
  created_at timestamp with time zone default now(),

  unique (slot_id)
);

-- Optional: Phone validation (Germany-style)
do $$
begin
  alter table public.appointments
  add constraint phone_format_check
  check (phone ~ '^(\+49|0)[1-9][0-9]{7,11}$');
exception
  when duplicate_object then null;
end $$;

-- RLS
alter table public.time_slots enable row level security;
alter table public.appointments enable row level security;

-- Public policies (customers)
drop policy if exists "Public can view open slots" on public.time_slots;
create policy "Public can view open slots"
on public.time_slots
for select
using (is_open = true);

drop policy if exists "Public can create appointments" on public.appointments;
create policy "Public can create appointments"
on public.appointments
for insert
with check (
  exists (
    select 1 from public.time_slots
    where public.time_slots.id = slot_id
      and public.time_slots.is_open = true
  )
);

-- Admin policies (restricted to service_role JWTs)
-- Note: Supabase service_role generally bypasses RLS, but these policies keep things safe
-- if you ever run queries through a role that does not bypass RLS.
drop policy if exists "Admin full access to time slots" on public.time_slots;
create policy "Admin full access to time slots"
on public.time_slots
for all
using (auth.role() = 'service_role')
with check (auth.role() = 'service_role');

drop policy if exists "Admin full access to appointments" on public.appointments;
create policy "Admin full access to appointments"
on public.appointments
for all
using (auth.role() = 'service_role')
with check (auth.role() = 'service_role');

-- Auto-close slot after successful booking
create or replace function public.close_slot_after_booking()
returns trigger as $$
begin
  update public.time_slots
  set is_open = false
  where id = new.slot_id;
  return new;
end;
$$ language plpgsql;

drop trigger if exists after_appointment_insert on public.appointments;
create trigger after_appointment_insert
after insert on public.appointments
for each row
execute procedure public.close_slot_after_booking();

