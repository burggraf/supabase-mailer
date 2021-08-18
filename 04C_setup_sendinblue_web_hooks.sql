/************************************************************
*
* Function:  sendinblue_webhook
*
* This is the function that is called when a webhook is received from Sendinblue.
* 
* Sendinblue web hook
* Paste the URL below into all of the Sendinblue WebHook entries
* https://<database_url>.supabase.co/rest/v1/rpc/sendinblue_webhook?apikey=<public_api_key>
*
************************************************************/
drop function sendinblue_webhook;
CREATE OR REPLACE FUNCTION public.sendinblue_webhook(event jsonb)
   returns text 
   language plpgsql
   -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
   -- SET search_path = admin, pg_temp;
  as
$$
declare
messageid text;
begin
/*
  select "event-data"->'user-variables'->>'messageid'::text into messageid;

  update public.messages 
    set 
        deliverysignature = signature,
        deliveryresult = "event-data",
        status = "event-data"->>'event'::text,
        log = COALESCE(log, '[]'::jsonb) || "event-data"-->'event'

    where  messages.id = messageid::uuid;
*/
  -- insert into test (t) values (event::text);

  return 'ok';    
end;
$$;
