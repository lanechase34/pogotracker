<cfoutput>
<div 
    id="currentEvent" 
    data-handler=#lcase(event.getCurrentHandler())# 
    data-action=#lcase(event.getCurrentAction())#
    data-sitekey=#getSetting('reCaptchaSiteKey')#
    data-idletimeout=#getSetting('sessionTimeout')#
    data-userauthenticated="#session?.authenticated ?: false#"
    data-environment="#getSetting('environment')#"
></div>
</cfoutput>