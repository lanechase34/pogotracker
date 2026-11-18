<cfoutput>
<div 
    id="customPokedexTable" 
    data-trainerid="#encodeForHTMLAttribute(prc.trainerid)#" 
    data-customid="#encodeForHTMLAttribute(prc.customid)#" 
    data-shiny="#encodeForHTMLAttribute(rc.shiny)#"
>
    #view(view="/views/pokedex/pokedexTable", args=prc.pokedexTableArgs)#
</div>
</cfoutput>