<!--- Idle timeout matches the timeout, like the index - the template cache's 30 minute idle eviction would otherwise re-render quiet pokemon --->
<cfoutput>
#runEvent(
    event                  = 'pokemon.detailContent',
    eventArguments         = {ses: rc.ses},
    private                = true,
    prePostExempt          = true,
    cache                  = true,
    cacheTimeout           = prc.detailContentCache.timeout,
    cacheLastAccessTimeout = prc.detailContentCache.timeout,
    cacheSuffix            = prc.detailContentCache.suffix
)#
</cfoutput>
