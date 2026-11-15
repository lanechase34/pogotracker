<cfoutput>
<div 
    id="costumePokedexTable" 
    class="mt-3" 
    data-trainerid="#encodeForHTMLAttribute(prc.trainerid)#" 
    data-shiny="#encodeForHTMLAttribute(rc.shiny)#"
>
    #view(view="/views/pokedex/pokedexTable", args=prc.pokedexTableArgs)#
</div>  
</cfoutput>