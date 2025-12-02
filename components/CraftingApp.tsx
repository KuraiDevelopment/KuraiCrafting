import React, { useEffect, useMemo, useState } from 'react';
import CraftingPanel from './CraftingPanel';

type Recipe = {
  id: string;
  name: string;
  description: string;
  ingredients: { name: string; count: number }[];
  craftTime: number;
  resultCount: number;
};

const MOCK_RECIPES: Recipe[] = [
  {
    id: 'r1',
    name: 'Repair Kit',
    description: 'Basic kit used to repair small items and vehicles.',
    ingredients: [
      { name: 'Cloth', count: 3 },
      { name: 'Adhesive', count: 1 },
      { name: 'Metal Scrap', count: 2 },
    ],
    craftTime: 6,
    resultCount: 1,
  },
  {
    id: 'r2',
    name: 'Lockpick Set',
    description: 'Used to unlock simple locks. Fragile.',
    ingredients: [
      { name: 'Wire', count: 2 },
      { name: 'Metal Scrap', count: 1 },
    ],
    craftTime: 4,
    resultCount: 1,
  },
  {
    id: 'r3',
    name: 'Advanced Medpack',
    description: 'Heals more and removes debuffs.',
    ingredients: [
      { name: 'Herbs', count: 5 },
      { name: 'Bottle', count: 1 },
      { name: 'Cloth', count: 2 },
    ],
    craftTime: 10,
    resultCount: 1,
  },
];

export default function CraftingApp() {
  const [recipes] = useState<Recipe[]>(MOCK_RECIPES);
  const [selectedId, setSelectedId] = useState<string | null>(recipes[0].id);
  const [inventory, setInventory] = useState<Record<string, number>>({
    Cloth: 10,
    Adhesive: 2,
    'Metal Scrap': 5,
    Wire: 3,
    Herbs: 6,
    Bottle: 2,
  });

  const [crafting, setCrafting] = useState<{ id: string; remaining: number } | null>(null);

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
    return recipe.ingredients.every((ing) => (inventory[ing.name] || 0) >= ing.count) && !crafting;
  }

  function onCraft(id: string) {
    const recipe = recipes.find((r) => r.id === id);
    if (!recipe) return;
    if (!canCraft(recipe)) return;

    // consume ingredients
    setInventory((inv) => {
      const next = { ...inv };
      recipe.ingredients.forEach((ing) => {
        next[ing.name] = (next[ing.name] || 0) - ing.count;
      });
      return next;
    });

    setCrafting({ id: recipe.id, remaining: recipe.craftTime });

    // mock completion after craftTime
    setTimeout(() => {
      setInventory((inv) => ({ ...inv, [recipe.name]: (inv[recipe.name] || 0) + recipe.resultCount }));
    }, recipe.craftTime * 1000);
  }

  function quickFill() {
    // small helper to top up resources for demo
    setInventory({
      Cloth: 20,
      Adhesive: 5,
      'Metal Scrap': 10,
      Wire: 6,
      Herbs: 12,
      Bottle: 5,
    });
  }

  return (
    <div className="w-[80vw] h-[80vh] bg-gradient-to-b from-zinc-900 to-zinc-950 rounded-lg shadow-2xl border border-zinc-700 overflow-hidden">
      <div className="h-full flex">
        <aside className="w-72 border-r border-zinc-800 p-4 flex flex-col gap-4">
          <div>
            <h2 className="text-xl font-bold text-zinc-100">Crafting Terminal</h2>
            <p className="text-xs text-zinc-400">Select a recipe to view details and craft items.</p>
          </div>

          <div className="flex-1 overflow-y-auto pr-1">
            <div className="space-y-2">
              {recipes.map((r) => {
                const disabled = !r.ingredients.every((ing) => (inventory[ing.name] || 0) >= ing.count) || Boolean(crafting);
                return (
                  <button
                    key={r.id}
                    onClick={() => setSelectedId(r.id)}
                    className={`w-full text-left p-3 rounded-md border border-zinc-800 ${selectedId === r.id ? 'bg-zinc-800 border-amber-500' : 'bg-zinc-900 hover:bg-zinc-800'} focus:outline-none`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="text-sm font-medium text-zinc-100">{r.name}</div>
                      <div className="text-xs text-zinc-400">{r.craftTime}s</div>
                    </div>
                    <div className="text-xs text-zinc-400 mt-1">{r.description}</div>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="pt-2 border-t border-zinc-800">
            <div className="flex items-center justify-between">
              <div className="text-xs text-zinc-400">Inventory</div>
              <button onClick={quickFill} className="text-xs text-amber-400 hover:underline">Quick Fill</button>
            </div>
            <div className="mt-2 grid grid-cols-2 gap-2">
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
              <h3 className="text-2xl font-semibold text-zinc-100">{selected.name}</h3>
              <p className="text-xs text-zinc-400">Detailed crafting view</p>
            </div>
            <div className="text-xs text-zinc-400">Status: {crafting ? `Crafting ${crafting.id} (${crafting.remaining}s)` : 'Idle'}</div>
          </div>

          <div className="grid grid-cols-2 gap-4 h-full">
            <div className="h-full">
              <CraftingPanel recipe={selected} onCraft={onCraft} disabled={!canCraft(selected)} />
            </div>

            <div className="h-full bg-zinc-900 border border-zinc-800 rounded-lg p-4 flex flex-col">
              <div className="text-xs text-zinc-400">Crafting Queue (live)</div>
              <div className="flex-1 flex items-center justify-center">
                {crafting ? (
                  <div className="text-center">
                    <div className="text-lg font-medium text-amber-400">{recipes.find(r => r.id === crafting.id)?.name}</div>
                    <div className="text-xs text-zinc-400 mt-2">Remaining: {crafting.remaining}s</div>
                    <div className="w-48 h-3 bg-zinc-800 rounded-full mt-4 overflow-hidden">
                      <div
                        className="h-full bg-amber-500"
                        style={{ width: `${((recipes.find(r => r.id === crafting.id)?.craftTime ?? 1) - crafting.remaining) / (recipes.find(r => r.id === crafting.id)?.craftTime ?? 1) * 100}%` }}
                      />
                    </div>
                  </div>
                ) : (
                  <div className="text-sm text-zinc-400">No active jobs. Start crafting to see progress.</div>
                )}
              </div>

              <div className="pt-4 border-t border-zinc-800 text-xs text-zinc-400">
                Tip: Hold shift while crafting in-game to queue multiple (mock tooltip only).
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
