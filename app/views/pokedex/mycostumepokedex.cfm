<cfoutput>
<div 
    id="costumePokedexTable" 
    class="mt-3" 
    data-trainerid="#encodeForHTMLAttribute(prc.trainerid)#" 
    data-costume="true"
    data-shiny="#encodeForHTMLAttribute(rc.shiny)#"
>
    #view(view="/views/pokedex/pokedextable", args=prc.pokedexTableArgs)#
</div>  
</cfoutput>