CREATE OR REPLACE FUNCTION public.send_email_sendgrid (message JSONB)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER -- required in order to read keys in the private schema
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  AS $$
DECLARE
  retval json;
  SENDGRID_API_KEY text;
BEGIN
  SELECT value::text INTO SENDGRID_API_KEY FROM private.keys WHERE key = 'SENDGRID_API_KEY';
  IF NOT found THEN RAISE 'missing entry in private.keys: SENDGRID_API_KEY'; END IF;

    SELECT
        * INTO retval
    FROM
        http (('POST', 
        'https://api.sendgrid.com/v3/mail/send', 
        ARRAY[http_header ('Authorization', 
        'Bearer ' || SENDGRID_API_KEY)], 
        'application/json',
        json_build_object(
            'personalizations',
            json_build_array(
                json_build_object(
                'to', json_build_array(
                    json_build_object('email', recipient)
                ))),
                'from', json_build_object('email', sender),
                'subject', subject,
                'content', json_build_array(
                    json_build_object('type', 'text/plain', 'value', text_body),
                    json_build_object('type', 'text/html', 'value', html_body)
                ),
                'custom_args', json_build_object(
                    'messageid', COALESCE(messageid,''))
        )::text));

        -- if the message table exists, 
        -- and the response from the mail server contains an id
        -- and the message from the mail server starts wtih 'Queued'
        -- mark this message as 'queued' in our message table, otherwise leave it as 'ready'
        
        IF (SELECT to_regclass('public.messages')) IS NOT NULL AND 
            retval::text = '202' THEN 
          UPDATE public.messages SET status = 'queued' WHERE id = (message->>'messageid')::UUID;
        ELSE
          RAISE 'error sending message with sendgrid: %',retval;
        END IF;

  RETURN retval;
END;
$$;
-- Do not allow this function to be called by public users (or called at all from the client)
REVOKE EXECUTE on function public.send_email_sendgrid FROM PUBLIC;
