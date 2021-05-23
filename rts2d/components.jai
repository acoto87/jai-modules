ComponentType :: enum {
    Transform;
    Sprite;
    Unit;
    Animations;
    StateMachine;
    Road;
    Wall;
    Ruin;
    Forest;
    Projectile;
    Spell;
    UI;
    Text;
    Rect;
    Button;
    Cursor;
    Audio;
}

Component :: struct {
    enabled: bool;
    type: ComponentType;
    index: s32;
    entityId: EntityId;
}

TransformComponent :: struct {
    using base: Component;
    base.type = ComponentType.Transform;

    position: Vec2;
    rotation: Vec2;
    scale: Vec2;
}

SpriteComponent :: struct {
    using base: Component;
    base.type = ComponentType.Sprite;

    resourceIndex: s32;
    frameIndex: s32;
    sprite: Sprite;
}

UnitFlags :: enum_flags u8 {
    Melee;
    Range;
    Magic;
    Mounted;
    Siege;
    Ship;
}

UnitDirection :: enum {
    North;
    NorthEast;
    East;
    SouthEast;
    South;
    SouthWest;
    West;
    NorthWest;
}

UnitComponent :: struct {
    using base: Component;
    base.type = ComponentType.Unit;

    flags: UnitFlags;
    direction: UnitDirection;

    // position in tiles
    tilex, tiley: s32;
    // size in tiles
    sizex, sizey: s32;

    // index of the player this unit belongs to
    player: u8;

    // resource that the unit can carry, like
    // peasants, peons, goldmines and trees
    resourceKind: ResourceKind;
    amount: s32;

    // indicate if the unit is building something
    isBuilding: bool;
    buildPercent: f32;

    // hit points, magic and armor
    hp, maxhp: s32;
    mana, maxMana: s32;
    armor: s32;
    range: s32;
    minDamage: s32;
    rndDamage: s32;
    decay: s32;
    invisible: bool;
    invulnerable: bool;
    hasBeenSeen: bool;

    // index of the array of speeds of the unit
    speed: s32;

    // the current animation of the unit referencing the animations component
    animationIndex: s32;

    // time remainder (in seconds) until mana is affected
    manaTime: f32;
    // time remainder (in seconds) until the unit invisiblity ceases
    invisibilityTime: f32;
    // time remainder (in seconds) until the unit invulnerability ceases
    invulnerabilityTime: f32;
}

AnimationsComponent :: struct {
    using base: Component;
    base.type = ComponentType.Animations;

    animations: List(*SpriteAnimation);
}

StateMachineComponent :: struct {
    using base: Component;
    base.type = ComponentType.StateMachine;

    currentState: *State;
    nextState: *State;
    leaveState: bool;
    enterState: bool;
}

UIComponent :: struct {
    using base: Component;
    base.type = ComponentType.UI;

    name: string;
}

TextAlignment :: enum {
    Left;
    Center;
    Right;
    Top;
    Middle;
    Bottom;
}

TextWrapping :: enum {
    None;
    Char;
}

TextTrimming :: enum {
    None;
    Spaces;
    All;
}

TextComponent :: struct {
    using base: Component;
    base.type = ComponentType.Text;

    text: string;
    fontIndex: s32;
    fontSize: f32;
    lineHeight: f32;
    fontColor: Color;
    highlightColor: Color;
    highlightIndex: s32;
    highlightCount: s32;
    boundings: Vec2;
    horizontalAlign: TextAlignment;
    verticalAlign: TextAlignment;
    lineAlign: TextAlignment;
    wrapping: TextWrapping;
    trimming: TextTrimming;
    multiline: bool;
}

RectComponent :: struct {
    using base: Component;
    base.type = ComponentType.Rect;

    size: Vec2;
    color: Color;
}

ClickHandler :: #type (entity: *Entity);

ButtonComponent :: struct {
    using base: Component;
    base.type = ComponentType.Button;

    interactive: bool;
    hot: bool;
    active: bool;
    hotKey: Keys;
    highlightIndex: s32;
    highlightCount: s32;
    tooltip: string;
    backgroundNormalSprite: Sprite;
    backgroundPressedSprite: Sprite;
    clickHandler: ClickHandler;
}

AudioType :: enum {
    Midi;
    Wave;
}

AudioComponent :: struct {
    using base: Component;
    base.type = ComponentType.Audio;

    audioType: AudioType;
    resourceIndex: s32;
    loop: bool;
    playbackTime: f32;
    sampleIndex: s32;
    // firstMessage: *tml_message;
    // currentMessage: *tml_message;
}

CursorType :: u16;

CursorComponent :: struct {
    using base: Component;
    base.type = ComponentType.Cursor;

    cursorType: CursorType;
    hot: Vec2;
}

ComponentsManager :: struct {
    transforms: StableList(TransformComponent);
    sprites: StableList(SpriteComponent);
    units: StableList(UnitComponent);
    animations: StableList(AnimationsComponent);
    stateMachines: StableList(StateMachineComponent);
    uis: StableList(UIComponent);
    texts: StableList(TextComponent);
    rects: StableList(RectComponent);
    buttons: StableList(ButtonComponent);
    cursors: StableList(CursorComponent);
    audios: StableList(AudioComponent);
}

