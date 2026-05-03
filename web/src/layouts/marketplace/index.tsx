import React, { useEffect, useMemo, useState } from "react";
import {
	Box, ScrollArea, Stack, Text, TextInput, Badge, Group, Button,
	ActionIcon, Tooltip, createStyles, Select, Image, Modal,
} from "@mantine/core";
import {
	TbBuildingStore, TbSearch, TbEye, TbEyeOff, TbShoppingCart, TbTag,
	TbTrash,
} from "react-icons/tb";

import { useMarketplace, MarketplaceListing } from "../../store/marketplace";
import { useLocale } from "../../store/locale";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { fetchNui } from "../../utils/fetchNui";
import { makeSignatureSvg } from "../../utils/signature";
import { useConfig } from "../../store/config";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1, minHeight: 0, minWidth: 0, display: "flex", flexDirection: "column",
		padding: 12, gap: 8, overflow: "hidden",
	},
	scrollInner: {
		paddingRight: 6,
		paddingBottom: 8,
	},
	card: {
		width: "100%",
		boxSizing: "border-box",
		overflow: "hidden",
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		padding: 10,
		border: `1px solid ${theme.colors.dark[5]}`,
		"&:hover": { borderColor: theme.colors[theme.primaryColor][5] },
	},
	previewActive: {
		borderColor: theme.colors.yellow[6],
	},
}));

