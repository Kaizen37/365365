import express from 'express';
import cors from 'cors';
import { env } from './env.js';
import { router } from './routes.js';

export function createApp() {
  const app = express();
  app.use(cors());
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
