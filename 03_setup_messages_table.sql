/************************************************************
*  Create the messages table
************************************************************/
CREATE TABLE if not exists public.messages
(
    id uuid primary key default gen_random_uuid(),
    recipient text,
    sender text,
    cc text,
    bcc text,
    subject text,
    text_body text,
    html_body text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status text,
    deliveryresult jsonb,
    deliverysignature jsonb,
    log jsonb
);
ALTER TABLE public.messages OWNER TO postgres;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
-- Turn off all access to the messages table by default
CREATE POLICY "messages delete policy" ON public.messages FOR DELETE USING (false);
CREATE POLICY "messages insert policy" ON public.messages FOR INSERT WITH CHECK (false);
CREATE POLICY "messages select policy" ON public.messages FOR SELECT USING (false);
CREATE POLICY "messages update policy" ON public.messages FOR UPDATE USING (false) WITH CHECK (false);

