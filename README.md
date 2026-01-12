## Kingstyle

This repo is set up to deploy/use Supabase, with environment variables kept out of git.

## Setup (Supabase env)

1. Copy the example env file:

   ```bash
   cp .env.example .env
   ```

2. Put your Supabase keys into `.env` (do **not** commit `.env`).

## Setup (Supabase database)

The SQL for the booking system lives in:

- `supabase/migrations/20260112130000_booking_schema.sql`

To apply it, paste/run that file in **Supabase Dashboard → SQL Editor**, or use the Supabase CLI if you already have it set up.

## Push to GitHub

If you haven’t pushed yet:

```bash
git remote set-url origin https://github.com/Henok131/Kingstyle.git
git push -u origin HEAD
```

