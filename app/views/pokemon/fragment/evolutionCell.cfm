<cfparam name="args.pokemon">
<cfoutput>
<a href="/pokemon/#args.pokemon.ses#" class="link-dark link-underline-opacity-0 link-underline-opacity-100-hover">
    <span class="d-flex justify-content-center">
        <img
            class="pokemonSearchIcon"
            src="/includes/images/sprites/#args.pokemon.sprite##getSetting('imageExtension')#"
            loading="lazy"
            alt="#args.pokemon.fullname# Sprite"
        >
    </span>
    <span class="d-block text-center small fw-semibold mt-1">
        #args.pokemon.fullname#
    </span>
</a>
</cfoutput>
