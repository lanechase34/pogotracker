<cfoutput>
<tr>
    <td>
        <div class="d-flex align-items-center my-1">
            <img class="typeIcon" src="#args.move.getTypeImg()#" alt="#args.move.getTypeImgAltText()#" loading="lazy"> 
            <span class="mx-3">#args.move.getName()#</span>
        </div>
    </td>
    <td>
        <span><i class="bi bi-shield-slash me-1"></i>#args.move.getDamage()#</span>
        <span><i class="bi bi-lightning-charge me-1"></i>#args.move.getEnergy()#</span>
    </td>
</tr>
</cfoutput>