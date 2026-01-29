component persistent="true" table="request_log" extends="base" {

    // columns
    property name="ip"      ormtype="string" length="45";
    property name="urlpath" ormtype="string" length="500";
    property name="method"  ormtype="string" length="10";
    property name="agent"   ormtype="string" length="250";
    property name="response" ormtype="string";
    property name="statuscode" ormtype="numeric" precision="3" scale="0";
    property name="delta" ormtype="numeric";
    property name="referer" ormtype="string" length="250";

    // relations
    property name="trainer" fieldtype="many-to-one" fkcolumn="trainerid" cfc="trainer" lazy="true";

    string function getUsername() {
        return getTrainer()?.getUsername() ?: '';
    }

}
