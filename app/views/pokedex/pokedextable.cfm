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
            (args.pokedexView == "costumeshiny" && currEntry.shiny) ||
            (args.pokedexView == "costume" && currEntry.live) ||
            (args.pokedexView == "shadowshiny" && currEntry.shadowshiny) ||
            (args.pokedexView == "shadow" && currEntry.shadow) ||
            (args.pokedexView == "shiny" && currEntry.shiny) ||
            (args.pokedexView == "caught" && currEntry.live)
        >
            <cfset total++/>
            <cfset caught = currEntry.registered && (
                    (args.pokedexView == "costumeshiny" && currEntry.dex_shiny) ||
                    (args.pokedexView == "costume" && currEntry.dex_caught) ||
                    (args.pokedexView == "shadowshiny" && currEntry.dex_shadowshiny) ||
                    (args.pokedexView == "shadow" && currEntry.dex_shadow) ||
                    (args.pokedexView == "shiny" && currEntry.dex_shiny) || 
                    (args.pokedexView == "hundo" && currEntry.dex_hundo) || 
                    (args.pokedexView == "caught" && currEntry.dex_caught)
                )
            />
            <cfif caught><cfset registered++></cfif>
            <div class="col d-flex justify-content-center align-items-center col-6 col-sm-6 col-md-4 col-lg-3 col-xl-2 col-xxl-1 pokemonCell <cfif caught>caught</cfif><cfif args.shadow> shadowCell</cfif> parent pokemon-entry"
                data-id="#currEntry.id#"
                data-number="#currEntry.number#"
                data-name="#currEntry.name#"
                data-form="#booleanFormat(currEntry.form)#"
                data-caught="#booleanFormat(currEntry.dex_caught)#"
                data-shiny="#booleanFormat(currEntry.dex_shiny)#"
                data-hundo="#booleanFormat(currEntry.dex_hundo)#"
                data-shadow="#booleanFormat(currEntry.dex_shadow)#"
                data-shadowshiny="#booleanFormat(currEntry.dex_shadowshiny)#"
                title="#encodeForHTMLAttribute("#currEntry.name##currEntry.costume ? ' #currEntry.costumetype#' : ''#")#"
                role="checkbox"
                aria-checked="#caught ? 'true' : 'false'#"
                aria-label="#encodeForHTMLAttribute("#currEntry.name##currEntry.costume ? ' #currEntry.costumetype#' : ''#")#"
                tabindex="0"
            >
                <img 
                    class="pokemonIcon" 
                    width="#getSetting('pokemonIconSize')#"
                    height="#getSetting('pokemonIconSize')#"
                    decoding="async"
                    <cfif i GT 10>loading="lazy"</cfif> 
                    src="/includes/images/<cfif args.shiny>shinysprites<cfelse>sprites</cfif>/#currEntry.sprite##getSetting('imageExtension')#"
                >

                <p class="mt-1 mb-0 small fw-semibold text-center text-capitalize">
                    <cfif currEntry.costume>
                        <span class="d-block fw-normal text-muted lh-1 costume-base-name">#currEntry.name#</span>
                        #currEntry.costumetype#
                    <cfelse>
                        #currEntry.name#
                    </cfif>
                </p>

                <span class="dex-number">#currEntry.number#</span>
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