const Marketplace: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const [confirmBuy, setConfirmBuy] = useState<MarketplaceListing | null>(null);
	const [confirmUnlist, setConfirmUnlist] = useState<MarketplaceListing | null>(null);
	const currencySymbol = t("ui.common.currency_symbol");
	const outfitCategories = useConfig((s) => s.outfitCategories);
	const outfitCategoryColors = useConfig((s) => s.outfitCategoryColors);

	const listings = useMarketplace((s) => s.listings);
	const setListings = useMarketplace((s) => s.setListings);
	const loading = useMarketplace((s) => s.loading);
	const setLoading = useMarketplace((s) => s.setLoading);
	const search = useMarketplace((s) => s.search);
	const setSearch = useMarketplace((s) => s.setSearch);
	const category = useMarketplace((s) => s.category);
	const setCategory = useMarketplace((s) => s.setCategory);
	const sort = useMarketplace((s) => s.sort);
	const setSort = useMarketplace((s) => s.setSort);
	const previewId = useMarketplace((s) => s.previewId);
	const setPreviewId = useMarketplace((s) => s.setPreviewId);

	const refresh = () => {
		setLoading(true);
		fetchNui("appearance:browseMarketplace", { search, category, sort });
	};

	useEffect(() => {
		refresh();
		
		return () => {
			if (previewId) fetchNui("appearance:endMarketplacePreview", {});
		};
	}, []);

	useEffect(() => {
		const t = setTimeout(refresh, 250);
		return () => clearTimeout(t);
	}, [search, category, sort]);

	useNuiEvent("marketplaceResults", (data: { listings: MarketplaceListing[] }) => {
		setListings(data.listings || []);
	});

	useNuiEvent("marketplaceBuyResult", (data: { ok: boolean }) => {
		if (data.ok) {
			setConfirmBuy(null);
			refresh();
		}
	});

	useNuiEvent("marketplaceUnlistResult", (data: { ok: boolean }) => {
		if (data.ok) {
			setConfirmUnlist(null);
			refresh();
		} else {
			setLoading(false);
		}
	});

	const togglePreview = (listing: MarketplaceListing) => {
		if (previewId === listing.id) {
			fetchNui("appearance:endMarketplacePreview", {});
			setPreviewId(null);
		} else {
			fetchNui("appearance:previewMarketplace", { id: listing.id });
			setPreviewId(listing.id);
		}
	};

	const buy = () => {
		if (!confirmBuy) return;
		fetchNui("appearance:buyMarketplace", { id: confirmBuy.id });
	};

	const unlist = () => {
		if (!confirmUnlist) return;
		setLoading(true);
		if (previewId === confirmUnlist.id) {
			fetchNui("appearance:endMarketplacePreview", {});
			setPreviewId(null);
		}
		fetchNui("appearance:unlistMarketplace", { id: confirmUnlist.id });
	};

	const categoryOptions = useMemo(() => [
		{ value: "", label: t("ui.marketplace.all_categories") },
		...outfitCategories.map((c) => ({ value: c.value, label: c.label })),
	], [outfitCategories, t]);

	const categoryLabelMap = useMemo(() => {
		return outfitCategories.reduce<Record<string, string>>((acc, item) => {
			acc[item.value] = item.label;
			return acc;
		}, {});
	}, [outfitCategories]);

	return (
		<Box className={classes.container}>
			<Group spacing={6}>
				<TbBuildingStore size={18} />
				<Text size="lg" weight={700}>{t("ui.marketplace.title")}</Text>
			</Group>

			<TextInput
				size="xs"
				placeholder={t("ui.marketplace.search_placeholder")}
				icon={<TbSearch size={14} />}
				value={search}
				onChange={(e) => setSearch(e.currentTarget.value)}
			/>

			<Group spacing={6} grow>
				<Select
					size="xs"
					value={category || ""}
					onChange={(v) => setCategory(v || null)}
					data={categoryOptions}
				/>
				<Select
					size="xs"
					value={sort}
					onChange={(v) => v && setSort(v as any)}
					data={[
						{ value: "newest", label: t("ui.marketplace.sort_newest") },
						{ value: "price_asc", label: t("ui.marketplace.sort_price_asc") },
						{ value: "price_desc", label: t("ui.marketplace.sort_price_desc") },
						{ value: "popular", label: t("ui.marketplace.sort_popular") },
					]}
				/>
			</Group>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }} type="auto" scrollbarSize={8}>
				<Stack spacing={6} className={classes.scrollInner}>
					{listings.length === 0 ? (
						<Text size="xs" color="dimmed" align="center" py={24}>
							{loading ? t("ui.actions.loading") : t("ui.marketplace.no_listings")}
						</Text>
					) : (
						listings.map((l) => {
							const thumb = makeSignatureSvg(l, { seed: l.id });
							const isPreview = previewId === l.id;
							return (
								<Box key={l.id} className={cx(classes.card, isPreview && classes.previewActive)}>
									<Group spacing={8} align="center" noWrap>
										<Image src={thumb} width={48} height={48} radius="sm" fit="cover" withPlaceholder />
										<Stack spacing={4} sx={{ flex: 1, minWidth: 0 }}>
											<Group position="apart" spacing={6} align="center" noWrap>
												<Text size="xs" weight={600} lineClamp={1} sx={{ flex: 1, minWidth: 0, lineHeight: 1.2 }}>
													{l.name}
												</Text>
												<Badge
													color="green"
													size="sm"
													variant="light"
													leftSection={
														<Box sx={{ display: "flex", alignItems: "center" }}>
															<TbTag size={10} />
														</Box>
													}
													sx={{ flexShrink: 0 }}
												>
													{currencySymbol}{l.price}
												</Badge>
											</Group>
											{l.sellerName && (
												<Text size={10} color="dimmed" lineClamp={1} sx={{ lineHeight: 1.2 }}>
													{t("ui.marketplace.by_seller", l.sellerName)}
												</Text>
											)}
											{l.description && (
												<Text size={10} color="dimmed" lineClamp={2} sx={{ lineHeight: 1.3 }}>
													{l.description}
												</Text>
											)}
											<Group spacing={4} align="center" noWrap sx={{ overflow: "hidden" }}>
												<Badge size="xs" variant="light" color={outfitCategoryColors[l.category]} sx={{ flexShrink: 0 }}>
													{categoryLabelMap[l.category] || l.category}
												</Badge>
												{l.isMine && (
													<Badge size="xs" variant="light" color="yellow" sx={{ flexShrink: 0 }}>
														{t("ui.marketplace.mine")}
													</Badge>
												)}
												{(l.tags || []).slice(0, 2).map((t) => (
													<Badge key={t} size="xs" variant="outline" color="grape" sx={{ flexShrink: 0 }}>
														{t}
													</Badge>
												))}
											</Group>
										</Stack>
									</Group>
									<Group spacing={4} mt={8} position="right" align="center">
										<Tooltip label={isPreview ? t("ui.marketplace.stop_preview") : t("ui.marketplace.preview")}>
											<ActionIcon
												size="sm" variant="light"
												color={isPreview ? "yellow" : "blue"}
												onClick={() => togglePreview(l)}
											>
												{isPreview ? <TbEyeOff size={12} /> : <TbEye size={12} />}
											</ActionIcon>
										</Tooltip>
										{l.isMine ? (
											<Button
												size="xs" variant="light" color="red"
												leftIcon={<TbTrash size={12} />}
												onClick={() => setConfirmUnlist(l)}
											>{t("ui.marketplace.unlist")}</Button>
										) : (
											<Button
												size="xs" variant="light" color="green"
												leftIcon={<TbShoppingCart size={12} />}
												onClick={() => setConfirmBuy(l)}
											>{t("ui.marketplace.buy")}</Button>
										)}
									</Group>
								</Box>
							);
						})
					)}
				</Stack>
			</ScrollArea>

			<Modal
				opened={!!confirmBuy}
				onClose={() => setConfirmBuy(null)}
				title={t("ui.marketplace.confirm_purchase")}
				centered size="sm"
			>
				{confirmBuy && (
					<Stack spacing={8}>
						<Text size="sm">
							{t("ui.marketplace.confirm_buy_named", confirmBuy.name, currencySymbol, confirmBuy.price)}
						</Text>
						<Group grow>
							<Button size="xs" variant="default" onClick={() => setConfirmBuy(null)}>{t("ui.actions.cancel")}</Button>
							<Button size="xs" variant="light" color="green" onClick={buy}>{t("ui.actions.confirm")}</Button>
						</Group>
					</Stack>
				)}
			</Modal>

			<Modal
				opened={!!confirmUnlist}
				onClose={() => setConfirmUnlist(null)}
				title={t("ui.marketplace.confirm_unlist")}
				centered size="sm"
			>
				{confirmUnlist && (
					<Stack spacing={8}>
						<Text size="sm">
							{t("ui.marketplace.confirm_unlist_named", confirmUnlist.name)}
						</Text>
						<Group grow>
							<Button size="xs" variant="default" onClick={() => setConfirmUnlist(null)}>{t("ui.actions.cancel")}</Button>
							<Button size="xs" variant="light" color="red" onClick={unlist} loading={loading}>{t("ui.marketplace.unlist")}</Button>
						</Group>
					</Stack>
				)}
			</Modal>
		</Box>
	);
};

export default Marketplace;
