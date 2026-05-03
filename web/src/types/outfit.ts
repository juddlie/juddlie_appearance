import type { ClothingComponent, PropData, TattooData, HairData } from "./appearance";

export interface OutfitData {
	clothing: ClothingComponent[];
	props: PropData[];
	tattoos?: TattooData[];
	hair?: HairData;
}

export interface Outfit {
	id: string;
	name: string;
	category: string;
	data: OutfitData;
	shareCode?: string;
	favorite: boolean;
	createdAt: number;
	tags?: string[];
}

