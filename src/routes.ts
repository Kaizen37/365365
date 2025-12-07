import express from 'express';
import { env } from './env.js';
import { stripeClient, requireStripeSecret } from './stripe.js';

export const router = express.Router();

router.get('/config', (_req, res) => {
  res.json({
    adsense: {
      clientId: env.ADSENSE_CLIENT_ID,
      slots: {
        home: env.ADSENSE_SLOT_ID_HOME,
        bible: env.ADSENSE_SLOT_ID_BIBLE,
        feed: env.ADSENSE_SLOT_ID_FEED
      }
    },
    masterAdminEmail: env.MASTER_ADMIN_EMAIL,
    bibleApiBaseUrl: env.BIBLE_API_BASE_URL
  });
});

router.post('/checkout/subscription', async (req, res, next) => {
  try {
    requireStripeSecret();
    const { plan, userId } = req.body as { plan?: string; userId?: string };
    if (!plan || !userId) {
      return res.status(400).json({ error: 'plan and userId are required' });
    }
    const session = await stripeClient().checkout.sessions.create({
      mode: 'subscription',
      line_items: [
        {
          price_data: {
            currency: 'brl',
            product_data: { name: `Plano ${plan}` },
            recurring: { interval: 'month' },
            unit_amount: plan === 'premium' ? 4990 : 2990
          },
          quantity: 1
        }
      ],
      metadata: { type: 'subscription', plan, userId },
      success_url: `${env.APP_BASE_URL ?? 'http://localhost:3000'}/app/loja?status=success`,
      cancel_url: `${env.APP_BASE_URL ?? 'http://localhost:3000'}/app/loja?status=cancelled`
    });
    res.json({ url: session.url, sessionId: session.id });
  } catch (error) {
    next(error);
  }
});

router.post('/webhooks/stripe', express.raw({ type: 'application/json' }), (req, res, next) => {
  try {
    const sig = req.headers['stripe-signature'];
    if (!sig) {
      return res.status(400).send('Missing signature');
    }
    const event = stripeClient().webhooks.constructEvent(req.body, sig as string, env.STRIPE_WEBHOOK_SECRET);
    switch (event.type) {
      case 'checkout.session.completed':
        res.json({ received: true, type: event.type, metadata: (event.data.object as any).metadata });
        break;
      default:
        res.json({ received: true, type: event.type });
    }
  } catch (err) {
    next(err);
  }
});

router.post('/ia/consume-credit', (req, res) => {
  const { creditsAvailable } = req.body as { creditsAvailable?: number };
  if (typeof creditsAvailable !== 'number') {
    return res.status(400).json({ error: 'creditsAvailable must be provided' });
  }
  if (creditsAvailable <= 0) {
    return res.status(402).json({ error: 'Insufficient credits' });
  }
  res.json({ remaining: creditsAvailable - 1, consumed: 1 });
});
