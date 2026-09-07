// kubejs/server_scripts/list_airtight.js

PlayerEvents.loggedIn(event => {
    const player = event.player
    const level = player.level

    const tag = ResourceLocation.fromNamespaceAndPath('aeronautics', 'airtight')
    
    let count = 0
    Registry.BLOCK.getTagOrEmpty(TagKey.create(Registries.BLOCK, tag)).forEach(holder => {
        player.sendSystemMessage(Component.literal('' + Registry.BLOCK.getKey(holder.value())))
        count++
    })
    
    player.sendSystemMessage(Component.literal('Total airtight blocks: ' + count))
})