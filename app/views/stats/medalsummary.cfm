<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-award fs-5"></i>Medals
        </div>
        <div class="row row-cols-auto gap-1 d-flex justify-content-center">
            <cfloop index="i" item="currMedal" array="#args.medalProgress#">
                <div class="m-0 p-0">
                    <img
                        id="#currMedal[1].getId()#icon"
                        alt="#currMedal[1].getAltText()#"
                        src="/includes/images/medals/#currMedal[1].getName()##getSetting('imageExtension')#"
                        loading="lazy"
                        class="medalIcon <cfif!isNull(currMedal[2])>#currMedal[2].getCurrentMedal()#Medal</cfif>"
                    />
                </div>
            </cfloop>
        </div>
    </div>
</div>
</cfoutput>
