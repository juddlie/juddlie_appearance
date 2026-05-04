export interface FaceFeatures {
	noseWidth: number;
	nosePeakHeight: number;
	nosePeakLength: number;
	noseBoneHeight: number;
	nosePeakLowering: number;
	noseBoneTwist: number;
	eyebrowHeight: number;
	eyebrowDepth: number;
	cheekboneHeight: number;
	cheekboneWidth: number;
	cheekWidth: number;
	eyeOpening: number;
	lipThickness: number;
	jawBoneWidth: number;
	jawBoneLength: number;
	chinBoneHeight: number;
	chinBoneLength: number;
	chinBoneWidth: number;
	chinHole: number;
	neckThickness: number;
}

export const faceFeatureIndices: Record<keyof FaceFeatures, number> = {
	noseWidth: 0, nosePeakHeight: 1, nosePeakLength: 2, noseBoneHeight: 3,
	nosePeakLowering: 4, noseBoneTwist: 5, eyebrowHeight: 6, eyebrowDepth: 7,
	cheekboneHeight: 8, cheekboneWidth: 9, cheekWidth: 10, eyeOpening: 11,
	lipThickness: 12, jawBoneWidth: 13, jawBoneLength: 14, chinBoneHeight: 15,
	chinBoneLength: 16, chinBoneWidth: 17, chinHole: 18, neckThickness: 19,
};

export interface HeadBlend {
	shapeFirst: number;
	shapeSecond: number;
	skinFirst: number;
	skinSecond: number;
	shapeMix: number;
	skinMix: number;
}

export interface HeadOverlay {
	value: number;
	opacity: number;
	firstColor: number;
	secondColor: number;
}


export interface HairData {
	style: number;
	color: number;
	highlight: number;
}

export interface ClothingComponent {
	component: number;
	drawable: number;
	texture: number;
}


export interface PropData {
	prop: number;
	drawable: number;
	texture: number;
}


export interface TattooData {
	collection: string;
	overlay: string;
	zone: string;
	label: string;
}

export interface AppearanceData {
	model: string;
	headBlend: HeadBlend;
	faceFeatures: FaceFeatures;
	headOverlays: HeadOverlay[];
	hair: HairData;
	eyeColor: number;
	clothing: ClothingComponent[];
	props: PropData[];
	tattoos: TattooData[];
	walkStyle?: string;
}

export interface AppearancePreset {
	id: string;
	name: string;
	tags: string[];
	data: AppearanceData;
	createdAt: number;
	shareCode?: string;
}

export interface ClothingLayer {
	id: string;
	component: number;
	label: string;
	drawable: number;
	texture: number;
	visible: boolean;
	order: number;
}

export interface HistoryEntry {
	id: string;
	label: string;
	timestamp: number;
	data: AppearanceData;
}

export interface Snapshot {
	id: string;
	name: string;
	timestamp: number;
	data: AppearanceData;
}

export interface RandomizerLocks {
	face: boolean;
	hair: boolean;
	clothing: boolean;
	props: boolean;
	tattoos: boolean;
}

export interface ValidationIssue {
	type: "clipping" | "compatibility" | "visibility";
	severity: "warning" | "error";
	message: string;
	suggestion?: string;
}