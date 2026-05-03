import create from "zustand";

const storageKey = "juddlie_appearance_favorites";

/**
 * key format: "clothing:3:42" | "prop:0:15" | "hair:12"
 * persisted to localStorage so it survives sessions.
 */
interface FavoritesState {
	keys: Set<string>;
	isFavorite: (key: string) => boolean;
	toggle: (key: string) => void;
	showOnlyFavorites: boolean;
	setShowOnlyFavorites: (show: boolean) => void;
}

function loadFavorites(): Set<string> {
	try {
		const raw = localStorage.getItem(storageKey);
		if (raw) return new Set(JSON.parse(raw));
	} catch { /* ignore */ }
	return new Set();
}

function saveFavorites(keys: Set<string>) {
	try {
		localStorage.setItem(storageKey, JSON.stringify([...keys]));
	} catch { /* ignore */ }
}

export const useFavorites = create<FavoritesState>((set, get) => ({
	keys: loadFavorites(),
	showOnlyFavorites: false,

	isFavorite: (key) => get().keys.has(key),

	toggle: (key) => set((s) => {
		const next = new Set(s.keys);
		if (next.has(key)) next.delete(key); else next.add(key);
		saveFavorites(next);
		return { keys: next };
	}),

	setShowOnlyFavorites: (showOnlyFavorites) => set({ showOnlyFavorites }),
}));

/** helper to create favorite keys */
export const favKey = {
	clothing: (component: number, drawable: number) => `clothing:${component}:${drawable}`,
	prop: (propId: number, drawable: number) => `prop:${propId}:${drawable}`,
	hair: (style: number) => `hair:${style}`,
};
