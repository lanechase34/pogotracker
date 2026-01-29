<cfoutput>
<tr>
    <td>
        <a href="/pokemon/#args.evolution.getPokemon().getSes()#" class="link-dark link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">
            <span class="d-flex justify-content-center">
                <img class="pokemonSearchIcon" src="/includes/images/sprites/#args.evolution.getPokemon().getSprite()##getSetting('imageExtension')#" loading="lazy">
            </span>
            <span class="fs-6 fw-medium">
                #args.evolution.getPokemon().getName()#
            </span>
        </a>
    </td>
    <td>
        <cfif args.evolution.getCost() GTE 0>#args.evolution.getCost()# Candy <br></cfif><cfif args.evolution.getCondition().len()>#ucFirst(args.evolution.getCondition())#</cfif></td>
    <td>
        <a href="/pokemon/#args.evolution.getEvolution().getSes()#" class="link-dark link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">
            <span class="d-flex justify-content-center">
                <img class="pokemonSearchIcon" src="/includes/images/sprites/#args.evolution.getEvolution().getSprite()##getSetting('imageExtension')#" loading="lazy">
            </span>
            <span class="fs-6 fw-medium">
                #args.evolution.getEvolution().getName()#
            </span>
        </a>
    </td>
</tr>
</cfoutput>