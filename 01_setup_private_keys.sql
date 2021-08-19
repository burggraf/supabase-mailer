CREATE SCHEMA IF NOT EXISTS private;
CREATE TABLE IF NOT EXISTS private.keys (
    key text primary key not null,
    value text
);
REVOKE ALL ON TABLE private.keys FROM PUBLIC;

/*******************************************************
*  IMPORTANT:  INSERT YOUR KEYS IN THE COMMANDS BELOW  *
********************************************************

-- [SENDGRID_API_KEY]

-- [PERSONAL_MAILGUN_DOMAIN]

-- [PERSONAL_MAILGUN_API_KEY]
-- (looks like this): api:key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

-- [SUPABASE_API_URL_HERE]
-- Supabase Dashboard / settings / api / config / url

-- [SUPABASE_PUBLIC_KEY_HERE]
-- Supabase Dashboard / settings / api / anon-public key
**************************************************************/

INSERT INTO private.keys (key, value) values ('SENDGRID_API_KEY', '[SENDGRID_API_KEY]');

INSERT INTO private.keys (key, value) values ('SENDINBLUE_API_KEY', '[SENDINBLUE_API_KEY]');

INSERT INTO private.keys (key, value) values ('MAILJET_API_KEY', '[MAILJET_API_KEY]');
INSERT INTO private.keys (key, value) values ('MAILJET_SECRET_KEY', '[MAILJET_SECRET_KEY]');

INSERT INTO private.keys (key, value) values ('MAILGUN_DOMAIN', '[PERSONAL_MAILGUN_DOMAIN]');
INSERT INTO private.keys (key, value) values ('MAILGUN_API_KEY', '[PERSONAL_MAILGUN_API_KEY]');
INSERT INTO private.keys (key, value) values ('MAILGUN_WEBHOOK_URL', 
    'https://[SUPABASE_API_URL_HERE]/rest/v1/rpc/mailgun_webhook?apikey=[SUPABASE_PUBLIC_KEY_HERE]');
