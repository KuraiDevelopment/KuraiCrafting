import CraftingApp from './components/CraftingApp';

export default function App(): JSX.Element {
  return (
      <div className="fixed inset-0 flex items-center justify-center">
          <main className="w-[80vw] h-[80vh]">
            <CraftingApp />
          </main>
      </div>
  )
}
