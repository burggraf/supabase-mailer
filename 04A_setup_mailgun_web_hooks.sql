/************************************************************
*
* Function:  mailgun_webhook
*
* This is the function that is called when a webhook is received from Mailgun.
* 
* Mailgun web hook
* Paste the URL below into all of the MailGun WebHook entries
* https://<database_url>.supabase.co/rest/v1/rpc/mailgun_webhook?apikey=<public_api_key>
*
************************************************************/
CREATE OR REPLACE FUNCTION public.mailgun_webhook("event-data" jsonb, "signature" jsonb)
   returns text 
   language plpgsql
   security definer
   -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
   -- SET search_path = admin, pg_temp;
  as
$$
declare
messageid text;
begin
  select "event-data"->'user-variables'->>'messageid'::text into messageid;

  update public.messages 
    set 
        deliverysignature = signature,
        deliveryresult = "event-data",
        status = "event-data"->>'event'::text,
        log = COALESCE(log, '[]'::jsonb) || "event-data"

    where  messages.id = messageid::uuid;

  return 'ok';    
end;
$$
/************************************************************/

/************************************************************
*
* Function:  create_mailgun_webhook
* 
* create, replace, or delete a single mailgun webook 
*
* This function updates a single Mailgun WebHook by calling the Mailgun API.
*
************************************************************/
create or replace function public.create_mailgun_webhook("hook_name" text, "mode" text)
   returns text 
   language plpgsql
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  as
$$
declare 
-- variable declaration
retval text;
MAILGUN_DOMAIN text;
MAILGUN_API_KEY text;
webhooks jsonb;
MAILGUN_WEBHOOK_URL text;
begin
    select value::text into MAILGUN_WEBHOOK_URL from private.keys where key = 'MAILGUN_WEBHOOK_URL';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_WEBHOOK_URL';
    end if;
    select value::text into MAILGUN_DOMAIN from private.keys where key = 'MAILGUN_DOMAIN';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_DOMAIN';
    end if;
    select value::text into MAILGUN_API_KEY from private.keys where key = 'MAILGUN_API_KEY';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_API_KEY';
    end if;

    if mode = 'CREATE' then
      SELECT content into retval FROM http(
        (
          'POST',
          'https://api.mailgun.net/v3/domains/' || MAILGUN_DOMAIN || '/webhooks',
          ARRAY[http_header('Authorization','Basic ' || encode(MAILGUN_API_KEY::bytea,'base64'::text))],
          'application/x-www-form-urlencoded',        
          'id=' ||  urlencode(hook_name) ||
          '&url=' || urlencode(MAILGUN_WEBHOOK_URL)
        )
      );
    elseif mode = 'UPDATE' then
      SELECT content into retval FROM http(
        (
          'PUT',
          'https://api.mailgun.net/v3/domains/' || MAILGUN_DOMAIN || '/webhooks/' || hook_name,
          ARRAY[http_header('Authorization','Basic ' || encode(MAILGUN_API_KEY::bytea,'base64'::text))],
          'application/x-www-form-urlencoded',        
          'url=' || urlencode(MAILGUN_WEBHOOK_URL)
        )
      );
    elseif mode = 'DELETE' then
      SELECT content into retval FROM http(
        (
          'DELETE',
          'https://api.mailgun.net/v3/domains/' || MAILGUN_DOMAIN || '/webhooks/' || hook_name,
          ARRAY[http_header('Authorization','Basic ' || encode(MAILGUN_API_KEY::bytea,'base64'::text))],
          'application/x-www-form-urlencoded',        
          'url=' || urlencode(MAILGUN_WEBHOOK_URL)
        )
      );
    else
      raise 'unknown mode: %', mode;
    end if;

    return retval;
end;
$$

