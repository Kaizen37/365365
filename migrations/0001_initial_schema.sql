-- Schema for Caminho Diário com Deus / Caminho Diário White Label
-- PostgreSQL compatible

-- Tenants (including default B2C tenant)
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    primary_color TEXT,
    secondary_color TEXT,
    plan TEXT NOT NULL DEFAULT 'starter' CHECK (plan IN ('starter','pro','enterprise')),
    ia_agent_id TEXT,
    ia_credits_balance INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Users with tenant scoping and profile/lead data
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT,
    name TEXT NOT NULL,
    birth_date DATE,
    gender TEXT,
    church_name TEXT,
    city TEXT,
    region TEXT,
    country TEXT,
    tradition TEXT DEFAULT 'protestant' CHECK (tradition IN ('protestant','catholic','orthodox','other')),
    preferred_bible_version TEXT,
    marketing_consent BOOLEAN NOT NULL DEFAULT false,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free','basic','premium')),
    ia_credits_balance INTEGER NOT NULL DEFAULT 0,
    preferences JSONB NOT NULL DEFAULT '{}'::JSONB,
    persona JSONB,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member','church_admin','super_admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email_tenant ON users(email, tenant_id);

-- Leads for marketing segmentation
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    country TEXT,
    tradition TEXT,
    marketing_consent BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_leads_user ON leads(user_id);

-- Bible structure (populated from ABíbliaDigital)
CREATE TABLE bible_books (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    abbreviation TEXT NOT NULL,
    testament TEXT NOT NULL CHECK (testament IN ('AT','NT')),
    order_index INTEGER NOT NULL
);
CREATE UNIQUE INDEX idx_bible_books_order ON bible_books(order_index);

CREATE TABLE bible_chapters (
    id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES bible_books(id) ON DELETE CASCADE,
    number INTEGER NOT NULL
);
CREATE UNIQUE INDEX idx_chapters_book_number ON bible_chapters(book_id, number);

CREATE TABLE bible_verses (
    id SERIAL PRIMARY KEY,
    chapter_id INTEGER NOT NULL REFERENCES bible_chapters(id) ON DELETE CASCADE,
    number INTEGER NOT NULL,
    text TEXT NOT NULL
);
CREATE UNIQUE INDEX idx_verses_chapter_number ON bible_verses(chapter_id, number);

-- Devotional content
CREATE TABLE devotional_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    duration_days INTEGER,
    tags TEXT[],
    is_premium BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_devotional_plans_tenant ON devotional_plans(tenant_id);

