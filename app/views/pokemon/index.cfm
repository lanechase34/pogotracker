<!--- Idle timeout matches the timeout - the template cache's 30 minute idle eviction would otherwise force a full re-render after quiet periods --->
<cfoutput>
#runEvent(
    event                  = 'pokemon.indexContent',
    private                = true,
    prePostExempt          = true,
    cache                  = true,
    cacheTimeout           = prc.indexContentCacheTimeout,
    cacheLastAccessTimeout = prc.indexContentCacheTimeout
)#
</cfoutput>
