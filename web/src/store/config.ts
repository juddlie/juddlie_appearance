import create from "zustand";

export interface ConfigAnimation {
	value: string;
	label: string;
	desc: string;
}

export interface ConfigQuickSlot {
	label: string;
	component: number;
	prop: number;
	type: string;
}

export interface ConfigCameraRange {
	min: number;
	max: number;
	step: number;
}

export interface ConfigOverlayGroups {
	hair: number[];
	colorable: number[];
	makeup: number[];
}

export interface ClothingComponentGroups {
	managedByDedicatedTabs: number[];
	layerOrder: number[];
}

export interface MarketplaceConfig {
	enabled?: boolean;
	minPrice?: number;
	maxPrice?: number;
	defaultPrice?: number;
	priceStep?: number;
	defaultTtlHours?: number;
	tax?: number;
}

export interface ShareConfig {
	codeLength?: number;
	defaultMaxUses?: number;
	defaultTtlSeconds?: number;
}

export interface ConfigState {
	loaded: boolean;
	cameraPresets: { value: string; label: string }[];
	lightingPresets: { value: string; label: string }[];
	cameraDefaults: { preset: string; lighting: string; fov: number; zoom: number; rotation: number };
	cameraRanges: { fov: ConfigCameraRange; zoom: ConfigCameraRange; rotation: ConfigCameraRange };
	randomizerDefaultSpeed: number;
	randomizerSpeedRange: ConfigCameraRange;
	eyeColorMax: number;
	headBlendRanges: { parent: ConfigCameraRange; skin: ConfigCameraRange; mix: ConfigCameraRange };
	faceFeatureLabels: Record<string, string>;
	animations: ConfigAnimation[];
	overlayLabels: string[];
	overlayGroups: ConfigOverlayGroups;
	componentLabels: Record<number, string>;
	clothingComponentGroups: ClothingComponentGroups;
	accessoryComponentIds: number[];
	propLabels: Record<number, string>;
	propIds: number[];
	tattooZones: { value: string; label: string }[];
	faceRegions: { name: string; features: string[] }[];
	quickSlots: ConfigQuickSlot[];
	randomizerCategories: { key: string; label: string }[];
	walkStyles: { value: string; label: string; clipset: string | null; category: string }[];
	walkStyleCategories: { value: string; label: string }[];
	outfitCategories: { value: string; label: string }[];
	locale: string;
	pedModels: { value: string; label: string }[];
	disabledComponents: number[];
	disabledProps: number[];
	allowedTabs: string[] | null;
	accentColor: string;
	prices: Record<string, number>;
	outfitCategoryColors: Record<string, string>;
	marketplace: MarketplaceConfig;
	share: ShareConfig;
	dropTierColors: Record<string, string>;
	shopType: string | null;

	setConfig: (config: Partial<ConfigState>) => void;
	setAllowedTabs: (tabs: string[] | null) => void;
	setShopType: (shopType: string | null) => void;
}

export const useConfig = create<ConfigState>((set) => ({
	loaded: false,
	cameraPresets: [],
	lightingPresets: [],
	cameraDefaults: { preset: "", lighting: "", fov: 0, zoom: 0, rotation: 0 },
	cameraRanges: {
		fov: { min: 0, max: 0, step: 1 },
		zoom: { min: 0, max: 0, step: 1 },
		rotation: { min: 0, max: 0, step: 1 },
	},
	randomizerDefaultSpeed: 0,
	randomizerSpeedRange: { min: 0, max: 0, step: 1 },
	eyeColorMax: 0,
	headBlendRanges: {
		parent: { min: 0, max: 0, step: 1 },
		skin: { min: 0, max: 0, step: 1 },
		mix: { min: 0, max: 0, step: 0.01 },
	},
	faceFeatureLabels: {},
	animations: [],
	overlayLabels: [],
	overlayGroups: { hair: [], colorable: [], makeup: [] },
	componentLabels: {},
	clothingComponentGroups: { managedByDedicatedTabs: [], layerOrder: [] },
	accessoryComponentIds: [],
	propLabels: {},
	propIds: [],
	tattooZones: [],
	faceRegions: [],
	quickSlots: [],
	randomizerCategories: [],
	walkStyles: [],
	walkStyleCategories: [],
	outfitCategories: [],
	locale: "en",
	pedModels: [],
	disabledComponents: [],
	disabledProps: [],
	allowedTabs: null,
	accentColor: "blue",
	prices: {},
	outfitCategoryColors: {},
	marketplace: {},
	share: {},
	dropTierColors: {},
	shopType: null,

	setConfig: (config) => set((state) => ({ ...state, ...config, loaded: true })),
	setAllowedTabs: (tabs) => set({ allowedTabs: tabs }),
	setShopType: (shopType) => set({ shopType }),
}));
