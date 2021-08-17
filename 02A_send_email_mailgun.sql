CREATE OR REPLACE FUNCTION public.send_email_mailgun (message JSONB)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER -- required in order to read keys in the private schema
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  AS $$
DECLARE
  retval json;
  MAILGUN_DOMAIN text;
  MAILGUN_API_KEY text;
BEGIN
  
  SELECT value::text INTO MAILGUN_DOMAIN FROM private.keys WHERE key = 'MAILGUN_DOMAIN';
  IF NOT found THEN RAISE 'missing entry in private.keys: MAILGUN_DOMAIN'; END IF;
  SELECT value::text INTO MAILGUN_API_KEY FROM private.keys WHERE key = 'MAILGUN_API_KEY';
  IF NOT found THEN RAISE 'missing entry in private.keys: MAILGUN_API_KEY'; END IF;

  SELECT
    content INTO retval
  FROM
    http (('POST', 
      'https://api.mailgun.net/v3/' || MAILGUN_DOMAIN || '/messages', 
      ARRAY[http_header ('Authorization', 
      'Basic ' || encode(MAILGUN_API_KEY::bytea, 'base64'::text))], 
      'application/x-www-form-urlencoded', 
      'from=' || urlencode (message->>'sender') || 
      '&to=' || urlencode (message->>'recipient') || 
      CASE WHEN message->>'cc' IS NOT NULL THEN '&cc=' || urlencode(message->>'cc') ELSE '' END || 
      CASE WHEN message->>'bcc' IS NOT NULL THEN '&bcc=' || urlencode(message->>'bcc') ELSE '' END || 
      CASE WHEN message->>'messageid' IS NOT NULL THEN '&v:messageid=' || urlencode(message->>'messageid') ELSE '' END || 
      '&subject=' || urlencode(message->>'subject') || 
      '&text=' || urlencode(message->>'text_body') || 
      '&html=' || urlencode(message->>'html_body')));
      -- if the message table exists, 
      -- and the response from the mail server contains an id
      -- and the message from the mail server starts wtih 'Queued'
      -- mark this message as 'queued' in our message table, otherwise leave it as 'ready'
      IF  (SELECT to_regclass('public.messages')) IS NOT NULL AND 
          retval->'id' IS NOT NULL 
          AND substring(retval->>'message',1,6) = 'Queued' THEN
        UPDATE public.messages SET status = 'queued' WHERE id = (message->>'messageid')::UUID;
      END IF;

  RETURN retval;
END;
$$;
-- Do not allow this function to be called by public users (or called at all from the client)
REVOKE EXECUTE on function public.send_email_mailgun FROM PUBLIC;
