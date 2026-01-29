component persistent="true" extends="base" {

    // columns
    property name="nameid" ormtype="string" length="50"; // ucase() with spaces replaced with underscore
    property name="name" ormtype="string" length="50";
    property name="type" ormtype="string" length="10";
    property name="damage" ormtype="numeric" precision="5" scale="2";
    property name="energy" ormtype="numeric" precision="5" scale="2";
    property name="turns"  ormtype="numeric" precision="5" scale="2";
    property name="buffSelf" ormtype="boolean" default="0";
    property name="buffChance" ormtype="numeric" precision="5" scale="4" default="0";
    property name="buffEffect" ormtype="string" length="255"; // attack or defense or both

    // relations
    property name="pokemonmove" fieldtype="one-to-many" cfc="pokemonmove" lazy="true";

    // methods
    string function getDamagePerEnergy() {
        if(getEnergy() == 0) return '--';
        return round(getDamage() / getEnergy(), 2);
    }

    string function getDamagePerTurn() {
        if(!getTurns()) return '--';
        return round(getDamage() / getTurns(), 2);
    }

    string function getEnergyPerTurn() {
        if(!getTurns()) return '--';
        return round(getEnergy() / getTurns(), 2);
    }

    boolean function isFastMove() {
        return getTurns() != 0;
    }

    boolean function isChargeMove() {
        return getTurns() == 0;
    }

    string function getBuff() {
        if(getBuffChance() == 0) return '';
        return '#getBuffChance() * 100#% chance | #getBuffEffect()# #getBuffSelf() == 1 ? 'Self' : 'Opponent'#';
    }

    string function getTypeImg(string type = 'icon') {
        // icon or symbol
        return '/includes/images/type#arguments.type#/#lCase(getType())#.webp';
    }

    string function getTypeImgAltText() {
        return '#ucFirst(getType())# type icon';
    }

}
