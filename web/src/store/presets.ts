import create from "zustand";
import type { AppearancePreset } from "../types";

interface PresetsState {
	presets: AppearancePreset[];
	searchQuery: string;
	selectedTags: string[];
	hoveredPreset: string | null;

	setPresets: (presets: AppearancePreset[]) => void;
	addPreset: (preset: AppearancePreset) => void;
	removePreset: (id: string) => void;
	updatePreset: (id: string, data: Partial<AppearancePreset>) => void;
	setSearchQuery: (query: string) => void;
	setSelectedTags: (tags: string[]) => void;
	setHoveredPreset: (id: string | null) => void;
	importPresets: (json: string) => void;
	exportPresets: () => string;
}

export const usePresets = create<PresetsState>((set, get) => ({
	presets: [],
	searchQuery: "",
	selectedTags: [],
	hoveredPreset: null,

	setPresets: (presets) => set({ presets }),
	addPreset: (preset) => set((s) => ({ presets: [...s.presets, preset] })),
	removePreset: (id) => set((s) => ({ presets: s.presets.filter((p) => p.id !== id) })),
	updatePreset: (id, data) => set((s) => ({
		presets: s.presets.map((p) => p.id === id ? { ...p, ...data } : p),
	})),
	setSearchQuery: (searchQuery) => set({ searchQuery }),
	setSelectedTags: (selectedTags) => set({ selectedTags }),
	setHoveredPreset: (hoveredPreset) => set({ hoveredPreset }),
	importPresets: (json) => {
		try {
			const imported = JSON.parse(json) as AppearancePreset[];
			if (Array.isArray(imported)) set((s) => ({ presets: [...s.presets, ...imported] }));
		} catch { /* invalid json */ }
	},
	exportPresets: () => JSON.stringify(get().presets, null, 2),
}));
