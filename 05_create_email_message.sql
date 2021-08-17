/************************************************************
*
* Function:  create_email_message(message JSON)
* 
* create a message in the messages table
*
{
  recipient: "", -- REQUIRED 
  sender: "", -- REQUIRED 
  cc: "",
  bcc: "",
  subject: "", -- REQUIRED 
  text_body: "", -- one of: text_body OR html_body is REQUIRED  
  html_body: "" -- both can be sent but one of them is REQUIRED
}
returns:  uuid (as text) of newly inserted message
************************************************************/
create or replace function public.create_email_message(message JSON)
   returns text
   language plpgsql
  -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
  -- SET search_path = admin, pg_temp;
  as
$$
declare 
-- variable declaration
recipient text;
sender text;
cc text;
bcc text;
subject text;
text_body text;
html_body text;
retval text;
begin
  /*
  if not exists (message->>'recipient') then
    RAISE INFO 'messages.recipient missing';
  end if
  */
  select  message->>'recipient', 
          message->>'sender',
          message->>'cc',
          message->>'bcc',
          message->>'subject',
          message->>'text_body',
          message->>'html_body' into recipient, sender, cc, bcc, subject, text_body, html_body;
  
  if coalesce(sender, '') = '' then
    -- select 'no sender' into retval;
    RAISE EXCEPTION 'message.sender missing';
  elseif coalesce(recipient, '') = '' then
    RAISE EXCEPTION 'message.recipient missing';
  elseif coalesce(subject, '') = '' then
    RAISE EXCEPTION 'message.subject missing';
  elseif coalesce(text_body, '') = '' and coalesce(html_body, '') = '' then
    RAISE EXCEPTION 'message.text_body and message.html_body are both missing';
  end if;

  if coalesce(text_body, '') = '' then
    select html_body into text_body;
  elseif coalesce(html_body, '') = '' then
    select text_body into html_body;
  end if; 

  insert into public.messages(recipient, sender, cc, bcc, subject, text_body, html_body, status, log)
  values (recipient, sender, cc, bcc, subject, text_body, html_body, 'ready', '[]'::jsonb) returning id into retval;

  return retval;
end;
$$
