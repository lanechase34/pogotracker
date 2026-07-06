component persistent="true" extends="base" {

    // columns
    property name="name" ormtype="string" length="50";

    // relations

    // methods
    struct function getOverride() {
        var override = queryExecute(
            '
            select override
            from overrides
            where id = :overrideId
            ',
            {overrideId: {value: getId(), cfsqltype: 'integer'}}
        ).override;
        return deserializeJSON(override);
    }

    void function setOverride(required struct override) {
        queryExecute(
            '
            update overrides
            set override = cast(:override as jsonb)
            where id = :overrideId
            ',
            {
                override  : {value: serializeJSON(arguments.override), cfsqltype: 'other'},
                overrideId: {value: getId(), cfsqltype: 'integer'}
            }
        );

        setUpdated(now());
    }

}
