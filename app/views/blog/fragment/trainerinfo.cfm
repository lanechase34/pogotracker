<cfoutput>
<div class="d-flex align-items-center mb-1">
    <img 
        class="blogIcon me-2" 
        src="#args.trainer.getIconPath()#"
        alt="#args.trainer.getIconAltText()#"
        loading="lazy"
    >
    <div class="inlineBlock">
        <div class="mb-1 text-body-secondary" >
            <i class="bi bi-person-circle me-2"></i>#args.trainer.getUsername()#
        </div>
        <div class="text-body-secondary" class="inlineBlock">
            <i class="bi bi-calendar3 me-2"></i>#args.date#
        </div>
    </div>
</div>
</cfoutput>