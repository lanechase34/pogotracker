<cfoutput>
#runEvent(
    event          = 'pokemon.detailContent',
    eventArguments = {ses: rc.ses},
    private        = true,
    prePostExempt  = true,
    cache          = true,
    cacheTimeout   = prc.detailContentCache.timeout,
    cacheSuffix    = prc.detailContentCache.suffix
)#
</cfoutput>
