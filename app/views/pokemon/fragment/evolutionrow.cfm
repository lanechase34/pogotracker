<cfoutput>
<tr>
    <td>
        <a href="/pokemon/#args.evolution.getPokemon().getSes()#" class="link-dark link-underline-opacity-0 link-underline-opacity-100-hover">
            <span class="d-flex justify-content-center">
                <img
                    class="pokemonSearchIcon"
                    src="/includes/images/sprites/#args.evolution.getPokemon().getSprite()##getSetting('imageExtension')#"
                    loading="lazy"
                    alt="#args.evolution.getPokemon().getName()# Sprite"
                >
            </span>
            <span class="d-block text-center small fw-semibold mt-1">
                #args.evolution.getPokemon().getName()#
            </span>
        </a>
    </td>
    <td>
        <div class="evo-req">
            <cfif args.evolution.getCost() GT 0>
                <span class="evo-candy">#args.evolution.getCost()# Candy</span>
            </cfif>
            <cfif args.evolution.getCondition().len()>
                <span class="evo-condition">#ucFirst(args.evolution.getCondition())#</span>
            </cfif>
        </div>
    </td>
    <td>
        <a href="/pokemon/#args.evolution.getEvolution().getSes()#" class="link-dark link-underline-opacity-0 link-underline-opacity-100-hover">
            <span class="d-flex justify-content-center">
                <img
                    class="pokemonSearchIcon"
                    src="/includes/images/sprites/#args.evolution.getEvolution().getSprite()##getSetting('imageExtension')#"
                    loading="lazy"
                    alt="#args.evolution.getEvolution().getName()# Sprite"
                >
            </span>
            <span class="d-block text-center small fw-semibold mt-1">
                #args.evolution.getEvolution().getName()#
            </span>
        </a>
    </td>
</tr>
</cfoutput>