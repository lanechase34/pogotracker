<cfoutput>
<div class="d-flex align-items-center gap-2 mb-2">
    <img
        class="profileIcon flex-shrink-0"
        src="#args.trainer.getIconPath()#"
        alt="#args.trainer.getIconAltText()#"
        loading="lazy"
    >
    <div>
        <div class="text-muted"><i class="bi bi-person-circle me-1 text-muted"></i>#args.trainer.getUsername()#</div>
        <div class="text-muted"><i class="bi bi-calendar3 me-1"></i>#args.date#</div>
    </div>
</div>
</cfoutput>
