/************************************************************
*
* Message Template System requires:
* SupaScript: https://github.com/burggraf/SupaScript
*
************************************************************/


/************************************************************
*
* Function:  prepare_message
* 
* grab a template from the message_templates table by name,
* send it a block of JSONB data, and have Mustache send you
* a rendered block of HTML
*
************************************************************/
create or replace function prepare_message(template_name text, merge_data jsonb)
returns text as $$

    const Mustache = require('https://unpkg.com/mustache@latest', false);

    const result = sql("select * from message_templates where name = $1 limit 1",[template_name]);
    if (result.length > 0) {
      template = result[0].template;
      return Mustache.render(template, merge_data);
    } else {
      return 'Template not found: ' + template_name;
    }

$$ language plv8;
