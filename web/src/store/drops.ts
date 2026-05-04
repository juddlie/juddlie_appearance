import create from "zustand";

export interface Drop {
	id: string;
	name: string;
	description?: string;
	tier: string;
	data: any;
	startsAt?: number | null;
	endsAt?: number | null;
	claimable: boolean;
	source: "config" | "db";
}

interface DropsState {
	drops: Drop[];
	loading: boolean;
	previewId: string | null;
	setDrops: (drops: Drop[]) => void;
	setLoading: (v: boolean) => void;
	setPreviewId: (id: string | null) => void;
}

export const useDrops = create<DropsState>((set) => ({
	drops: [],
	loading: false,
	previewId: null,
	setDrops: (drops) => set({ drops, loading: false }),
	setLoading: (loading) => set({ loading }),
	setPreviewId: (previewId) => set({ previewId }),
}));
