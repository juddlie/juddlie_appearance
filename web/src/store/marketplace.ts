import create from "zustand";
export interface MarketplaceListing {
	id: string;
	seller: string;
	sellerName?: string;
	name: string;
	description?: string;
	category: string;
	tags: string[];
	price: number;
	isMine?: boolean;
	purchases: number;
	created_at: number;
	expires_at?: number | null;
}

export type MarketplaceSort = "newest" | "price_asc" | "price_desc" | "popular";

interface MarketplaceState {
	listings: MarketplaceListing[];
	loading: boolean;
	search: string;
	category: string | null;
	sort: MarketplaceSort;
	previewId: string | null;

	setListings: (rows: MarketplaceListing[]) => void;
	setLoading: (v: boolean) => void;
	setSearch: (v: string) => void;
	setCategory: (v: string | null) => void;
	setSort: (v: MarketplaceSort) => void;
	setPreviewId: (id: string | null) => void;
}

export const useMarketplace = create<MarketplaceState>((set) => ({
	listings: [],
	loading: false,
	search: "",
	category: null,
	sort: "newest",
	previewId: null,

	setListings: (listings) => set({ listings, loading: false }),
	setLoading: (loading) => set({ loading }),
	setSearch: (search) => set({ search }),
	setCategory: (category) => set({ category }),
	setSort: (sort) => set({ sort }),
	setPreviewId: (previewId) => set({ previewId }),
}));
