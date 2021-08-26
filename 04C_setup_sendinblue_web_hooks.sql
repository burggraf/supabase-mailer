CREATE OR REPLACE FUNCTION public.sendinblue_webhook(jsonb) 
returns text 
security definer
language plpgsql
as
$_$
begin
  update public.messages 
    set 
        status = ($1->>'event'),
        log = COALESCE(log, '[]'::jsonb) || $1
    where messages.id = ($1->'tags'->>0)::uuid;
  return 'ok';    
end;
$_$;

/*
{
    "event":"delivered",
    "id":428172,
    "date":"2021-08-25 06:43:06",
    "ts":1629866586,
    "message-id":"<202108251532.75384645670@smtp-relay.mailin.fr>",
    "email":"user@.com",
    "ts_event":1229366586,
    "subject":"Sendinblue webhook test",
    "tag":"[\"5026b7c2-67a8-40d8-b08f-5bb9148bf665\"]",
    "sending_ip":"111.111.111.111",
    "ts_epoch":1629898986496,
    "tags":["5026b7c2-67a8-40d8-b08f-5bb9148bf665"]}

*/