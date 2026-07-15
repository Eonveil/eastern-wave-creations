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

-- 4. Enable Row Level Security (RLS)
ALTER TABLE ewc_secure.vault_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE ewc_secure.console_auth ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies
-- Allow public select (read) on settings
DROP POLICY IF EXISTS "Allow public read access to settings" ON ewc_secure.vault_config;
CREATE POLICY "Allow public read access to settings" 
ON ewc_secure.vault_config 
FOR SELECT 
USING (true);

-- Allow service role to perform all actions on settings
DROP POLICY IF EXISTS "Allow service role to manage settings" ON ewc_secure.vault_config;
CREATE POLICY "Allow service role to manage settings" 
ON ewc_secure.vault_config 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Allow service role to perform all actions on auth table
DROP POLICY IF EXISTS "Allow service role to manage auth" ON ewc_secure.console_auth;
CREATE POLICY "Allow service role to manage auth" 
ON ewc_secure.console_auth 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- 6. Seed initial values
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


-- ============================================================================
-- SQL Statements to update values manually
-- Use these manually inside the SQL Editor to update credentials or site details.
-- ============================================================================

/*
-- Example: Update settings manually
UPDATE ewc_secure.vault_config
SET email = 'info@easternwavecreations.co.za',
    phone = 'Text hello to +27...',
    tagline = 'Engineering next-generation headless websites and automated pipelines.',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

-- Example: Update Webmaster Console Credentials manually
UPDATE ewc_secure.console_auth
SET email = 'webmaster@gmail.com',
    password_hash = 'webmaster123'
WHERE id = 1;
*/
