import create from "zustand";
import type { AppearanceData, FaceFeatures, HeadBlend, HeadOverlay, HairData, ClothingLayer, RandomizerLocks } from "../types";

const defaultFaceFeatures: FaceFeatures = {
	noseWidth: 0, nosePeakHeight: 0, nosePeakLength: 0, noseBoneHeight: 0,
	nosePeakLowering: 0, noseBoneTwist: 0, eyebrowHeight: 0, eyebrowDepth: 0,
	cheekboneHeight: 0, cheekboneWidth: 0, cheekWidth: 0, eyeOpening: 0,
	lipThickness: 0, jawBoneWidth: 0, jawBoneLength: 0, chinBoneHeight: 0,
	chinBoneLength: 0, chinBoneWidth: 0, chinHole: 0, neckThickness: 0,
};

const defaultHeadBlend: HeadBlend = {
	shapeFirst: 0, shapeSecond: 0, skinFirst: 0, skinSecond: 0,
	shapeMix: 0.5, skinMix: 0.5,
};

export const defaultAppearance: AppearanceData = {
	model: "",
	headBlend: defaultHeadBlend,
	faceFeatures: defaultFaceFeatures,
	headOverlays: [],
	hair: { style: 0, color: 0, highlight: 0 },
	eyeColor: 0,
	clothing: [],
	props: [],
	tattoos: [],
	walkStyle: "",
};

interface AppearanceState {
	current: AppearanceData;
	original: AppearanceData;
	layers: ClothingLayer[];
	locks: RandomizerLocks;
	dirty: boolean;
	activeTab: string;

	setAppearance: (data: AppearanceData) => void;
	setOriginal: (data: AppearanceData) => void;
	setFaceFeature: (key: keyof FaceFeatures, value: number) => void;
	setHeadBlend: (blend: Partial<HeadBlend>) => void;
	setHeadOverlay: (index: number, overlay: Partial<HeadOverlay>) => void;
	setHair: (hair: Partial<HairData>) => void;
	setEyeColor: (color: number) => void;
	setClothing: (component: number, drawable: number, texture: number) => void;
	setProp: (prop: number, drawable: number, texture: number) => void;
	addTattoo: (tattoo: any) => void;
	removeTattoo: (collection: string, overlay: string) => void;
	clearTattoos: () => void;
	setLayers: (layers: ClothingLayer[]) => void;
	toggleLayerVisibility: (id: string) => void;
	reorderLayer: (id: string, newOrder: number) => void;
	setModel: (model: string) => void;
	setWalkStyle: (walkStyle: string) => void;
	setLock: (category: keyof RandomizerLocks, locked: boolean) => void;
	setActiveTab: (tab: string) => void;
	revert: () => void;
	apply: () => void;
}

export const useAppearance = create<AppearanceState>((set) => ({
	current: { ...defaultAppearance },
	original: { ...defaultAppearance },
	layers: [],
	locks: { face: false, hair: false, clothing: false, props: false, tattoos: false },
	dirty: false,
	activeTab: "face",

	setAppearance: (data) => set({ current: data, dirty: true }),
	setOriginal: (data) => set({ original: data, current: data, dirty: false }),

	setFaceFeature: (key, value) => set((s) => ({
		current: { ...s.current, faceFeatures: { ...s.current.faceFeatures, [key]: value } },
		dirty: true,
	})),

	setHeadBlend: (blend) => set((s) => ({
		current: { ...s.current, headBlend: { ...s.current.headBlend, ...blend } },
		dirty: true,
	})),

	setHeadOverlay: (index, overlay) => set((s) => {
		const overlays = [...s.current.headOverlays];
		overlays[index] = { ...overlays[index], ...overlay };
		return { current: { ...s.current, headOverlays: overlays }, dirty: true };
	}),

	setHair: (hair) => set((s) => {
		const { collection, localIndex, ...currentHair } = s.current.hair as any;
		return {
			current: { ...s.current, hair: { ...currentHair, ...hair } },
			dirty: true,
		};
	}),

	setEyeColor: (color) => set((s) => ({
		current: { ...s.current, eyeColor: color },
		dirty: true,
	})),

	setClothing: (component, drawable, texture) => set((s) => {
		const clothing = [...s.current.clothing];
		const idx = clothing.findIndex((c) => c.component === component);
		if (idx >= 0) clothing[idx] = { component, drawable, texture };
		else clothing.push({ component, drawable, texture });
		return { current: { ...s.current, clothing }, dirty: true };
	}),

	setProp: (prop, drawable, texture) => set((s) => {
		const props = [...s.current.props];
		const idx = props.findIndex((p) => p.prop === prop);
		if (idx >= 0) props[idx] = { prop, drawable, texture };
		else props.push({ prop, drawable, texture });
		return { current: { ...s.current, props }, dirty: true };
	}),

	addTattoo: (tattoo) => set((s) => ({
		current: { ...s.current, tattoos: [...s.current.tattoos, tattoo] },
		dirty: true,
	})),

	removeTattoo: (collection, overlay) => set((s) => ({
		current: {
			...s.current,
			tattoos: s.current.tattoos.filter((t) => !(t.collection === collection && t.overlay === overlay)),
		},
		dirty: true,
	})),

	clearTattoos: () => set((s) => ({
		current: { ...s.current, tattoos: [] },
		dirty: true,
	})),

	setLayers: (layers) => set({ layers }),

	toggleLayerVisibility: (id) => set((s) => ({
		layers: s.layers.map((l) => l.id === id ? { ...l, visible: !l.visible } : l),
	})),

	reorderLayer: (id, newOrder) => set((s) => ({
		layers: s.layers.map((l) => l.id === id ? { ...l, order: newOrder } : l).sort((a, b) => a.order - b.order),
	})),

	setModel: (model) => set((s) => ({
		current: { ...s.current, model },
		dirty: true,
	})),

	setWalkStyle: (walkStyle) => set((s) => ({
		current: { ...s.current, walkStyle },
		dirty: true,
	})),

	setLock: (category, locked) => set((s) => ({
		locks: { ...s.locks, [category]: locked },
	})),

	setActiveTab: (activeTab) => set({ activeTab }),
	revert: () => set((s) => ({ current: { ...s.original }, dirty: false })),
	apply: () => set((s) => ({ original: { ...s.current }, dirty: false })),
}));
