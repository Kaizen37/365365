import express from 'express';
import cors from 'cors';
import { env } from './env.js';
import { router, stripeWebhookHandler } from './routes.js';

export function createApp() {
  const app = express();
  app.use(cors());

  // Stripe exige corpo bruto para validação da assinatura; registre antes do JSON parser
  app.post('/api/webhooks/stripe', express.raw({ type: 'application/json' }), stripeWebhookHandler);

  // Demais rotas podem usar JSON normalmente
  app.use(express.json());
  app.use('/api', router);
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', env: 'ready' });
  });
  app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    if (err instanceof Error) {
      res.status(400).json({ error: err.message });
    } else {
      res.status(500).json({ error: 'Unexpected error' });
    }
  });
  return app;
}
