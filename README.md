# Caminho Diário com Deus / White Label

Projeto base com modelagem de dados, variáveis de ambiente e um backend Node/Express inicial para testar fluxos de checkout, consumo de créditos de IA e configuração pública do app.

## Como usar
1. Copie `.env.example` para `.env` e preencha as chaves obrigatórias (Supabase, Stripe, ElevenLabs, AdSense, etc.).
2. Instale dependências: `npm install`.
3. Execute as migrations SQL (`migrations/0001_initial_schema.sql`) em um banco PostgreSQL ou via Supabase SQL editor.
4. Rode em desenvolvimento: `npm run dev` (porta padrão 4000).
5. Testes: `npm test` (usa `.env.test` com valores fictícios).
6. Conecte um frontend PWA com as rotas de aplicativo (`/app/hoje`, `/app/diario`, `/app/biblia`, etc.) e os painéis `/igreja/admin` e `/admin`.

## Conteúdo
- `docs/architecture.md`: visão arquitetural, rotas e requisitos offline/IA/monetização.
- `migrations/0001_initial_schema.sql`: schema completo para usuários, tenants, créditos, Bíblia, devocionais, diário, comunidade, assinaturas e pacotes premium.
- `.env.example`: lista de variáveis obrigatórias e opcionais.
- `src/`: servidor Express com endpoints de configuração pública, checkout de assinatura, webhook Stripe e consumo de crédito de IA.
- `tests/`: testes automatizados de fumaça usando Vitest + Supertest.
