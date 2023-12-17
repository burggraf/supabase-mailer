--drop function send_email_resend;
CREATE OR REPLACE FUNCTION public.send_email_resend (message JSONB)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER -- required in order to read keys in the private schema
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  AS $$

DECLARE
  retval json;
  response_status_code int;
  RESEND_API_KEY text;
BEGIN
  SELECT value::text INTO RESEND_API_KEY FROM private.keys WHERE key = 'RESEND_API_KEY';
  IF NOT found THEN RAISE 'missing entry in private.keys: RESEND_API_KEY'; END IF;

    SELECT
        status::int, content::jsonb INTO response_status_code, retval
    FROM
        http (('POST', 
        'https://api.resend.com/emails', 
        ARRAY[http_header ('Authorization', 
        'Bearer ' || RESEND_API_KEY)], 
        'application/json',
        json_build_object(
            'from', message->>'sender',
            'to', message->>'recipient',
            'subject', message->>'subject',
            'text', message->>'text_body',
            'html', message->>'html_body'
        )::text));

        -- check if request successful
        IF response_status_code != 200 THEN 
          RAISE 'error sending message with resend: %', response_status_code;
        END IF;

  RETURN retval;
END;
$$;
-- Do not allow this function to be called by public users (or called at all from the client)
REVOKE EXECUTE on function public.send_email_resend FROM PUBLIC;

/*

curl -X POST 'https://api.resend.com/emails' \
     -H 'Authorization: Bearer re_123456789' \
     -H 'Content-Type: application/json' \
     -d $'{
  "from": "Acme <onboarding@resend.dev>",
  "to": ["delivered@resend.dev"],
  "subject": "hello world",
  "text": "it works!"
}'

*/
