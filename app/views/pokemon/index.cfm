<cfoutput>
#runEvent(
    event         = 'pokemon.indexContent',
    private       = true,
    prePostExempt = true,
    cache         = true,
    cacheTimeout  = prc.indexContentCacheTimeout
)#
</cfoutput>
