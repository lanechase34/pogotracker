component {

    void function preInsert(required component entity) {
        if(isNull(arguments.entity.getCreated())) {
            arguments.entity.setCreated(now());
        }
        arguments.entity.setUpdated(now());
    }

    void function preUpdate(required component entity, struct oldData) {
        arguments.entity.setUpdated(now());
    }

}
