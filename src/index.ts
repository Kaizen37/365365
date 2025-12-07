import { createApp } from './app.js';
import { env } from './env.js';

const app = createApp();

app.listen(Number(env.PORT), () => {
  console.log(`Server running on http://localhost:${env.PORT}`);
});
