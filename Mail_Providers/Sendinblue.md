# using supabase-mailer with Sendinblue

## Step 1:  Setup your private keys

Execute the following code in a SQL Query window:

```sql
INSERT INTO private.keys (key, value) values ('SENDINBLUE_API_KEY', '[SENDINBLUE_API_KEY]');
```
Where:
`aaaaaaaaaa` is your Sendinblue API Key

## Step 2: Create the `send_email_message` function

Run the `SQL` code contained in [02_send_email_message.sql](02_send_email_message.sql) in a query window to create the PostgreSQL function.  NOTE:  You must modify this function for Sendinblue.  See the line:
```sql
email_provider text := 'sendinblue';
```

## Step 2A: Create the `send_email_sendinblue` function
Run the `SQL` code contained in [02D_send_email_sendinblue.sql](../02D_send_email_sendinblue.sql) in a query window to create the PostgreSQL function. 

## Send a test message

You can send a test message from a query window like this:

```sql
select send_email_message('{
  "sender": "sender@mydomain.com",
  "recipient": "recipient@somewhere.com",
  "subject": "This is a test message from my Supabase app!",
  "html_body": "<html><body>This message was sent from <a href=\"https://postgresql.org\">PostgreSQL</a> using <a href=\"https://supabase.io\">Supabase</a> and <a href=\"https://sendinblue.com\">Sendinblue</a>.</body></html>"
}');
```
If you've got everything setup correctly, you'll get a JSON object back with the Provider's response, such as:
```
200
```

At this point, you have everything you need to send messages.  If you want to track your messages, read on.

## Step 3: (Optional) Create the messages table (for tracking messages)

Run the `SQL` code from [03_setup_messages_table.sql](../03_setup_messages_table.sql) in a query window to create the table that will store your email messages.  When the `send_email_message` function senses that this table exists, it will store your messages in this table automatically when you send them.

## Step 4: (Optional) Webhooks for tracking messages

This step is not yet implemented. 

## Step 5: (Optional) Create messages to be sent later

This is completely optional, but if your workflow calls for you to create messages to be sent at a later time (say, according to a schedule, or triggered from another event or table update) you can use the `create_email_message` function.

Run the `SQL` code in [05_create_email_message.sql](../05_create_email_message.sql) in a query window.  Now you can create messages in the messages table like this:

```sql
select create_email_message('{
  "sender": "sender@mydomain.com",
  "recipient": "recipient@somewhere.com",
  "subject": "This is a test message from my Supabase app!",
  "html_body": "<html><body>This message was originally created as \"ready\" in the messages table, then sent later from <a href=\"https://supabase.io\">Supabase</a> using <a href=\"https://sendinblue.com\">Sendinblue</a>.</body></html>"
}');
```

This will create a message in the messages table with `messages.status` = `ready` and it will return the `messageid` of the message it just created.  To send the message, just call `send_email_message` later and pass it the `messageid` of this message.  For example:

```sql
select send_email_message('{
  "messageid": "7f5fd9b7-cacb-4949-b8d4-a0398fa382e7"
}');
```

