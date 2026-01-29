<cfoutput>
<div id="alertDiv">
<cfif request.keyExists('alert') && request.alert.count()>
    <div class="alert alert-#request.alert.type# <cfif request.alert.dismissible>alert-dismissible</cfif> mt-3" role="alert">
        <cfif request.alert.icon.len()>
            <i class="bi #request.alert.icon# me-2"></i>
        </cfif> 
        #request.alert.message#
        <cfif request.alert.dismissible>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </cfif>
    </div>
</cfif>
</div>
</cfoutput>