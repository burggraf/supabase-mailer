# supabase-mailer
Send and track email from Supabase / PostgreSQL using a Transactional Email Provider (Mailgun, Sendgrid, Sendinblue, Mailjet, Mailersend)

## Features
- Send an email message using the API of a Transactional Email Provider 
  - Mailgun
  - Sendgrid
  - Sendinblue
  - Mailjet
  - Mailersend
- Create and store an outgoing email messages in a PostgreSQL table
- Send a `message` from the `messages` table using the API of your selected mail provider
- Webooks can track the status of your messages and update your `messages` table based on various events
  - Mailgun
    - Mailgun webhooks can be set up automatically using their API -- just call the PostgreSQL setup function
    - Mailgun events:
      - temporary_fail
      - permanent_fail
      - delivered
      - opened
      - clicked
      - complained
      - unsubscribed
  - Other providers coming soon...

## Requirements
- Supabase account (free tier is fine)
  - Sending messages should work with any PostgreSQL database (no Supabase account required)
  - Webhooks require a Supabase account so the webhooks have a server (Postgrest) to post event messages to
- A Transactional Email Provider account (most have a free tier available)
  - supported providers: Mailgun, Sendgrid, Sendinblue, Mailjet

## Setup for Mail Providers:

See: [Mailgun Setup](./Mail_Providers/Mailgun.md)

See: [Mailjet Setup](./Mail_Providers/Mailjet.md)

See: [Sendgrid Setup](./Mail_Providers/Sendgrid.md)

See: [Sendinblue Setup](./Mail_Providers/Sendinblue.md)

See: [Mailersend Setup](./Mail_Providers/Mailersend.md)
