import create from "zustand";

export interface ComponentMax {
	maxDrawable: number;
	maxTexture: number;
}

export interface HairMax {
	maxStyle: number;
	maxColor: number;
}

export interface MaxValuesState {
	components: Record<string, ComponentMax>;
	props: Record<string, ComponentMax>;
	hair: HairMax;
	overlays: Record<string, number>;

	setMaxValues: (data: {
		components: Record<string, ComponentMax>;
		props: Record<string, ComponentMax>;
		hair: HairMax;
		overlays: Record<string, number>;
	}) => void;

	updateTextureMax: (type: "component" | "prop", id: number, maxTexture: number) => void;

	getComponentMax: (componentId: number) => ComponentMax;
	getPropMax: (propId: number) => ComponentMax;
}

export const useMaxValues = create<MaxValuesState>((set, get) => ({
	components: {},
	props: {},
	hair: { maxStyle: 0, maxColor: 0 },
	overlays: {},

	setMaxValues: (data) => set({
		components: data.components,
		props: data.props,
		hair: data.hair,
		overlays: data.overlays,
	}),

	updateTextureMax: (type, id, maxTexture) => set((s) => {
		const key = String(id);
		if (type === "component") {
			const prev = s.components[key] ?? { maxDrawable: 0, maxTexture: 0 };
			return { components: { ...s.components, [key]: { ...prev, maxTexture } }, props: s.props };
		} else {
			const prev = s.props[key] ?? { maxDrawable: 0, maxTexture: 0 };
			return { props: { ...s.props, [key]: { ...prev, maxTexture } }, components: s.components };
		}
	}),

	getComponentMax: (componentId) => {
		return get().components[String(componentId)] ?? { maxDrawable: 0, maxTexture: 0 };
	},

	getPropMax: (propId) => {
		return get().props[String(propId)] ?? { maxDrawable: 0, maxTexture: 0 };
	},
}));
