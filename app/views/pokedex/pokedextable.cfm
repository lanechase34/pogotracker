<cfoutput>
<div
    id="pokedexGrid"
    data-view="#encodeForHTMLAttribute(args.pokedexView)#"
    class="row mb-3 align-items-stretch gx-0"
>
    <cfset registered = 0/>
    <cfset total = 0/>
    <cfloop index="i" item="currEntry" array="#args.pokedex#">
        <cfif 
            (args.pokedexView == "costumeshiny" && currEntry[1].getShiny()) ||
            (args.pokedexView == "costume" && currEntry[1].getLive()) ||
            (args.pokedexView == "shadowshiny" && currEntry[1].getShadowShiny()) ||
            (args.pokedexView == "shadow" && currEntry[1].getShadow()) ||
            (args.pokedexView == "shiny" && currEntry[1].getShiny()) ||
            (args.pokedexView == "caught" && currEntry[1].getLive())
        >
            <cfset total++/>
            <cfset caught = !isNull(currEntry[2]) && (
                    (args.pokedexView == "costumeshiny" && currEntry[2].getShiny()) ||
                    (args.pokedexView == "costume" && currEntry[2].getCaught()) ||
                    (args.pokedexView == "shadowshiny" && currEntry[2].getShadowShiny()) ||
                    (args.pokedexView == "shadow" && currEntry[2].getShadow()) ||
                    (args.pokedexView == "shiny" && currEntry[2].getShiny()) || 
                    (args.pokedexView == "hundo" && currEntry[2].getHundo()) || 
                    (args.pokedexView == "caught" && currEntry[2].getCaught())
                )
            />
            <cfif caught><cfset registered++></cfif>
            <div class="col d-flex justify-content-center align-items-center col-6 col-sm-6 col-md-4 col-lg-3 col-xl-2 col-xxl-1 pokemonCell <cfif caught>caught</cfif> parent pokemon-entry"
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
                title="#encodeForHTMLAttribute("#currEntry[1].getName()##currEntry[1].getCostume() ? ' #currEntry[1].getCostumeType()#' : ''#")#"
                role="checkbox"
                aria-checked="#caught ? 'true' : 'false'#"
                aria-label="#encodeForHTMLAttribute("#currEntry[1].getName()##currEntry[1].getCostume() ? ' #currEntry[1].getCostumeType()#' : ''#")#"
                tabindex="0"
            >
                <img 
                    class="pokemonIcon" 
                    <cfif i GT 10>loading="lazy"</cfif> 
                    src="/includes/images/<cfif args.shiny>shinysprites<cfelse>sprites</cfif>/#currEntry[1].getSprite()##getSetting('imageExtension')#"
                >
                <cfif args.shadow>
                    <img src="/includes/images/shadow-pokemon#getSetting('imageExtension')#" <cfif i GT 10>loading="lazy"</cfif> class="shadowIcon">
                </cfif>

                <p class="mt-1 mb-0 small fw-semibold text-center text-capitalize">
                    <cfif currEntry[1].getCostume()>
                        #currEntry[1].getCostumeType()#
                    <cfelse>
                        #currEntry[1].getName()#
                    </cfif>
                </p>

<!---                 
                <cfif currEntry[1].getCostume()>
                    <p class="mt-1 mb-0 small fw-semibold text-center text-capitalize">#currEntry[1].getCostumeType()#</p>
                </cfif> --->
                <span class="dex-number">#currEntry[1].getNumber()#</span>
            </div>
        </cfif>
    </cfloop>
    <cfif total EQ 0>
        <!--- No valid pokemon exists for this view --->
        <div class="col-12 d-flex justify-content-center py-5">
            <div class="d-flex flex-column align-items-center text-center px-5 py-4 rounded border shadow-sm" style="max-width: 500px;">
                <p class="fs-5 fw-medium mb-1 text-muted">No Pokemon found</p>
            </div>
        </div>
    </cfif>
</div>
<div id="registeredCount" data-registered="#registered#" data-total="#total#"></div>
</cfoutput>