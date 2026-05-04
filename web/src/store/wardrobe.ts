import create from "zustand";
import type { OutfitData } from "../types/outfit";

export interface WardrobeSlot {
	slot: number;
	name: string;
	data: OutfitData;
}

interface WardrobeState {
	slots: WardrobeSlot[];
	maxSlots: number;
	setSlots: (slots: WardrobeSlot[], max: number) => void;
}

export const useWardrobe = create<WardrobeState>((set) => ({
	slots: [],
	maxSlots: 4,
	setSlots: (slots, maxSlots) => set({ slots, maxSlots }),
}));
