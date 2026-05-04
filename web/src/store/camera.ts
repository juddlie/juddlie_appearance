import create from "zustand";

interface CameraState {
	preset: string;
	lighting: string;
	fov: number;
	zoom: number;
	rotation: number;
	compareMode: boolean;

	setPreset: (preset: string) => void;
	setLighting: (lighting: string) => void;
	setFov: (fov: number) => void;
	setZoom: (zoom: number) => void;
	setRotation: (rotation: number) => void;
	toggleCompare: () => void;
}

export const useCamera = create<CameraState>((set) => ({
	preset: "",
	lighting: "",
	fov: 0,
	zoom: 0,
	rotation: 0,
	compareMode: false,

	setPreset: (preset) => set({ preset }),
	setLighting: (lighting) => set({ lighting }),
	setFov: (fov) => set({ fov }),
	setZoom: (zoom) => set({ zoom }),
	setRotation: (rotation) => set({ rotation }),
	toggleCompare: () => set((s) => ({ compareMode: !s.compareMode })),
}));
