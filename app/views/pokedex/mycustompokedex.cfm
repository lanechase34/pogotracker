<cfoutput>
<div 
    id="customPokedexTable" 
    class="mt-xl-3" 
    data-trainerid="#encodeForHTMLAttribute(prc.trainerid)#" 
    data-customid="#encodeForHTMLAttribute(prc.customid)#" 
    data-shiny="#encodeForHTMLAttribute(rc.shiny)#"
>
    #view(view="/views/pokedex/pokedextable", args=prc.pokedexTableArgs)#
</div>
</cfoutput>