CREATE TABLE devotionals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES devotional_plans(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    scripture_reference TEXT,
    content TEXT NOT NULL,
    reflection TEXT,
    prayer TEXT,
    day_index INTEGER,
    tags TEXT[],
    source TEXT NOT NULL DEFAULT 'predefinido' CHECK (source IN ('predefinido','ia','personalizado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_devotionals_tenant_plan_day ON devotionals(tenant_id, plan_id, day_index);

CREATE TABLE user_devotional_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    devotional_id UUID REFERENCES devotionals(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES devotional_plans(id) ON DELETE CASCADE,
    day_index INTEGER,
    read_at TIMESTAMPTZ,
    reading_time_seconds INTEGER,
    completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_user_devotional_progress_user ON user_devotional_progress(user_id);

-- Journal
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    text TEXT,
    hearing_from_god TEXT,
    repentance TEXT,
    gratitude TEXT,
    sync_status TEXT NOT NULL DEFAULT 'local' CHECK (sync_status IN ('local','pending','synced')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_journal_user_date ON journal_entries(user_id, entry_date);

-- Goals and challenges
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    goal_type TEXT NOT NULL,
    parameters JSONB NOT NULL DEFAULT '{}'::JSONB,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_goals_tenant ON goals(tenant_id);

CREATE TABLE user_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    progress NUMERIC(12,2) NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_user_goals_user ON user_goals(user_id);

CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    duration_days INTEGER,
    related_goals UUID[] ,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_challenges_tenant ON challenges(tenant_id);

CREATE TABLE user_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','cancelled')),
    progress NUMERIC(12,2) NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ
);
CREATE INDEX idx_user_challenges_user ON user_challenges(user_id);

-- IA chat
CREATE TABLE ia_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ia_conversations_user ON ia_conversations(user_id);

CREATE TABLE ia_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ia_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user','assistant','system')),
    content TEXT NOT NULL,
    audio_url TEXT,
    estimated_tokens INTEGER,
    consumed_credits INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ia_messages_conversation ON ia_messages(conversation_id);

-- Community
CREATE TABLE community_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    group_type TEXT NOT NULL DEFAULT 'geral',
    visibility TEXT NOT NULL DEFAULT 'tenant' CHECK (visibility IN ('tenant','global','private')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_community_groups_tenant ON community_groups(tenant_id);

CREATE TABLE community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES community_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    post_type TEXT NOT NULL DEFAULT 'reflexao' CHECK (post_type IN ('pedido_oracao','testemunho','versiculo_compartilhado','reflexao')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_community_posts_group ON community_posts(group_id);

CREATE TABLE community_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_community_comments_post ON community_comments(post_id);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notif_type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::JSONB,
    read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications(user_id);

-- Credits and transactions
CREATE TABLE credits_user (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE credit_transactions_user (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('mensal_incluso','compra_pack','consumo','ajuste')),
    amount INTEGER NOT NULL,
    description TEXT,
    stripe_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_credit_tx_user ON credit_transactions_user(user_id);

CREATE TABLE credits_tenant (
    tenant_id UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE credit_transactions_tenant (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('mensal_incluso','compra_pack','consumo','ajuste')),
    amount INTEGER NOT NULL,
    source TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_credit_tx_tenant ON credit_transactions_tenant(tenant_id);

CREATE TABLE credit_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    credits INTEGER NOT NULL,
    reference_price NUMERIC(10,2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Subscriptions
CREATE TABLE subscriptions_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    plan TEXT NOT NULL CHECK (plan IN ('free','basic','premium')),
    status TEXT NOT NULL,
    current_period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_subscriptions_users_user ON subscriptions_users(user_id);

CREATE TABLE subscriptions_tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    plan TEXT NOT NULL CHECK (plan IN ('starter','pro','enterprise')),
    status TEXT NOT NULL,
    current_period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_subscriptions_tenants_tenant ON subscriptions_tenants(tenant_id);

-- Premium content packs
CREATE TABLE premium_content_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_premium_content_tenant ON premium_content_packs(tenant_id);

-- Community favorites/bookmarks (verses)
CREATE TABLE bible_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    verse_id INTEGER NOT NULL REFERENCES bible_verses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_bible_favorites_user_verse ON bible_favorites(user_id, verse_id);

CREATE TABLE bible_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    verse_id INTEGER NOT NULL REFERENCES bible_verses(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_bible_notes_user ON bible_notes(user_id);

-- Audit log
CREATE TABLE audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed data
INSERT INTO tenants (id, name, slug, plan, ia_credits_balance)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Caminho Diário com Deus',
    'caminho-diario',
    'starter',
    0
) ON CONFLICT DO NOTHING;

INSERT INTO credit_packs (id, name, credits, reference_price, active)
VALUES
    ('00000000-0000-0000-0000-000000000101', 'Pack 50 créditos', 50, 9.90, true),
    ('00000000-0000-0000-0000-000000000102', 'Pack 100 créditos', 100, 17.90, true),
    ('00000000-0000-0000-0000-000000000103', 'Pack 200 créditos', 200, 29.90, true),
    ('00000000-0000-0000-0000-000000000104', 'Pack 500 créditos', 500, 59.90, true)
ON CONFLICT DO NOTHING;
