<cfoutput>
<div class="mt-3 d-flex flex-wrap justify-content-center gap-1 px-2">
    <cfloop index="g" item="currGen" array="#prc.generations#">
        <cfif currGen.getRegion() EQ "Unown"><cfcontinue></cfif>
        <button
            class="btn btn-dark pokedex-link #currGen.getRegion()#link"
            data-region="#currGen.getRegion()#"
        >
            #currGen.getRegion()#
        </button>
    </cfloop>
    <button class="btn btn-dark pokedex-link megalink" data-region="mega">Mega</button>
    <button class="btn btn-dark pokedex-link gigalink" data-region="giga">Giga</button>
    <button class="btn btn-dark pokedex-link Unownlink" data-region="Unown">Unown</button>
</div>

<hr>

<div 
    id="pokedexTable" 
    class="" 
    data-trainerid="#encodeForHTMLAttribute(prc.trainerid)#" 
    data-region="#encodeForHTMLAttribute(rc.region)#"
    data-shiny="#encodeForHTMLAttribute(rc.shiny)#"
>
</div>
</cfoutput>