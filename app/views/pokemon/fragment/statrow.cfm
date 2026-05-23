<cfoutput>
<div class="stat-bar-item">
    <div class="stat-bar-header">
        <span class="stat-bar-name">#args.stat#</span>
        <span class="stat-bar-value">#args.value#</span>
    </div>
    <div
        class="progress pokemonStatBar"
        role="progressbar"
        aria-label="#args.stat#"
        aria-valuemin="0"
        aria-valuemax="100"
    >
        <div class="progress-bar #args.color#" style="width: #args.percent#%"></div>
    </div>
</div>
</cfoutput>