CREATE OR REPLACE FUNCTION public.send_email_mailjet (message JSONB)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER -- required in order to read keys in the private schema
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  AS $$
DECLARE
  retval json;
  MAILJET_API_KEY text;
  MAILJET_SECRET_KEY text;
BEGIN
  SELECT value::text INTO MAILJET_API_KEY FROM private.keys WHERE key = 'MAILJET_API_KEY';
  IF NOT found THEN RAISE 'missing entry in private.keys: MAILJET_API_KEY'; END IF;
  SELECT value::text INTO MAILJET_SECRET_KEY FROM private.keys WHERE key = 'MAILJET_SECRET_KEY';
  IF NOT found THEN RAISE 'missing entry in private.keys: MAILJET_SECRET_KEY'; END IF;

    SELECT
        * INTO retval
    FROM
        http 
        ((
            'POST', 
            'https://api.mailjet.com/v3.1/send', 
            ARRAY[http_header ('Authorization', 
            --'Basic ' || encode((MAILJET_API_KEY || ':' || MAILJET_SECRET_KEY)::bytea, 'base64'::text))], 
            'Basic ' || regexp_replace(encode((MAILJET_API_KEY || ':' || MAILJET_SECRET_KEY)::bytea, 'base64')::text, '\s', '', 'g') 
            )], 
            'application/json',
            json_build_object(
              'Messages', json_build_array(
                json_build_object(
                  'From', json_build_object(
                    'Email', message->>'sender',
                    'Name', message->>'sender'
                  ),
                  'To', json_build_array(
                    json_build_object(
                      'Email', message->>'recipient',
                      'Name', message->>'recipient'
                    )
                  ),
                  'Subject', message->>'subject',
                  'TextPart', message->>'text_body',
                  'HTMLPart', message->>'html_body' --,
                  --'CustomID', message->>'messageid'
                )
              )
            )::text
          
        ));
        -- if the message table exists, 
        -- and the response from the mail server contains an id
        -- and the message from the mail server starts wtih 'Queued'
        -- mark this message as 'queued' in our message table, otherwise leave it as 'ready'
        
        IF (SELECT to_regclass('public.messages')) IS NOT NULL AND 
            retval::text = '200' THEN 
          UPDATE public.messages SET status = 'queued' WHERE id = (message->>'messageid')::UUID;
        ELSE
          RAISE 'error sending message with mailjet: %',retval;
        END IF;

  RETURN retval;
END;
$$;
-- Do not allow this function to be called by public users (or called at all from the client)
REVOKE EXECUTE on function public.send_email_mailjet FROM PUBLIC;

/*
curl -s \
-X POST \
--user "MAILJET_API_KEY:MAILJET_SECRET_KEY" \
https://api.mailjet.com/v3.1/send \
-H 'Content-Type: application/json' \
-d '{
  "Messages":[
    {
      "From": {
        "Email": "from@email.com",
        "Name": "from@email.com"
      },
      "To": [
        {
          "Email": "to@email.com",
          "Name": "to@email.com"
        }
      ],
      "Subject": "My first Mailjet email",
      "TextPart": "Greetings from Mailjet.",
      "HTMLPart": "<h3>Dear passenger 1, welcome to <a href='https://www.mailjet.com/'>Mailjet</a>!</h3><br />May the delivery force be with you!",
      "CustomID": "AppGettingStartedTest"
    }
  ]
}'
*/
