import type { ClothingComponent, PropData } from "./appearance";

export interface AccessorySet {
	id: string;
	name: string;
	clothing: ClothingComponent[];
	props: PropData[];
	createdAt: number;
}
