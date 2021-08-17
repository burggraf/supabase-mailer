CREATE OR REPLACE FUNCTION public.send_email_sendinblue (message JSONB)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER -- required in order to read keys in the private schema
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  AS $$
DECLARE
  retval json;
  SENDINBLUE_API_KEY text;
BEGIN
  SELECT value::text INTO SENDINBLUE_API_KEY FROM private.keys WHERE key = 'SENDINBLUE_API_KEY';
  IF NOT found THEN RAISE 'missing entry in private.keys: SENDINBLUE_API_KEY'; END IF;

/*
curl --request POST \
  --url https://api.sendinblue.com/v3/smtp/email \
  --header 'accept: application/json' \
  --header 'api-key:YOUR_API_KEY' \
  --header 'content-type: application/json' \
  --data '{  
   "sender":{  
      "name":"Sender Alex",
      "email":"senderalex@example.com"
   },
   "to":[  
      {  
         "email":"testmail@example.com",
         "name":"John Doe"
      }
   ],
   "subject":"Hello world",
   "htmlContent":"<html><head></head><body><p>Hello,</p>This is my first transactional email sent from Sendinblue.</p></body></html>"
}'
*/
    SELECT
        * INTO retval
    FROM
        http 
        ((
            'POST', 
            'https://api.sendinblue.com/v3/smtp/email', 
            ARRAY[http_header ('api-key', SENDINBLUE_API_KEY)], 
            'application/json',
            json_build_object(
              'sender', json_build_object('name', message->>'sender', 'email', message->>'sender'),
              'to', 
                json_build_array(
                  json_build_object('name', message->>'receipient', 'email', message->>'recipient')
                ),
              'subject', message->>'subject',
              'htmlContent', message->>'html_body',
              'textConent', message->>'text_body'
            )::text
          
        ));

        -- if the message table exists, 
        -- and the response from the mail server contains an id
        -- and the message from the mail server starts wtih 'Queued'
        -- mark this message as 'queued' in our message table, otherwise leave it as 'ready'
        
        IF (SELECT to_regclass('public.messages')) IS NOT NULL AND 
            retval::text = '201' THEN 
          UPDATE public.messages SET status = 'queued' WHERE id = (message->>'messageid')::UUID;
        ELSE
          RAISE 'error sending message with sendinblue: %',retval;
        END IF;

  RETURN retval;
END;
$$;
-- Do not allow this function to be called by public users (or called at all from the client)
REVOKE EXECUTE on function public.send_email_sendinblue FROM PUBLIC;
