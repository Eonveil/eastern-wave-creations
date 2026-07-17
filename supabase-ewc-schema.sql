-- ============================================================================
-- SQL Script for Setting Up Eastern Wave Creations settings & console auth
-- Execute this manually inside your Supabase SQL Editor
-- ============================================================================

-- 1. Create a custom secure schema (obscured name)
CREATE SCHEMA IF NOT EXISTS ewc_secure;

-- 2. Create the configuration settings table
CREATE TABLE IF NOT EXISTS ewc_secure.vault_config (
    id INT PRIMARY KEY DEFAULT 1,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    tagline TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT single_row CHECK (id = 1)
);

-- 3. Create the webmaster auth table
CREATE TABLE IF NOT EXISTS ewc_secure.console_auth (
    id INT PRIMARY KEY DEFAULT 1,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    CONSTRAINT single_user CHECK (id = 1)
);

-- 4. Create the client briefs table to save inquiries
CREATE TABLE IF NOT EXISTS ewc_secure.client_briefs (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    service TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE ewc_secure.vault_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE ewc_secure.console_auth ENABLE ROW LEVEL SECURITY;
ALTER TABLE ewc_secure.client_briefs ENABLE ROW LEVEL SECURITY;

-- 6. Grant Schema Usage and Permissions
GRANT USAGE ON SCHEMA ewc_secure TO anon, authenticated, service_role, authenticator;

GRANT SELECT, UPDATE ON ewc_secure.vault_config TO anon, authenticated;
GRANT SELECT ON ewc_secure.console_auth TO anon, authenticated;
GRANT SELECT, INSERT ON ewc_secure.client_briefs TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE ewc_secure.client_briefs_id_seq TO anon, authenticated;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ewc_secure TO postgres, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ewc_secure TO postgres, service_role;

-- 7. Create RLS Policies
-- Allow public select (read) on settings
DROP POLICY IF EXISTS "Allow public read access to settings" ON ewc_secure.vault_config;
CREATE POLICY "Allow public read access to settings" 
ON ewc_secure.vault_config 
FOR SELECT 
USING (true);

-- Allow public update settings (so Console using Anon Key can edit them)
DROP POLICY IF EXISTS "Allow public update settings" ON ewc_secure.vault_config;
CREATE POLICY "Allow public update settings"
ON ewc_secure.vault_config
FOR UPDATE
TO anon, authenticated
USING (id = 1)
WITH CHECK (id = 1);

-- Allow public select on auth for login script
DROP POLICY IF EXISTS "Allow select for console login" ON ewc_secure.console_auth;
CREATE POLICY "Allow select for console login"
ON ewc_secure.console_auth
FOR SELECT
TO anon
USING (true);

-- Allow public inserts on briefs (so website form can submit)
DROP POLICY IF EXISTS "Allow public inserts" ON ewc_secure.client_briefs;
CREATE POLICY "Allow public inserts" 
ON ewc_secure.client_briefs 
FOR INSERT 
TO anon, authenticated
WITH CHECK (true);

-- Allow service role to perform all actions
DROP POLICY IF EXISTS "Allow service role to manage settings" ON ewc_secure.vault_config;
CREATE POLICY "Allow service role to manage settings" ON ewc_secure.vault_config FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow service role to manage auth" ON ewc_secure.console_auth;
CREATE POLICY "Allow service role to manage auth" ON ewc_secure.console_auth FOR ALL USING (true) WITH CHECK (true);


-- 8. Seed initial values
-- Seed default profile settings
INSERT INTO ewc_secure.vault_config (id, email, phone, tagline)
VALUES (
    1, 
    'info@easternwavecreations.co.za', 
    'Text ''hello'' to test our live flow', 
    'Engineering modern websites & intelligent WhatsApp communication pipelines.'
)
ON CONFLICT (id) DO UPDATE 
SET email = EXCLUDED.email, 
    phone = EXCLUDED.phone, 
    tagline = EXCLUDED.tagline,
    updated_at = CURRENT_TIMESTAMP;

-- Seed default Webmaster login details (webmaster@gmail.com / webmaster123)
INSERT INTO ewc_secure.console_auth (id, email, password_hash)
VALUES (
    1, 
    'webmaster@gmail.com', 
    'webmaster123'
)
ON CONFLICT (id) DO UPDATE 
SET email = EXCLUDED.email, 
    password_hash = EXCLUDED.password_hash;