/************************************************************
*
* Function:  setup_mailgun_webhooks
* 
* create or replace ALL mailgun webooks
*
* This function updates ALL Mailgun WebHooks by calling the Mailgun API.
*
* It calls create_mailgun_webhook to create webhooks for:
*
* clicked, delivered, opened, complained, permanent_fail, temporary_fail, and unsubscribed.
*
************************************************************/
create or replace function public.setup_mailgun_webhooks()
   returns text 
   language plpgsql
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  as
$$
declare 
-- variable declaration
MAILGUN_DOMAIN text;
MAILGUN_API_KEY text;
webhooks jsonb;
MAILGUN_WEBHOOK_URL text;
hook_result text;
retval text;
begin
    select value::text into MAILGUN_WEBHOOK_URL from private.keys where key = 'MAILGUN_WEBHOOK_URL';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_WEBHOOK_URL';
    end if;
    select value::text into MAILGUN_DOMAIN from private.keys where key = 'MAILGUN_DOMAIN';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_DOMAIN';
    end if;
    select value::text into MAILGUN_API_KEY from private.keys where key = 'MAILGUN_API_KEY';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_API_KEY';
    end if;
    SELECT content into webhooks FROM http(
      (
        'GET',
        -- replace(MAILGUN_URL_MESSAGES, '/messages', '/webhooks'),
        'https://api.mailgun.net/v3/domains/' || MAILGUN_DOMAIN || '/webhooks',
        ARRAY[http_header('Authorization','Basic ' || encode(MAILGUN_API_KEY::bytea,'base64'::text))],
        'application/x-www-form-urlencoded',
        ''
      )
    );

    select '[' into retval;

    if length(webhooks->'webhooks'->>'clicked') > 0 then
      select public.create_mailgun_webhook('clicked', 'UPDATE') into hook_result;
    else
      select public.create_mailgun_webhook('clicked', 'CREATE') into hook_result;
    end if;

    select retval || '{ "clicked": "' || (hook_result::jsonb->>'message'::text) || '" } ' into retval::text;

    if length(webhooks->'webhooks'->>'complained') > 0 then
      select public.create_mailgun_webhook('complained', 'UPDATE') into hook_result;
    else
      select public.create_mailgun_webhook('complained', 'CREATE') into hook_result;
    end if;

    select retval || ', { "complained": "' || (hook_result::jsonb->>'message'::text) || '" } ' into retval::text;

    if length(webhooks->'webhooks'->>'delivered') > 0 then
      select public.create_mailgun_webhook('delivered', 'UPDATE') into hook_result;
    else
      select public.create_mailgun_webhook('delivered', 'CREATE') into hook_result;
    end if;

    select retval || ', { "delivered": "' || (hook_result::jsonb->>'message'::text) || '" } ' into retval::text;

    if length(webhooks->'webhooks'->>'opened') > 0 then
      select public.create_mailgun_webhook('opened', 'UPDATE') into hook_result;
    else
      select public.create_mailgun_webhook('opened', 'CREATE') into hook_result;
    end if;

    select retval || ', { "opened": "' || (hook_result::jsonb->>'message'::text) || '" } ' into retval::text;

    if length(webhooks->'webhooks'->>'permanent_fail') > 0 then
      select public.create_mailgun_webhook('permanent_fail', 'UPDATE') into hook_result;
    else
      select public.create_mailgun_webhook('permanent_fail', 'CREATE') into hook_result;
    end if;

    select retval || ', { "permanent_fail": "' || (hook_result::jsonb->>'message'::text) || '" } ' into retval::text;

    if length(webhooks->'webhooks'->>'temporary_fail') > 0 then
      select public.create_mailgun_webhook('temporary_fail', 'UPDATE') into hook_result;
    else
      select public.create_mailgun_webhook('temporary_fail', 'CREATE') into hook_result;
    end if;

    select retval || ', { "temporary_fail": "' || (hook_result::jsonb->>'message'::text) || '" } ' into retval::text;

    if length(webhooks->'webhooks'->>'unsubscribed') > 0 then
      select public.create_mailgun_webhook('unsubscribed', 'UPDATE') into hook_result;
    else
      select public.create_mailgun_webhook('unsubscribed', 'CREATE') into hook_result;
    end if;

    select retval || ', { "unsubscribed": "' || (hook_result::jsonb->>'message'::text) || '" } ' into retval::text;
    
    select retval || ']' into retval;

    return retval::jsonb;
  
end;
$$

/************************************************************
*
* Function:  get_current_mailgun_webhooks
* 
* list the status of all mailgun webhooks
*
************************************************************/

create or replace function public.get_current_mailgun_webhooks()
   returns jsonb 
   language plpgsql
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.  abort 
  -- SET search_path = admin, pg_temp;
  as
$$
declare 
-- variable declaration
MAILGUN_DOMAIN text;
MAILGUN_API_KEY text;
retval jsonb;
begin

    select value::text into MAILGUN_DOMAIN from private.keys where key = 'MAILGUN_DOMAIN';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_DOMAIN';
    end if;
    select value::text into MAILGUN_API_KEY from private.keys where key = 'MAILGUN_API_KEY';
    if not found then
      raise 'missing entry in private.keys: MAILGUN_API_KEY';
    end if;
    
    SELECT content into retval FROM http(
      (
        'GET',
        -- replace(MAILGUN_URL_MESSAGES, '/messages', '/webhooks'),
        'https://api.mailgun.net/v3/domains/' || MAILGUN_DOMAIN || '/webhooks',
        ARRAY[http_header('Authorization','Basic ' || encode(MAILGUN_API_KEY::bytea,'base64'::text))],
        'application/x-www-form-urlencoded',
        ''
      )
    );

    return retval::jsonb;
  
end;
$$


/*
Webhook testing and troubleshooting:

webhooks:
clicked
complained
delivered
opened
permanent_fail
temporary_fail
unsubscribed

get webhooks
curl -s --user "api:key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" "https://api.mailgun.net/v3/domains/MY_DOMAIN/webhooks"

create webhook
curl -s --user 'api:YOUR_API_KEY' \
   https://api.mailgun.net/v3/domains/YOUR_DOMAIN_NAME/webhooks \
   -F id='clicked' \
   -F url='https://YOUR_SUPABASE_URL/rest/v1/rpc/mailgun_webhook?apikey=YOUR_PUBLIC_SUPABASE_KEY'

update webhook
curl -s --user 'api:YOUR_API_KEY' -X PUT \
    https://api.mailgun.net/v3/domains/YOUR_DOMAIN_NAME/webhooks/clicked \
    -F url='https://your_domain,com/v1/clicked'

delete webhook
curl -s --user 'api:YOUR_API_KEY' -X DELETE \
    https://api.mailgun.net/v3/domains/YOUR_DOMAIN_NAME/webhooks/clicked

*/
