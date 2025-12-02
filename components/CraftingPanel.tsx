import React from 'react';

type Recipe = {
  id: string;
  name: string;
  description: string;
  ingredients: { name: string; count: number }[];
  craftTime: number; // seconds
  resultCount: number;
};

type Props = {
  recipe: Recipe;
  onCraft: (recipeId: string) => void;
  disabled?: boolean;
};

export default function CraftingPanel({ recipe, onCraft, disabled }: Props) {
  return (
    <div className="bg-zinc-900 border border-zinc-700 rounded-lg p-4 flex flex-col gap-3 shadow-lg w-full">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold text-zinc-100">{recipe.name}</h3>
          <p className="text-xs text-zinc-400">{recipe.description}</p>
        </div>
        <div className="text-right">
          <div className="text-sm text-zinc-300">Produces</div>
          <div className="text-xl font-medium text-amber-400">x{recipe.resultCount}</div>
        </div>
      </div>

      <div className="flex-1">
        <div className="text-xs text-zinc-400 mb-2">Ingredients</div>
        <div className="grid grid-cols-2 gap-2">
          {recipe.ingredients.map((ing) => (
            <div key={ing.name} className="flex items-center justify-between bg-zinc-800 rounded-md p-2">
              <div className="text-sm text-zinc-100">{ing.name}</div>
              <div className="text-xs text-zinc-300">{ing.count}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="flex items-center justify-between">
        <div className="text-xs text-zinc-400">Craft time: <span className="text-zinc-100 font-medium">{recipe.craftTime}s</span></div>
        <button
          onClick={() => onCraft(recipe.id)}
          disabled={disabled}
          className={`px-4 py-2 rounded-md font-semibold transition ${disabled ? 'bg-zinc-700 text-zinc-400 cursor-not-allowed' : 'bg-amber-500 text-zinc-900 hover:brightness-95'}`}>
          Craft
        </button>
      </div>
    </div>
  );
}
