import create from "zustand";

interface OwnershipState {
	owned: Record<string, boolean>;
	setOwned: (map: Record<string, boolean>) => void;
	addOwned: (key: string) => void;
}

export const useOwnership = create<OwnershipState>((set) => ({
	owned: {},
	setOwned: (owned) => set({ owned }),
	addOwned: (key) => set((s) => ({ owned: { ...s.owned, [key]: true } })),
}));
