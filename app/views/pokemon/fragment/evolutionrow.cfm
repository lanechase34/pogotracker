<cfoutput>
<tr>
    <td>
        #view(view = "/views/pokemon/fragment/evolutionCell", args = {pokemon: args.evolution.pokemon})#
    </td>
    <td>
        <div class="evo-req">
            <cfif args.evolution.cost GT 0>
                <span class="evo-candy">#args.evolution.cost# Candy</span>
            </cfif>
            <cfif args.evolution.condition.len()>
                <span class="evo-condition">#ucFirst(args.evolution.condition)#</span>
            </cfif>
        </div>
    </td>
    <td>
        #view(view = "/views/pokemon/fragment/evolutionCell", args = {pokemon: args.evolution.evolution})#
    </td>
</tr>
</cfoutput>