import { AdminPageShell } from './AdminPageShell';
import './admin.css';

const RECIPES = [
  { id: 'r1', item: 'Salted Caramel Latte', yield: '1 drink', ingredients: 'Espresso 18g, milk 180ml, caramel 15ml' },
  { id: 'r2', item: 'Butter Croissant', yield: '1 unit', ingredients: 'Frozen croissant 1 pc, bake 12 min' },
  { id: 'r3', item: 'Chicken Wrap', yield: '1 wrap', ingredients: 'Tortilla, chicken 80g, veg 40g' },
];

export function AdminRecipesPage() {
  return (
    <AdminPageShell pageId="admin-recipes" title="Recipes" hint="COGS and yield tracking — future inventory API.">
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Menu item</th>
            <th>Yield</th>
            <th>Ingredients (sample)</th>
          </tr>
        </thead>
        <tbody>
          {RECIPES.map((r) => (
            <tr key={r.id}>
              <td>{r.item}</td>
              <td>{r.yield}</td>
              <td>{r.ingredients}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
