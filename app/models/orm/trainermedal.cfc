component persistent="true" extends="base" {

    // columns
    property name="current" ormtype="integer"; // tracks the current progress of the medal for trainer

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";
    property name="medal"   fieldtype="many-to-one" cfc="medal"   fkcolumn="medalid"   lazy="true";

    // functions

    // based on inputted count, determine whether this medal is default, bronze, silver, gold, or platinum
    string function getCurrentMedal() {
        var current = getCurrent();
        var medal   = getMedal();
        if(current >= medal.getPlatinum()) {
            return 'platinum';
        }
        else if(current >= medal.getGold()) {
            return 'gold';
        }
        else if(current >= medal.getSilver()) {
            return 'silver';
        }
        else if(current >= medal.getBronze()) {
            return 'bronze';
        }
        return '';
    }

}
