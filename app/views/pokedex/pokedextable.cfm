<cfoutput>
<div 
    id="pokedexGrid" 
    data-view="#args.pokedexView#" 
    class="row mt-3 mb-3 align-items-center gx-0"
>
    <cfset registered = 0/>
    <cfset total = 0/>
    <cfloop index="i" item="currEntry" array="#args.pokedex#">
        <cfif 
            (args.pokedexView == "shadowshiny" && currEntry[1].getShadowShiny()) ||
            (args.pokedexView == "shadow" && currEntry[1].getShadow()) ||
            (args.pokedexView == "shiny" && currEntry[1].getShiny()) ||
            (args.pokedexView == "caught" && currEntry[1].getLive())
        >
            <cfset total++/>
            <cfset caught = !isNull(currEntry[2]) && (
                    (args.pokedexView == "shadowshiny" && currEntry[2].getShadowShiny()) ||
                    (args.pokedexView == "shadow" && currEntry[2].getShadow()) ||
                    (args.pokedexView == "shiny" && currEntry[2].getShiny()) || 
                    (args.pokedexView == "hundo" && currEntry[2].getHundo()) || 
                    (args.pokedexView == "caught" && currEntry[2].getCaught())
                )
            />
            <cfif caught><cfset registered++></cfif>
            <div class="col d-flex justify-content-center col-6 col-sm-6 col-md-4 col-lg-3 col-xl-2 col-xxl-1 pokemonCell <cfif caught>caught</cfif> parent"
                data-id="#currEntry[1].getId()#"
                data-number="#currEntry[1].getNumber()#"
                data-name="#currEntry[1].getName()#"
                data-gender="#currEntry[1].getGender()#"
                data-tradable="#currEntry[1].getTradable()#"
                data-caught="#!isNull(currEntry[2]) ? currEntry[2].getCaught() : false#"
                data-shiny="#!isNull(currEntry[2]) ? currEntry[2].getShiny() : false#"
                data-hundo="#!isNull(currEntry[2]) ? currEntry[2].getHundo() : false#" 
                data-shadow="#!isNull(currEntry[2]) ? currEntry[2].getShadow() : false#"
                data-shadowshiny="#!isNull(currEntry[2]) ? currEntry[2].getShadowShiny() : false#"
            >
                <img class="pokemonIcon" <cfif i GT 10>loading="lazy"</cfif> src="/includes/images/<cfif args.shiny>shinysprites<cfelse>sprites</cfif>/#currEntry[1].getSprite()##getSetting('imageExtension')#">
                <cfif args.shadow>
                    <img src="/includes/images/shadow-pokemon#getSetting('imageExtension')#" <cfif i GT 10>loading="lazy"</cfif> class="shadowIcon">
                </cfif>
            </div>
        </cfif>
    </cfloop>   
</div>
<div id="registeredCount" data-registered="#registered#" data-total="#total#"></div>
</cfoutput>