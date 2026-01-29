<cfoutput>
<div class="row">
    <h5 class="card-title text-center mb-3">#args.header#</h5>
    <cfloop index="i" from="1" to="#args.loop#">
        <div class="col-12 col-xxl-6 col-xxxl-4 d-flex align-items-center justify-content-center my-1">
            <div class="card d-flex flex-row align-items-center">
                <cfif i LTE args.tradePlan.trainerOnly.len()>
                    <img class="pokemonIcon" src="/includes/images/<cfif args.shiny>shinysprites<cfelse>sprites</cfif>/#args.tradePlan.trainerOnly[i].getSprite()##getSetting('imageExtension')#">
                <cfelse>
                    <img class="pokemonIcon" src="/includes/images/<cfif args.shiny>shinysprites<cfelse>sprites</cfif>/0#getSetting('imageExtension')#">
                </cfif>
                <i class="bi bi-arrow-left-right tradeIcon mx-1"></i>
                <cfif i LTE args.tradePlan.friendOnly.len()>
                    <img class="pokemonIcon" src="/includes/images/<cfif args.shiny>shinysprites<cfelse>sprites</cfif>/#args.tradePlan.friendOnly[i].getSprite()##getSetting('imageExtension')#">
                <cfelse>
                    <img class="pokemonIcon" src="/includes/images/<cfif args.shiny>shinysprites<cfelse>sprites</cfif>/0#getSetting('imageExtension')#">
                </cfif>
            </div>
        </div>
    </cfloop>
</div>
</cfoutput>