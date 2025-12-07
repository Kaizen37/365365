import Stripe from 'stripe';
import { env } from './env.js';

let stripe: Stripe | undefined;

export function stripeClient() {
  if (!stripe) {
    stripe = new Stripe(env.STRIPE_SECRET_KEY, { apiVersion: '2024-06-20' });
  }
  return stripe;
}

export function requireStripeSecret() {
  if (!env.STRIPE_SECRET_KEY) {
    throw new Error('Stripe secret key missing');
  }
}