initComponentsManager :: (componentsManager: *ComponentsManager) {
    init(*componentsManager.transforms);
    init(*componentsManager.sprites);
    init(*componentsManager.units);
    init(*componentsManager.animations);
    init(*componentsManager.stateMachines);
    init(*componentsManager.uis);
    init(*componentsManager.texts);
    init(*componentsManager.rects);
    init(*componentsManager.buttons);
    init(*componentsManager.cursors);
    init(*componentsManager.audios);
}

freeComponentsManager :: (componentsManager: *ComponentsManager) {
    uninit(*componentsManager.transforms);
    uninit(*componentsManager.sprites);
    uninit(*componentsManager.units);
    uninit(*componentsManager.animations);
    uninit(*componentsManager.stateMachines);
    uninit(*componentsManager.uis);
    uninit(*componentsManager.texts);
    uninit(*componentsManager.rects);
    uninit(*componentsManager.buttons);
    uninit(*componentsManager.cursors);
    uninit(*componentsManager.audios);
}

getComponent :: (entity: *Entity, type: ComponentType) -> *Component {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);
    assert(entity != null);

    manager := ctx.scene.componentsManager;
    index := entity.components[type];
    if (index < 0) {
        return null;
    }

    if (type == ComponentType.Transform)        return ref(*manager.transforms, index);
    else if (type == ComponentType.Sprite)       return ref(*manager.sprites, index);
    else if (type == ComponentType.Unit)         return ref(*manager.units, index);
    else if (type == ComponentType.Animations)   return ref(*manager.animations, index);
    else if (type == ComponentType.StateMachine) return ref(*manager.stateMachines, index);
    else if (type == ComponentType.UI)           return ref(*manager.uis, index);
    else if (type == ComponentType.Text)         return ref(*manager.texts, index);
    else if (type == ComponentType.Rect)         return ref(*manager.rects, index);
    else if (type == ComponentType.Button)       return ref(*manager.buttons, index);
    else if (type == ComponentType.Cursor)       return ref(*manager.cursors, index);
    else if (type == ComponentType.Audio)        return ref(*manager.audios, index);
    else {
        logError("Unkown component of type: %\n", type);
        return null;
    }
}

getComponent :: inline (entity: *Entity, $type: Type) -> *type {
    componentType := getComponentTypeFromType(type);
    return cast(*type) getComponent(entity, componentType);
}

hasComponent :: inline (entity: *Entity, type: ComponentType) -> bool {
    assert(entity != null);
    return entity.components[type] >= 0;
}

hasComponent :: inline (entity: *Entity, $type: Type) -> bool {
    assert(entity != null);

    componentType := getComponentTypeFromType(type);
    return entity.components[componentType] >= 0;
}

createComponent :: (type: ComponentType) -> *Component {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    index: s64 = -1;
    component: *Component = null;

    manager := *ctx.scene.componentsManager;

    if (type == ComponentType.Transform) {
        index, component = addNew(*manager.transforms);
    } else if (type == ComponentType.Sprite) {
        index, component = addNew(*manager.sprites);
    } else if (type == ComponentType.Unit) {
        index, component = addNew(*manager.units);
    } else if (type == ComponentType.Animations) {
        index, component = addNew(*manager.animations);
    } else if (type == ComponentType.StateMachine) {
        index, component = addNew(*manager.stateMachines);
    } else if (type == ComponentType.UI) {
        index, component = addNew(*manager.uis);
    } else if (type == ComponentType.Text) {
        index, component = addNew(*manager.texts);
    } else if (type == ComponentType.Rect) {
        index, component = addNew(*manager.rects);
    } else if (type == ComponentType.Button) {
        index, component = addNew(*manager.buttons);
    } else if (type == ComponentType.Cursor) {
        index, component = addNew(*manager.cursors);
    } else if (type == ComponentType.Audio) {
        index, component = addNew(*manager.audios);
    } else {
        logError("Unkown component type: %\n", type);
    }

    if (component != null) {
        component.enabled = true;
        component.type = type;
        component.index = cast(s32) index;
    }

    return component;
}

createComponent :: inline ($type: Type) -> *type {
    componentType := getComponentTypeFromType(type);
    return cast(*type) createComponent(componentType);
}

addComponent :: inline (entity: *Entity, component: *Component) {
    assert(entity != null);

    component.entityId = entity.id;
    entity.components[component.type] = component.index;
}

