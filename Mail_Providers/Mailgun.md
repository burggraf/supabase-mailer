# using supabase-mailer with Mailgun

## Step 1:  Setup your private keys

Execute the following code in a SQL Query window:

```sql
INSERT INTO private.keys (key, value) values ('MAILGUN_DOMAIN', 'aaaaaaaaaa');
INSERT INTO private.keys (key, value) values ('MAILGUN_API_KEY', 'bbbbbbbbbbb');
INSERT INTO private.keys (key, value) values ('MAILGUN_WEBHOOK_URL', 
    'https://ccccccc@supabase.io/rest/v1/rpc/mailgun_webhook?apikey=ddddddddddddd');
```
Where:
`aaaaaaaaaa` is your Mailgun Domain
`bbbbbbbbbbb` is your Mailgun API Key
`ccccccc@supabase.io` is your Supabase API URL
`ddddddddddddd` is your Supabase ANON (Public) API Key

The last `INSERT` statement is optional -- if you're not using webhooks to track email messages you don't need it.

### API KEY NOTES
Pay careful attention to your Mailgun API Key, it needs to be in the following format:
```
api:key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
so you may need to add the `api:` part to the front of your key.


## Step 2: Create the `send_email_message` function

Run the `SQL` code contained in [02_send_email_message.sql](02_send_email_message.sql) in a query window to create the PostgreSQL function.  NOTE:  You must modify this function for Mailgun.  See the line:
```sql
email_provider text := 'mailgun';
```

## Step 2A: Create the `send_email_mailgun` function
Run the `SQL` code contained in [02A_send_email_mailgun.sql](../02A_send_email_mailgun.sql) in a query window to create the PostgreSQL function. 

## Send a test message

You can send a test message from a query window like this:

```sql
select send_email_message('{
  "sender": "sender@mydomain.com",
  "recipient": "recipient@somewhere.com",
  "subject": "This is a test message from my Supabase app!",
  "html_body": "<html><body>This message was sent from <a href=\"https://postgresql.org\">PostgreSQL</a> using <a href=\"https://supabase.io\">Supabase</a> and <a href=\"https://mailgun.com\">Mailgun</a>.</body></html>"
}');
```
If you've got everything setup correctly, you'll get a JSON object back with the Provider's response, such as:
```
{"id":"<20210809140930.1.A3374464DBAD3C45A@my.mailgun.domain.com>","message":"Queued. Thank you."}
```

At this point, you have everything you need to send messages.  If you want to track your messages, read on.

## Step 3: (Optional) Create the messages table (for tracking messages)

Run the `SQL` code from [03_setup_messages_table.sql](../03_setup_messages_table.sql) in a query window to create the table that will store your email messages.  When the `send_email_message` function senses that this table exists, it will store your messages in this table automatically when you send them.

## Step 4: (Optional) Set up Webhooks

Run the `SQL` code from [04_setup_mailgun_web_hooks.sql](../04_setup_mailgun_web_hooks.sql) to create the functions that will automatically configure your webhooks using the Mailgun API.

This will create the following functions:

- `setup_mailgun_webhooks` -- this is the only function you need to run, and just one time (see below)
- `create_mailgun_webhook` -- this is called by the function above to create each individual webhook
- `mailgun_webhook` -- this is called directly by Mailgun each time the status of one of your messages changes
- `get_current_mailgun_webhooks` -- this is just for debugging -- it goes out to the Mailgun API to see if your webbooks are set up at the Mailgun site

## Step 4A: (Optional) Automatically set up your webhooks at Mailgun using the API
```sql
select setup_mailgun_webhooks();
```

This sets up all your webhooks.  If you want to verify if your webhooks are set up at Mailgun, you can go to the Mailgun site and see them there, or check them with:

```sql
select get_current_mailgun_webhooks();
```

## Step 5: (Optional) Create messages to be sent later

This is completely optional, but if your workflow calls for you to create messages to be sent at a later time (say, according to a schedule, or triggered from another event or table update) you can use the `create_email_message` function.

Run the `SQL` code in [05_create_email_message.sql](../05_create_email_message.sql) in a query window.  Now you can create messages in the messages table like this:

```sql
select create_email_message('{
  "sender": "sender@mydomain.com",
  "recipient": "recipient@somewhere.com",
  "subject": "This is a test message from my Supabase app!",
  "html_body": "<html><body>This message was originally created as \"ready\" in the messages table, then sent later from <a href=\"https://supabase.io\">Supabase</a> using <a href=\"https://mailgun.com\">Mailgun</a>.</body></html>"
}');
```

This will create a message in the messages table with `messages.status` = `ready` and it will return the `messageid` of the message it just created.  To send the message, just call `send_email_message` later and pass it the `messageid` of this message.  For example:

```sql
select send_email_message('{
  "messageid": "7f5fd9b7-cacb-4949-b8d4-a0398fa382e7"
}');
```

## Tracking your messages

If you've set up your `web hooks`, and you've created the `messages` table, then your message statuses will be updated automatically in the `messages` table.   You can watch the status of your message go from `ready` to `queued` to `delivered` to `opened` to `clicked`.  See [Mailgun: Tracking Messages](https://documentation.mailgun.com/en/latest/user_manual.html#tracking-messages).

In addition to the `status` field of the messages table changing, a `log` record is added to the array of events in the `log` field of the messages table.  `log` is a `JSONB` column, so every event for the message is logged individually, along with all the data that comes back from Mailgun, including the timestamp of the event.
