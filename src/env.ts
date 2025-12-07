import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  PORT: z.string().optional().default('4000'),
  SUPABASE_URL: z.string(),
  SUPABASE_ANON_KEY: z.string(),
  SUPABASE_SERVICE_ROLE_KEY: z.string(),
  ELEVENLABS_API_KEY: z.string(),
  ELEVENLABS_AGENT_ID_DEFAULT: z.string(),
  BIBLE_API_BASE_URL: z.string().url(),
  STRIPE_PUBLIC_KEY: z.string(),
  STRIPE_SECRET_KEY: z.string(),
  STRIPE_WEBHOOK_SECRET: z.string(),
  ADSENSE_CLIENT_ID: z.string(),
  ADSENSE_SLOT_ID_HOME: z.string(),
  ADSENSE_SLOT_ID_BIBLE: z.string(),
  ADSENSE_SLOT_ID_FEED: z.string(),
  MASTER_ADMIN_EMAIL: z.string().email(),
  APP_BASE_URL: z.string().url().optional(),
  DATABASE_URL: z.string().optional(),
  JWT_SECRET: z.string().optional()
});

export const env = envSchema.parse(process.env);
