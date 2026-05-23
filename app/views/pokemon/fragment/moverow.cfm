<cfoutput>
<tr>
    <td>
        <div class="d-flex align-items-center gap-2 my-1">
            <img
                class="typeIcon flex-shrink-0"
                src="#args.move.getTypeImg()#"
                alt="#args.move.getTypeImgAltText()#"
                loading="lazy"
            >
            <span class="fw-medium">#args.move.getName()#</span>
        </div>
    </td>
    <td class="text-end">
        <div class="d-flex justify-content-end gap-1 flex-wrap">
            <span class="move-stat-badge">
                <i class="bi bi-shield-slash text-danger"></i>#args.move.getDamage()#
            </span>
            <span class="move-stat-badge">
                <i class="bi bi-lightning-charge text-warning"></i>#args.move.getEnergy()#
            </span>
        </div>
    </td>
</tr>
</cfoutput>