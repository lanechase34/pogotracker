<cfparam name="args.trainer">
<cfparam name="args.nameClass" default="">
<cfoutput>
<td class="align-middle" style="width: 56px;">
    <img
        class="profileIcon"
        src="#encodeForHTMLAttribute(args.trainer.iconpath)#"
        alt="#encodeForHTMLAttribute(args.trainer.iconalttext)#"
    >
</td>
<td class="align-middle<cfif len(args.nameClass)> #args.nameClass#</cfif>">#encodeForHTML(args.trainer.username)#</td>
</cfoutput>