removeComponent :: (entity: *Entity, type: ComponentType) {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);
    assert(entity != null);

    manager := *ctx.scene.componentsManager;
    index := entity.components[type];
    if (index < 0) {
        return;
    }

    if (type == ComponentType.Transform)         removeAt(*manager.transforms, index);
    else if (type == ComponentType.Sprite)       removeAt(*manager.sprites, index);
    else if (type == ComponentType.Unit)         removeAt(*manager.units, index);
    else if (type == ComponentType.Animations)   removeAt(*manager.animations, index);
    else if (type == ComponentType.StateMachine) removeAt(*manager.stateMachines, index);
    else if (type == ComponentType.UI)           removeAt(*manager.uis, index);
    else if (type == ComponentType.Text)         removeAt(*manager.texts, index);
    else if (type == ComponentType.Rect)         removeAt(*manager.rects, index);
    else if (type == ComponentType.Button)       removeAt(*manager.buttons, index);
    else if (type == ComponentType.Cursor)       removeAt(*manager.cursors, index);
    else if (type == ComponentType.Audio)        removeAt(*manager.audios, index);

    entity.components[type] = -1;
}

removeComponent :: inline (entity: *Entity, $type: Type) {
    componentType := getComponentTypeFromType(type);
    return cast(*type) removeComponent(entity, componentType);
}

setComponentStatus :: inline (entity: *Entity, componentType: ComponentType, enabled: bool) {
    component := getComponent(entity, componentType);
    assert(component != null);

    component.enabled = enabled;
}

setComponentStatus :: inline (entity: *Entity, $componentType: Type, enabled: bool) {
    component := getComponent(entity, componentType);
    assert(component != null);

    component.enabled = enabled;
}

addTransformComponent :: (entity: *Entity, position: Vec2, scale: Vec2 = VEC2_ONE, rotation: Vec2 = VEC2_ZERO) -> *TransformComponent {
    component := createComponent(TransformComponent);
    component.position = position;
    component.rotation = rotation;
    component.scale = scale;
    addComponent(entity, component);
    return component;
}

addSpriteComponent :: (entity: *Entity, sprite: Sprite) -> *SpriteComponent {
    component := createComponent(SpriteComponent);
    component.resourceIndex = 0;
    component.frameIndex = 0;
    component.sprite = sprite;
    addComponent(entity, component);
    return component;
}

addAnimationsComponent :: (entity: *Entity) -> *AnimationsComponent {
    component := createComponent(AnimationsComponent);
    init(*component.animations);
    addComponent(entity, component);
    return component;
}

addUIComponent :: (entity: *Entity, name: string) -> *UIComponent {
    component := createComponent(UIComponent);
    component.name = name;
    addComponent(entity, component);
    return component;
}

addTextComponent :: (entity: *Entity, fontIndex: s32, fontSize: f32, text: string) -> *TextComponent {
    component := createComponent(TextComponent);
    component.fontIndex = fontIndex;
    component.fontSize = fontSize;
    component.lineHeight = 0;
    component.fontColor = FONT_NORMAL_COLOR;
    component.highlightColor = FONT_HIGHLIGHT_COLOR;
    component.highlightIndex = NO_HIGHLIGHT;
    component.highlightCount = 0;
    component.boundings = VEC2_ZERO;
    component.horizontalAlign = TextAlignment.Left;
    component.verticalAlign = TextAlignment.Top;
    component.lineAlign = TextAlignment.Left;
    component.wrapping = TextWrapping.None;
    component.multiline = false;
    component.text = allocString(text);
    addComponent(entity, component);
    return component;
}

addRectComponent :: (entity: *Entity, size: Vec2, color: Color) -> *RectComponent {
    component := createComponent(RectComponent);
    component.size = size;
    component.color = color;
    addComponent(entity, component);
    return component;
}

addCursorComponent :: (entity: *Entity, cursorType: CursorType, hot: Vec2) -> *CursorComponent {
    component := createComponent(CursorComponent);
    component.cursorType = cursorType;
    component.hot = hot;
    addComponent(entity, component);
    return component;
}

addButtonComponent :: (entity: *Entity, normalSprite: Sprite, pressedSprite: Sprite) -> *ButtonComponent {
    component := createComponent(ButtonComponent);
    component.interactive = true;
    component.hot = false;
    component.active = false;
    component.hotKey = Keys.None;
    component.highlightIndex = NO_HIGHLIGHT;
    component.backgroundNormalSprite = normalSprite;
    component.backgroundPressedSprite = pressedSprite;
    component.clickHandler = null;
    addComponent(entity, component);
    return component;
}

#scope_file

getComponentTypeFromType :: ($componentType: Type) -> ComponentType {
    #if (componentType == TransformComponent)         return ComponentType.Transform;
    else if (componentType ==  SpriteComponent)       return ComponentType.Sprite;
    else if (componentType ==  UnitComponent)         return ComponentType.Unit;
    else if (componentType ==  AnimationsComponent)   return ComponentType.Animations;
    else if (componentType ==  StateMachineComponent) return ComponentType.StateMachine;
    else if (componentType ==  UIComponent)           return ComponentType.UI;
    else if (componentType ==  TextComponent)         return ComponentType.Text;
    else if (componentType ==  RectComponent)         return ComponentType.Rect;
    else if (componentType ==  ButtonComponent)       return ComponentType.Button;
    else if (componentType ==  CursorComponent)       return ComponentType.Cursor;
    else if (componentType ==  AudioComponent)        return ComponentType.Audio;
    else {
        logError("Unkown component of type: %. Defaulting to Transform.\n", componentType);
        return ComponentType.Transform;
    }
}
