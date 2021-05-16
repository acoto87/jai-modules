isUnit :: inline (entity: *Entity) -> bool {
    return entity.type == EntityType.Unit;
}

hasUnitFlag :: (entity: *Entity, flag: UnitFlags) -> bool {
    if (!isUnit(entity)) return false;
    unit := getComponent(entity, UnitComponent);
    return (unit.unitFlags & flag) == flag;
}
