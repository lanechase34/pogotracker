<cfoutput>
<!--- Entries live in services/assets so the modulepreload links always match these URLs --->
<script type="importmap">#getInstance("services.assets").getImportMapJSON()#</script>
</cfoutput>
