import React, { useEffect, useMemo, useState } from 'react';
import CraftingPanel from './CraftingPanel';
import { fetchNui } from '../utils/fetchNui';

type Recipe = {
  id: string;
  name: string;
  description: string;
  ingredients: { name: string; count: number }[];
  craftTime: number;
  resultCount: number;
  requiredLevel: number;
};

type InventoryItem = {
  name: string;
  count: number;
};

export default function CraftingApp() {
  const [visible, setVisible] = useState(false);
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [inventory, setInventory] = useState<Record<string, number>>({});
  const [playerLevel, setPlayerLevel] = useState(0);
  const [crafting, setCrafting] = useState<{ id: string; remaining: number } | null>(null);

  // Listen for NUI messages from client.lua
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data;

      if (action === 'openCrafting') {
        setRecipes(data.recipes || []);
        setInventory(data.inventory || {});
        setPlayerLevel(data.playerLevel || 0);
        setSelectedId(data.recipes?.[0]?.id || null);
        setVisible(true);
      } else if (action === 'closeCrafting') {
        setVisible(false);
      } else if (action === 'updateInventory') {
        setInventory(data.inventory || {});
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // ESC key to close
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && visible) {
        handleClose();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible]);

  // Crafting timer
  useEffect(() => {
    if (!crafting) return;
    const timer = setInterval(() => {
      setCrafting((c) => {
        if (!c) return null;
        if (c.remaining <= 1) return null;
        return { ...c, remaining: c.remaining - 1 };
      });
    }, 1000);
    return () => clearInterval(timer);
  }, [crafting]);

  const selected = useMemo(() => recipes.find((r) => r.id === selectedId) || recipes[0], [recipes, selectedId]);

  function canCraft(recipe: Recipe) {
    if (!recipe) return false;
    return recipe.ingredients.every((ing) => (inventory[ing.name] || 0) >= ing.count) && !crafting;
  }

  function handleClose() {
    setVisible(false);
    fetchNui('closeUI', {});
  }

  function onCraft(id: string) {
    const recipe = recipes.find((r) => r.id === id);
    if (!recipe) return;
    if (!canCraft(recipe)) return;

    // Optimistically update UI
    setInventory((inv) => {
      const next = { ...inv };
      recipe.ingredients.forEach((ing) => {
        next[ing.name] = (next[ing.name] || 0) - ing.count;
      });
      return next;
    });

    setCrafting({ id: recipe.id, remaining: recipe.craftTime });

    // Send craft request to server
    fetchNui('craftItem', { recipeId: id, amount: 1 });

    // Simulate completion
    setTimeout(() => {
      setCrafting(null);
    }, recipe.craftTime * 1000);
  }

  if (!visible) return null;

  return (
    <div className="w-screen h-screen flex items-center justify-center">
      <div className="w-[80vw] h-[80vh] bg-gradient-to-b from-zinc-900 to-zinc-950 rounded-lg shadow-2xl border border-zinc-700 overflow-hidden">
        <div className="h-full flex">
          <aside className="w-72 border-r border-zinc-800 p-4 flex flex-col gap-4">
            <div>
              <h2 className="text-xl font-bold text-zinc-100">Crafting Terminal</h2>
              <p className="text-xs text-zinc-400">Level {playerLevel} - Select a recipe to craft</p>
            </div>

            <div className="flex-1 overflow-y-auto pr-1">
              <div className="space-y-2">
                {recipes.map((r) => {
                  const disabled = !canCraft(r);
                  return (
                    <button
                      key={r.id}
                      onClick={() => setSelectedId(r.id)}
                      className={`w-full text-left p-3 rounded-md border border-zinc-800 ${selectedId === r.id ? 'bg-zinc-800 border-amber-500' : 'bg-zinc-900 hover:bg-zinc-800'} ${disabled ? 'opacity-50' : ''} focus:outline-none`}
                    >
                      <div className="flex items-center justify-between">
                        <div className="text-sm font-medium text-zinc-100">{r.name}</div>
                        <div className="text-xs text-zinc-400">{r.craftTime}s</div>
                      </div>
                      <div className="text-xs text-zinc-400 mt-1">{r.description}</div>
                      <div className="text-xs text-amber-400 mt-1">Lvl {r.requiredLevel}</div>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="pt-2 border-t border-zinc-800">
              <div className="text-xs text-zinc-400 mb-2">Inventory</div>
              <div className="grid grid-cols-2 gap-2 max-h-32 overflow-y-auto">
                {Object.entries(inventory).map(([k, v]) => (
                  <div key={k} className="text-xs bg-zinc-800 rounded-md p-2 flex items-center justify-between">
                    <div className="truncate text-zinc-100">{k}</div>
                    <div className="text-zinc-300">{v}</div>
                  </div>
                ))}
              </div>
            </div>
          </aside>

          <main className="flex-1 p-6 flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-2xl font-semibold text-zinc-100">{selected?.name || 'No Recipe'}</h3>
                <p className="text-xs text-zinc-400">Detailed crafting view</p>
              </div>
              <button onClick={handleClose} className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md text-sm">
                Close [ESC]
              </button>
            </div>

            <div className="grid grid-cols-2 gap-4 h-full">
              <div className="h-full">
                {selected && <CraftingPanel recipe={selected} onCraft={onCraft} disabled={!canCraft(selected)} />}
              </div>

              <div className="h-full bg-zinc-900 border border-zinc-800 rounded-lg p-4 flex flex-col">
                <div className="text-xs text-zinc-400">Crafting Queue</div>
                <div className="flex-1 flex items-center justify-center">
                  {crafting ? (
                    <div className="text-center">
                      <div className="text-lg font-medium text-amber-400">{recipes.find(r => r.id === crafting.id)?.name}</div>
                      <div className="text-xs text-zinc-400 mt-2">Remaining: {crafting.remaining}s</div>
                      <div className="w-48 h-3 bg-zinc-800 rounded-full mt-4 overflow-hidden">
                        <div
                          className="h-full bg-amber-500 transition-all"
                          style={{ width: `${((recipes.find(r => r.id === crafting.id)?.craftTime ?? 1) - crafting.remaining) / (recipes.find(r => r.id === crafting.id)?.craftTime ?? 1) * 100}%` }}
                        />
                      </div>
                    </div>
                  ) : (
                    <div className="text-sm text-zinc-400">No active jobs. Select a recipe and click craft.</div>
                  )}
                </div>

                <div className="pt-4 border-t border-zinc-800 text-xs text-zinc-400">
                  Tip: Craft items to gain XP and level up your crafting skill.
                </div>
              </div>
            </div>
          </main>
        </div>
      </div>
    </div>
  );
}
