import create from "zustand";
import type { AccessorySet } from "../types/accessory";

interface AccessoriesState {
	sets: AccessorySet[];
	searchQuery: string;

	setSets: (sets: AccessorySet[]) => void;
	addSet: (set: AccessorySet) => void;
	removeSet: (id: string) => void;
	updateSet: (id: string, data: Partial<AccessorySet>) => void;
	setSearchQuery: (query: string) => void;
}

export const useAccessories = create<AccessoriesState>((set) => ({
	sets: [],
	searchQuery: "",

	setSets: (sets) => set({ sets }),
	addSet: (newSet) => set((s) => ({ sets: [newSet, ...s.sets] })),
	removeSet: (id) => set((s) => ({ sets: s.sets.filter((a) => a.id !== id) })),
	updateSet: (id, data) => set((s) => ({
		sets: s.sets.map((a) => a.id === id ? { ...a, ...data } : a),
	})),
	setSearchQuery: (searchQuery) => set({ searchQuery }),
}));
