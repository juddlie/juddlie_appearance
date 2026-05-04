import create from "zustand";
import type { Outfit } from "../types/outfit";

interface OutfitsState {
	outfits: Outfit[];
	searchQuery: string;
	selectedCategory: string | null;

	setOutfits: (outfits: Outfit[]) => void;
	addOutfit: (outfit: Outfit) => void;
	removeOutfit: (id: string) => void;
	updateOutfit: (id: string, data: Partial<Outfit>) => void;
	toggleFavorite: (id: string) => void;
	setSearchQuery: (query: string) => void;
	setSelectedCategory: (category: string | null) => void;
}

export const useOutfits = create<OutfitsState>((set) => ({
	outfits: [],
	searchQuery: "",
	selectedCategory: null,

	setOutfits: (outfits) => set({ outfits }),

	addOutfit: (outfit) => set((s) => ({ outfits: [outfit, ...s.outfits] })),

	removeOutfit: (id) => set((s) => ({ outfits: s.outfits.filter((o) => o.id !== id) })),

	updateOutfit: (id, data) => set((s) => ({
		outfits: s.outfits.map((o) => o.id === id ? { ...o, ...data } : o),
	})),

	toggleFavorite: (id) => set((s) => ({
		outfits: s.outfits.map((o) => o.id === id ? { ...o, favorite: !o.favorite } : o),
	})),

	setSearchQuery: (searchQuery) => set({ searchQuery }),

	setSelectedCategory: (selectedCategory) => set({ selectedCategory }),
}));
