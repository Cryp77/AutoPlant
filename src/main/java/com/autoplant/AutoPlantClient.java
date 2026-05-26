package com.autoplant;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.block.Blocks;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import net.minecraft.item.Item;
import net.minecraft.item.Items;
import net.minecraft.text.Text;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.Direction;
import org.lwjgl.glfw.GLFW;

import java.util.Set;

public class AutoPlantClient implements ClientModInitializer {

    private static final Set<Item> SEEDS = Set.of(
            Items.WHEAT_SEEDS,
            Items.CARROT,
            Items.POTATO,
            Items.BEETROOT_SEEDS,
            Items.MELON_SEEDS,
            Items.PUMPKIN_SEEDS
    );

    private static final long COOLDOWN_MS = 250L;

    private KeyBinding toggleKey;
    private boolean enabled = false;
    private long lastPlantTime = 0L;

    @Override
    public void onInitializeClient() {
        toggleKey = KeyBindingHelper.registerKeyBinding(new KeyBinding(
                "key.autoplant.toggle",
                InputUtil.Type.KEYSYM,
                GLFW.GLFW_KEY_G,
                "category.autoplant"
        ));

        ClientTickEvents.END_CLIENT_TICK.register(this::onEndTick);
    }

    private void onEndTick(MinecraftClient client) {
        while (toggleKey.wasPressed()) {
            enabled = !enabled;
            if (client.player != null) {
                client.player.sendMessage(
                        Text.literal("AutoPlant: " + (enabled ? "ON" : "OFF")),
                        true
                );
            }
        }

        if (!enabled
                || client.player == null
                || client.interactionManager == null
                || client.world == null
                || client.currentScreen != null) {
            return;
        }

        long now = System.currentTimeMillis();
        if (now - lastPlantTime < COOLDOWN_MS) {
            return;
        }

        var stack = client.player.getMainHandStack();
        if (!SEEDS.contains(stack.getItem())) {
            return;
        }

        var hitResult = client.crosshairTarget;
        if (hitResult == null || hitResult.getType() != HitResult.Type.BLOCK) {
            return;
        }

        var blockHit = (BlockHitResult) hitResult;
        if (blockHit.getSide() != Direction.UP) {
            return;
        }

        var blockState = client.world.getBlockState(blockHit.getBlockPos());
        if (!blockState.isOf(Blocks.FARMLAND)) {
            return;
        }

        // Skip if something is already planted above the farmland
        if (!client.world.getBlockState(blockHit.getBlockPos().up()).isAir()) {
            return;
        }

        client.interactionManager.interactBlock(client.player, Hand.MAIN_HAND, blockHit);
        lastPlantTime = now;
    }
}
