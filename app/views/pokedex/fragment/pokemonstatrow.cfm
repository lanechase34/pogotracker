<cfoutput>
<tr>
    <td scope="col" class="col-4 text-center">
        #args.stat#
    </td>
    <td scope="col" class="col-8">
        <div class="mx-2 my-1">
            #args.value#
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
    </td>
</tr>
</cfoutput>