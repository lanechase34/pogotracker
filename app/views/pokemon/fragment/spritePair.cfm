<cfparam name="args.sprite">
<cfparam name="args.shiny"     default="false">
<cfparam name="args.normalAlt">
<cfparam name="args.shinyAlt">
<cfparam name="args.iconClass" default="pokemonIcon">
<cfparam name="args.size"      default="148">
<cfparam name="args.lazy"      default="false">
<cfoutput>
<div class="pokemon-sprite-pair">
    <div class="pokemon-sprite-group">
        <img
            class="#args.iconClass#"
            src="/includes/images/sprites/#args.sprite##getSetting('imageExtension')#"
            alt="#args.normalAlt#"
            width="#args.size#"
            height="#args.size#"
            <cfif args.lazy>loading="lazy"</cfif>
        >
        <span class="badge bg-dark text-white sprite-label">Normal</span>
    </div>
    <cfif args.shiny>
    <div class="pokemon-sprite-group">
        <img
            class="#args.iconClass#"
            src="/includes/images/shinysprites/#args.sprite##getSetting('imageExtension')#"
            alt="#args.shinyAlt#"
            width="#args.size#"
            height="#args.size#"
            <cfif args.lazy>loading="lazy"</cfif>
        >
        <span class="badge bg-dark text-white sprite-label">&##x2728; Shiny</span>
    </div>
    </cfif>
</div>
</cfoutput>
