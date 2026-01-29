<cfoutput>
<div class="row mt-3 gx-0">
    <ul class="nav nav-tabs justify-content-center">
        <cfloop index="g" item="currGen" array="#prc.generations#">
            <cfif currGen.getRegion() EQ "Unown"><cfcontinue></cfif>
            <li class="nav-item">
                <button 
                    class="nav-link pokedex-link #currGen.getRegion()#link"
                    aria-current="page" 
                    data-region="#currGen.getRegion()#"
                >
                    #currGen.getRegion()#  
                </button>
            </li>
        </cfloop>
        <li class="nav-item">
            <button 
                class="nav-link pokedex-link megalink"
                aria-current="page" 
                data-region="mega"
            >
                Mega
            </button>
        </li>
        <li class="nav-item">
            <button 
                class="nav-link pokedex-link gigalink"
                aria-current="page" 
                data-region="giga"
            >
                Giga
            </button>
        </li>
        <li class="nav-item">
            <button 
                class="nav-link pokedex-link Unownlink"
                aria-current="page" 
                data-region="Unown"
            >
                Unown
            </button>
        </li>
    </ul>
</div>

<div 
    id="pokedexTable" 
    class="" 
    data-trainerid="#prc.trainerid#" 
    data-region="#encodeForHTML(rc.region)#"
    data-shiny="#encodeForHTML(rc.shiny)#"
>

</div>
</cfoutput>