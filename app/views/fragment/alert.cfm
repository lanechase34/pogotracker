<cfoutput>
<div id="alertDiv">
<cfif prc.keyExists('alert') && prc.alert.count()>
    <div class="alert alert-#prc.alert.type# <cfif prc.alert.dismissible>alert-dismissible</cfif> mt-#prc.alert?.margin ?: 3#" role="alert">
        <cfif prc.alert.icon.len()>
            <i class="bi #prc.alert.icon# me-2"></i>
        </cfif> 
        #prc.alert.message#
        <cfif prc.alert.dismissible>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </cfif>
    </div>
</cfif>
</div>
</cfoutput>