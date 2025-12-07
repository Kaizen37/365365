import request from 'supertest';
import { describe, it, expect, beforeAll } from 'vitest';
import { createApp } from '../src/app.js';
import { env } from '../src/env.js';

const app = createApp();

describe('API smoke tests', () => {
  it('returns health payload', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  it('exposes public config values', async () => {
    const res = await request(app).get('/api/config');
    expect(res.status).toBe(200);
    expect(res.body.masterAdminEmail).toBe(env.MASTER_ADMIN_EMAIL);
    expect(res.body.adsense.clientId).toBe(env.ADSENSE_CLIENT_ID);
  });

  it('rejects IA usage without credits', async () => {
    const res = await request(app).post('/api/ia/consume-credit').send({ creditsAvailable: 0 });
    expect(res.status).toBe(402);
  });
});
