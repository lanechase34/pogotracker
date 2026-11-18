<cfoutput>
<div 
    id="costumePokedexTable" 
    data-trainerid="#encodeForHTMLAttribute(prc.trainerid)#" 
    data-shiny="#encodeForHTMLAttribute(rc.shiny)#"
>
    #view(view="/views/pokedex/pokedexTable", args=prc.pokedexTableArgs)#
</div>  
</cfoutput>