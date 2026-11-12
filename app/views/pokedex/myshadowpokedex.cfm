<cfoutput>
<div 
    id="shadowPokedexTable" 
    class="mt-3" 
    data-trainerid="#encodeForHTMLAttribute(prc.trainerid)#" 
    data-shadow="true"
    data-shiny="#encodeForHTMLAttribute(rc.shiny)#"
>
    #view(view="/views/pokedex/pokedextable", args=prc.pokedexTableArgs)#
</div>  
</cfoutput>