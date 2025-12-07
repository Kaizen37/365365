# Caminho Diário com Deus — Arquitetura e Rotas

Este documento resume a proposta arquitetural, modelagem de dados e rotas principais para o SaaS B2C/B2B "Caminho Diário com Deus" e sua plataforma White Label para igrejas.

## Visão de Arquitetura

- **Frontend**: PWA mobile-first (React/Next.js ou similar) com service worker para cache de assets e rotas essenciais. IndexedDB para dados offline (Bíblia, devocionais em lote, diário pendente).
- **Backend**: API REST multi-tenant (Node/TypeScript + Supabase PostgreSQL). Middlewares garantem escopo de tenant por `tenant_id` a partir do usuário autenticado ou do slug informado.
- **Autenticação**: Supabase Auth (email/senha). Após cadastro, o usuário informa opcionalmente um código de igreja para vincular-se a um tenant; padrão é o tenant `caminho-diario`.
- **Multi-tenant**: Tabelas levam `tenant_id` (nullable para conteúdo global). Policies e filtros sempre aplicam isolamento. Tenants correspondem a igrejas na modalidade White Label.
- **IA**: Integração com ElevenLabs (voz) e LLM para geração de devocionais personalizados. Consumo de créditos registrado em `credit_transactions_user` e `credit_transactions_tenant`.
- **Pagamentos**: Stripe Checkout para assinaturas (planos usuário e igrejas) e compra de créditos/pacotes premium. Webhook `/api/webhooks/stripe` processa eventos e atualiza planos/créditos.
- **Ads**: Componente `<AdSlot />` recebe `ADSENSE_CLIENT_ID` e slot específico. Renderizado somente para plano `free`.
- **Offline-first**:
  - Bíblia: importada da ABíbliaDigital via job inicial para tabelas `bible_books`, `bible_chapters`, `bible_verses`. UI lê de cache local; sincronização eventual.
  - Devocionais: pré-baixo de 7–30 dias para permitir uso offline.
  - Diário: salva localmente e sincroniza quando online, com campo de status de sincronização.

## Rotas Principais (Front)

- `/login`, `/onboarding` (inclui perfil espiritual/demográfico e quiz de arquétipo)
- `/app/hoje` — devocional diário, player de áudio, notas, troca de devocional, criação com propósito
- `/app/diario` — lista e detalhe de notas; pedido de ajuda à IA
- `/app/biblia` — leitura offline filtrada por tradição bíblica e versão preferida
- `/app/metas` — metas sugeridas e personalizadas, progresso e insígnias
- `/app/desafios` — desafios semanais/mensais por tenant; adesão pelo usuário
- `/app/ia` — chat conselheiro espiritual com áudio via ElevenLabs
- `/app/comunidade` — grupos por tenant, posts, comentários, moderação
- `/app/loja` — upgrade de plano, compra de créditos e pacotes premium via Stripe
- `/app/configuracoes` — perfil, tradição bíblica, versão, preferências, notificações, tema, exportar/excluir conta
- `/igreja/admin` — painel de igreja (tenant): métricas, membros, conteúdo, branding, agente IA
- `/admin` — super admin: visão global, gestão de tenants, produtos, métricas financeiras

## Rotas de API (sugestão REST)

- `POST /api/auth/signup` — cria usuário, aceita `church_code`, inicia quiz de arquétipo
- `POST /api/auth/login` — login Supabase
- `POST /api/onboarding/profile` — salva perfil demográfico e tradição bíblica
- `GET /api/devotionals/today` — devocional do dia por tenant e plano
- `POST /api/devotionals/mark-read` — marca leitura e atualiza metas
- `POST /api/devotionals/create-purposeful` — gera plano devocional personalizado com IA
- `GET /api/journal` / `POST /api/journal` — CRUD diário com status de sincronização
- `GET /api/bible/books` / `GET /api/bible/:book/:chapter` — leitura offline com filtro de tradição/versão
- `GET /api/goals` / `POST /api/user-goals` — metas globais e do usuário
- `GET /api/challenges` / `POST /api/user-challenges` — desafios por tenant e adesão
- `GET /api/ia/conversations` / `POST /api/ia/message` — chat IA, consumindo créditos e registrando transações
- `GET /api/community/groups` / `POST /api/community/posts` / `POST /api/community/comments`
- `POST /api/checkout/subscription` — cria sessão de assinatura (user ou tenant)
- `POST /api/checkout/credit-pack` — cria sessão de compra de créditos
- `POST /api/checkout/premium-content` — compra de pacotes devocionais premium
- `POST /api/webhooks/stripe` — webhook de billing, valida com `STRIPE_WEBHOOK_SECRET`
- `GET /api/admin/metrics` — métricas super admin
- `GET /api/tenant/admin/metrics` — métricas e gestão do painel da igreja

## Perfil espiritual e demográfico

Durante o onboarding são coletados nome completo, data de nascimento, sexo, igreja/denominação, localização, tradição cristã, consentimento de marketing e preferências bíblicas. Campos são persistidos em `users` e opcionalmente em `leads` para segmentação. A tradição bíblica controla o canon/versão exibida na aba Bíblia.

## Planos e Créditos

- Planos usuário: `free` (ads + 10 créditos iniciais), `basic` (50 créditos/mês), `premium` (200 créditos/mês), com packs extras de 50/100/200/500 créditos. Pacotes devocionais premium são add-ons.
- Planos tenant: `starter`, `pro`, `enterprise` com franquia de créditos, limites de membros e dashboards.
- Consumo: cada mensagem de IA debita créditos do usuário; se esgotados, bloqueia envio e sugere upgrade/compra. Tenants podem ter franquia própria quando o agente é compartilhado.

## Segurança e governança

- Policies de acesso por `tenant_id` em todas as consultas de dados vinculados.
- Webhook Stripe com validação de assinatura e tratamento de eventos: `checkout.session.completed`, `customer.subscription.*`, `invoice.payment_*`.
- Super admin identificado por `MASTER_ADMIN_EMAIL` com FAB visível apenas para esse usuário.

## Offline e sincronização

- Service worker: cache de assets e rotas principais.
- IndexedDB: Bíblia, devocionais pré-baixados, diário pendente.
- Estratégia de sincronização marca registros com `status_sync` (`local`, `pending`, `synced`) e resolve conflitos pelo timestamp do servidor.

## Dados iniciais

- Tenant padrão `caminho-diario` criado via migration.
- Tabela `credit_packs` pré-populada com 50/100/200/500 créditos.
- Planos referenciais descritos acima para usuários e igrejas.
