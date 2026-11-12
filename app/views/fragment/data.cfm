<cfoutput>
<div 
    id="currentEvent" 
    data-handler=#lcase(event.getCurrentHandler())# 
    data-action=#lcase(event.getCurrentAction())#
    data-sitekey=#getSetting('reCaptchaSiteKey')#
    data-idletimeout=#getSetting('sessionTimeout')#
    data-userauthenticated="#prc.keyExists("oCurrentUser")#"
    data-environment="#getSetting('environment')#"
    data-port="#getSetting('environment') != 'production' ? '#getSetting('httpPort')#' : ''#"
></div>
</cfoutput>