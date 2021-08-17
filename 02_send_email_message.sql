/************************************************************
 *
 * Function:  send_email_message
 * 
 * low level function to send email message
 *
 ************************************************************/
CREATE EXTENSION IF NOT EXISTS HTTP;
drop function send_email_message;
CREATE OR REPLACE FUNCTION public.send_email_message (message JSONB)
  RETURNS json
  LANGUAGE plpgsql
  -- SECURITY DEFINER -- required in order to read keys in the private schema
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  AS $$
DECLARE
  -- variable declaration
  email_provider text := 'mailgun'; -- 'mailgun', 'sendgrid', 'sendinblue'
  retval json;
  messageid text;
BEGIN


  IF message->'text_body' IS NULL AND message->'html_body' IS NULL THEN RAISE 'message.text_body or message.html_body is required'; END IF;
  
  IF message->'text_body' IS NULL THEN     
     select message || jsonb_build_object('text_body',message->>'html_body') into message;
  END IF;
  
  IF message->'html_body' IS NULL THEN 
     select message || jsonb_build_object('html_body',message->>'text_body') into message;
  END IF;  

  IF message->'recipient' IS NULL THEN RAISE 'message.recipient is required'; END IF;
  IF message->'sender' IS NULL THEN RAISE 'message.sender is required'; END IF;
  IF message->'subject' IS NULL THEN RAISE 'message.subject is required'; END IF;

  IF message->'messageid' IS NULL AND (SELECT to_regclass('public.messages')) IS NOT NULL THEN
    -- messages table exists, so save this message in the messages table
    INSERT INTO public.messages(recipient, sender, cc, bcc, subject, text_body, html_body, status, log)
    VALUES (message->'recipient', message->'sender', message->'cc', message->'bcc', message->'subject', message->'text_body', message->'html_body', 'ready', '[]'::jsonb) RETURNING id INTO messageid;
    select message || jsonb_build_object('messageid',messageid) into message;
  END IF;

  EXECUTE 'SELECT send_email_' || email_provider || '($1)' INTO retval USING message;
  -- SELECT send_email_mailgun(message) INTO retval;
  -- SELECT send_email_sendgrid(message) INTO retval;

  RETURN retval;
END;
$$;
-- Do not allow this function to be called by public users (or called at all from the client)
REVOKE EXECUTE on function public.send_email_message FROM PUBLIC;

-- To allow, say, authenticated users to call this function, you would use:
-- GRANT EXECUTE ON FUNCTION public.send_email_message TO authenticated;


