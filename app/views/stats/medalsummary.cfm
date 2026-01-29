<cfoutput>
<div class="card shadow-sm">
    <div class="card-body mx-1">
        <div class="d-flex align-items-center justify-content-center mb-3">
            <h5 class="m-0">
                <i class="bi bi-award me-1"></i>
                Medals
            </h5>
        </div>
        <div class="row row-cols-auto d-flex justify-content-center">
            <cfloop index="i" item="currMedal" array="#args.medalProgress#">
                <cfif fileExists("/includes/images/medals/#currMedal[1].getName()##getSetting('imageExtension')#")>
                    <img 
                        id="#currMedal[1].getId()#icon"
                        alt="#currMedal[1].getAltText()#"
                        src="/includes/images/medals/#currMedal[1].getName()##getSetting('imageExtension')#" 
                        loading="lazy" 
                        class="medalIcon <cfif!isNull(currMedal[2])>#currMedal[2].getCurrentMedal()#Medal</cfif>"
                    />
                </cfif>
            </cfloop>
        </div>
    </div>
</div>
</cfoutput>