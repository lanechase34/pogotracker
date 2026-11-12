component persistent="true" extends="base" {

    // columns
    property name="name" ormtype="string" length="50";

    // relations

    // methods
    struct function getOverride() {
        var override = queryExecute(
            "
            select override
            from overrides
            where id = :overrideId
            ",
            {overrideId: {value: getId(), cfsqltype: "integer"}}
        ).override;
        return deserializeJSON(override);
    }

}
