import create from "zustand";
import type { HistoryEntry, Snapshot, AppearanceData } from "../types";

interface HistoryState {
	entries: HistoryEntry[];
	snapshots: Snapshot[];
	currentIndex: number;

	pushEntry: (label: string, data: AppearanceData) => void;
	undo: () => AppearanceData | null;
	redo: () => AppearanceData | null;
	canUndo: () => boolean;
	canRedo: () => boolean;
	saveSnapshot: (name: string, data: AppearanceData) => void;
	removeSnapshot: (id: string) => void;
	clearHistory: () => void;
}

let entryCounter = 0;

export const useHistory = create<HistoryState>((set, get) => ({
	entries: [],
	snapshots: [],
	currentIndex: -1,

	pushEntry: (label, data) => set((s) => {
		const trimmed = s.entries.slice(0, s.currentIndex + 1);
		const entry: HistoryEntry = {
			id: `h-${++entryCounter}`,
			label,
			timestamp: Date.now(),
			data: JSON.parse(JSON.stringify(data)),
		};
		return { entries: [...trimmed, entry], currentIndex: trimmed.length };
	}),

	undo: () => {
		const s = get();
		if (s.currentIndex <= 0) return null;
		const newIndex = s.currentIndex - 1;
		set({ currentIndex: newIndex });
		return JSON.parse(JSON.stringify(s.entries[newIndex].data));
	},

	redo: () => {
		const s = get();
		if (s.currentIndex >= s.entries.length - 1) return null;
		const newIndex = s.currentIndex + 1;
		set({ currentIndex: newIndex });
		return JSON.parse(JSON.stringify(s.entries[newIndex].data));
	},

	canUndo: () => get().currentIndex > 0,
	canRedo: () => get().currentIndex < get().entries.length - 1,

	saveSnapshot: (name, data) => set((s) => ({
		snapshots: [...s.snapshots, {
			id: `snap-${Date.now()}`,
			name,
			timestamp: Date.now(),
			data: JSON.parse(JSON.stringify(data)),
		}],
	})),

	removeSnapshot: (id) => set((s) => ({
		snapshots: s.snapshots.filter((snap) => snap.id !== id),
	})),

	clearHistory: () => set({ entries: [], currentIndex: -1 }),
}));
