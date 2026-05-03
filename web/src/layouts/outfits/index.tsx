import React, { useState, useMemo, useEffect } from "react";
import {
	Box, ScrollArea, Stack, Text, TextInput, Badge, Group, Button,
	ActionIcon, Modal, Select, Tooltip, createStyles, UnstyledButton,
	SegmentedControl, Checkbox, NumberInput, CopyButton, Image,
} from "@mantine/core";
import {
	TbSearch, TbTrash, TbPlus, TbCopy, TbStar, TbStarFilled,
	TbHanger, TbEdit, TbRazor, TbShare, TbBuildingStore, TbDownload,
} from "react-icons/tb";

import { useOutfits } from "../../store/outfits";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { makeSignatureSvg } from "../../utils/signature";
import { useLocale } from "../../store/locale";
import type { Outfit, OutfitData } from "../../types/outfit";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		minWidth: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
		overflow: "hidden",
	},
	grid: {
		display: "flex",
		flexWrap: "wrap" as const,
		gap: 8,
		paddingRight: 6,
		paddingBottom: 8,
	},
	outfitCard: {
		width: "calc(50% - 4px)",
		boxSizing: "border-box",
		overflow: "hidden",
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		padding: 10,
		cursor: "pointer",
		transition: "background-color 150ms, border-color 150ms",
		border: `1px solid ${theme.colors.dark[5]}`,
		position: "relative" as const,
		"&:hover": {
			backgroundColor: theme.colors.dark[6],
			borderColor: theme.colors[theme.primaryColor][5],
		},
	},
	outfitCardFav: {
		borderColor: theme.colors.yellow[6],
	},
	actions: {
		position: "absolute" as const,
		top: 4,
		right: 4,
		display: "flex",
		gap: 2,
	},
}));

const Outfits: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const [saveModal, setSaveModal] = useState(false);
	const [shareModal, setShareModal] = useState<Outfit | null>(null);
	const [shareResult, setShareResult] = useState<string | null>(null);
	const [shareMaxUses, setShareMaxUses] = useState<number>(0);
	const [shareTtlHours, setShareTtlHours] = useState<number>(0);
	const [importModal, setImportModal] = useState(false);
	const [importCode, setImportCode] = useState("");
	const [marketModal, setMarketModal] = useState<Outfit | null>(null);
	const [marketPrice, setMarketPrice] = useState<number>(0);
	const [marketDesc, setMarketDesc] = useState("");
	const [newName, setNewName] = useState("");
	const [newCategory, setNewCategory] = useState<string>("");
	const [includeHair, setIncludeHair] = useState(false);

	const outfits = useOutfits((s) => s.outfits);
	const searchQuery = useOutfits((s) => s.searchQuery);
	const setSearchQuery = useOutfits((s) => s.setSearchQuery);
	const selectedCategory = useOutfits((s) => s.selectedCategory);
	const setSelectedCategory = useOutfits((s) => s.setSelectedCategory);
	const addOutfit = useOutfits((s) => s.addOutfit);
	const removeOutfit = useOutfits((s) => s.removeOutfit);
	const toggleFavorite = useOutfits((s) => s.toggleFavorite);

	const current = useAppearance((s) => s.current);
	const accentColor = useConfig((s) => s.accentColor);
	const outfitCategories = useConfig((s) => s.outfitCategories);
	const outfitCategoryColors = useConfig((s) => s.outfitCategoryColors);
	const marketplace = useConfig((s) => s.marketplace);
	const share = useConfig((s) => s.share);

	const defaultCategory = useMemo(() => {
		return outfitCategories.find((c) => c.value === "custom")?.value || outfitCategories[0]?.value || "";
	}, [outfitCategories]);

	const categoryLabelMap = useMemo(() => {
		return outfitCategories.reduce<Record<string, string>>((acc, category) => {
			acc[category.value] = category.label;
			return acc;
		}, {});
	}, [outfitCategories]);

	useEffect(() => {
		const configuredPrice = marketplace.defaultPrice ?? marketplace.minPrice ?? 0;
		setMarketPrice(configuredPrice);
	}, [marketplace.defaultPrice, marketplace.minPrice]);

	useEffect(() => {
		setShareMaxUses(share.defaultMaxUses ?? 0);
		setShareTtlHours(Math.floor((share.defaultTtlSeconds ?? 0) / 3600));
	}, [share.defaultMaxUses, share.defaultTtlSeconds]);

	useEffect(() => {
		if (!newCategory || !outfitCategories.some((category) => category.value === newCategory)) {
			setNewCategory(defaultCategory);
		}
	}, [defaultCategory, newCategory, outfitCategories]);

	useNuiEvent("shareCodeResult", (data: { code?: string; err?: string }) => {
		if (data.code) setShareResult(data.code);
	});
	useNuiEvent("importCodeResult", (data: { ok: boolean; err?: string }) => {
		if (data.ok) {
			setImportModal(false);
			setImportCode("");
		}
	});

	const filtered = useMemo(() => {
		let list = outfits;

		if (selectedCategory) {
			list = list.filter((o) => o.category === selectedCategory);
		}

		if (searchQuery) {
			const q = searchQuery.toLowerCase();
			list = list.filter((o) => o.name.toLowerCase().includes(q));
		}

		return [...list].sort((a, b) => {
			if (a.favorite && !b.favorite) return -1;
			if (!a.favorite && b.favorite) return 1;
			return (b.createdAt || 0) - (a.createdAt || 0);
		});
	}, [outfits, searchQuery, selectedCategory]);

	const handleSaveOutfit = () => {
		const outfitData: OutfitData = {
			clothing: JSON.parse(JSON.stringify(current.clothing)),
			props: JSON.parse(JSON.stringify(current.props)),
			tattoos: current.tattoos ? JSON.parse(JSON.stringify(current.tattoos)) : [],
		};

		if (includeHair && current.hair) {
			outfitData.hair = JSON.parse(JSON.stringify(current.hair));
		}

		const id = `outfit-${Date.now()}`;

		const outfit: Outfit = {
			id,
			name: newName || t("ui.outfits.untitled"),
			category: newCategory || defaultCategory,
			data: outfitData,
			shareCode: btoa(JSON.stringify(outfitData)).slice(0, share.codeLength ?? 0),
			favorite: false,
			createdAt: Date.now(),
		};

		addOutfit(outfit);
		fetchNui("appearance:saveOutfit", outfit);

		setSaveModal(false);
		setNewName("");
		setNewCategory(defaultCategory);
		setIncludeHair(false);
	};

	const handleGenerateShare = () => {
		if (!shareModal) return;
		setShareResult(null);
		fetchNui("appearance:generateShareCode", {
			outfitId: shareModal.id,
			maxUses: shareMaxUses,
			ttlSeconds: shareTtlHours * 3600,
		});
	};

	const handleImportShare = () => {
		if (!importCode.trim()) return;
		fetchNui("appearance:importShareCode", { code: importCode.trim().toUpperCase() });
	};

	const handleListMarketplace = () => {
		if (!marketModal) return;
		const listingId = `mp_${marketModal.id}_${Date.now()}`;
		fetchNui("appearance:listMarketplace", {
			id: listingId,
			name: marketModal.name,
			description: marketDesc,
			category: marketModal.category,
			tags: marketModal.tags || [],
			price: marketPrice,
			data: marketModal.data,
		});
		setMarketModal(null);
		setMarketDesc("");
		setMarketPrice(marketplace.defaultPrice ?? marketplace.minPrice ?? 0);
	};

	const handleApplyOutfit = (outfitId: string) => {
		const outfit = outfits.find((o) => o.id === outfitId);
		if (!outfit) return;

		fetchNui("appearance:applyOutfit", outfit.data);
	};

	const handleDeleteOutfit = (e: React.MouseEvent, outfitId: string) => {
		e.stopPropagation();
		removeOutfit(outfitId);
		fetchNui("appearance:deleteOutfit", outfitId);
	};

	const handleToggleFavorite = (e: React.MouseEvent, outfitId: string) => {
		e.stopPropagation();
		toggleFavorite(outfitId);
		fetchNui("appearance:updateOutfit", {
			id: outfitId,
			favorite: !outfits.find((o) => o.id === outfitId)?.favorite,
		});
	};

	const signatures = useMemo(() => {
		const map: Record<string, string> = {};
		outfits.forEach((o) => {
			map[o.id] = makeSignatureSvg(o.data, { seed: o.id });
		});
		return map;
	}, [outfits]);

	return (
		<Box className={classes.container}>
			<Group position="apart">
				<Group spacing={6}>
					<TbHanger size={18} />
					<Text size="lg" weight={700}>{t("ui.outfits.title")}</Text>
				</Group>
				<Group spacing={4}>
					<Tooltip label={t("ui.outfits.import_share_code")} transition="pop">
						<ActionIcon size="xs" variant="light" onClick={() => setImportModal(true)}>
							<TbDownload size={12} />
						</ActionIcon>
					</Tooltip>
					<Tooltip label={t("ui.outfits.save_current_outfit")} transition="pop">
						<ActionIcon size="xs" variant="light" onClick={() => setSaveModal(true)}>
							<TbPlus size={12} />
						</ActionIcon>
					</Tooltip>
				</Group>
			</Group>

			<SegmentedControl
				size="xs"
				value={selectedCategory || "all"}
				onChange={(v) => setSelectedCategory(v === "all" ? null : v)}
				data={[
					{ label: t("ui.common.all"), value: "all" },
					...outfitCategories.map((c) => ({ label: c.label, value: c.value })),
				]}
			/>

			<TextInput
				size="xs"
				placeholder={t("ui.outfits.search_placeholder")}
				icon={<TbSearch size={14} />}
				value={searchQuery}
				onChange={(e) => setSearchQuery(e.currentTarget.value)}
			/>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }} type="auto" scrollbarSize={8}>
				{filtered.length === 0 ? (
					<PanelCard>
						<Text size="xs" color="dimmed" align="center" py={24}>
							{t("ui.outfits.empty")}
						</Text>
					</PanelCard>
				) : (
					<Box className={classes.grid}>
						{filtered.map((outfit) => (
							<UnstyledButton
								key={outfit.id}
								className={cx(
									classes.outfitCard,
									outfit.favorite && classes.outfitCardFav
								)}
								onClick={() => handleApplyOutfit(outfit.id)}
							>
								<Group spacing={8} align="flex-start" noWrap>
									<Image
										src={signatures[outfit.id]}
										width={36}
										height={36}
										radius="sm"
										withPlaceholder
										fit="cover"
									/>
									<Stack spacing={2} sx={{ flex: 1, minWidth: 0 }}>
										<Text size="xs" weight={600} lineClamp={1}>{outfit.name}</Text>
										<Group spacing={4}>
											<Badge
												size="xs"
												variant="light"
												color={outfitCategoryColors[outfit.category] || "gray"}
											>
												{categoryLabelMap[outfit.category] || outfit.category}
											</Badge>
											{outfit.data.hair && (
												<Badge size="xs" variant="light" color="teal" leftSection={<TbRazor size={10} />}>
													{t("ui.outfits.hair")}
												</Badge>
											)}
											{(outfit.tags || []).slice(0, 2).map((tag) => (
												<Badge key={tag} size="xs" variant="outline" color="grape">{tag}</Badge>
											))}
										</Group>
									</Stack>
								</Group>

								<Group spacing={4} mt={6}>
									<Tooltip label={t("ui.outfits.generate_share_code")} transition="pop">
										<ActionIcon
											size={16}
											variant="subtle"
											color={accentColor}
											onClick={(e: React.MouseEvent) => {
												e.stopPropagation();
												setShareModal(outfit);
												setShareResult(null);
											}}
										>
											<TbShare size={10} />
										</ActionIcon>
									</Tooltip>
									<Tooltip label={t("ui.outfits.list_on_marketplace")} transition="pop">
										<ActionIcon
											size={16}
											variant="subtle"
											color="grape"
											onClick={(e: React.MouseEvent) => {
												e.stopPropagation();
												setMarketModal(outfit);
											}}
										>
											<TbBuildingStore size={10} />
										</ActionIcon>
									</Tooltip>
								</Group>

								<Box className={classes.actions}>
									<ActionIcon
										size={16}
										variant="subtle"
										color={outfit.favorite ? "yellow" : "gray"}
										onClick={(e: React.MouseEvent) => handleToggleFavorite(e, outfit.id)}
									>
										{outfit.favorite ? <TbStarFilled size={10} /> : <TbStar size={10} />}
									</ActionIcon>
									<ActionIcon
										size={16}
										variant="subtle"
										color="red"
										onClick={(e: React.MouseEvent) => handleDeleteOutfit(e, outfit.id)}
									>
										<TbTrash size={10} />
									</ActionIcon>
								</Box>
							</UnstyledButton>
						))}
					</Box>
				)}
			</ScrollArea>

			<Modal
				opened={saveModal}
				onClose={() => setSaveModal(false)}
				title={t("ui.outfits.save_outfit")}
				centered
				size="sm"
			>
				<Stack spacing={8}>
					<TextInput
						size="xs"
						label={t("ui.common.name")}
						value={newName}
						onChange={(e) => setNewName(e.currentTarget.value)}
						placeholder={t("ui.outfits.name_placeholder")}
					/>
					<Select
						size="xs"
						label={t("ui.common.category")}
						value={newCategory}
						onChange={(v) => v && setNewCategory(v)}
						data={outfitCategories.map((c) => ({ value: c.value, label: c.label }))}
					/>
					<Checkbox
						size="xs"
						label={t("ui.outfits.include_hairstyle")}
						checked={includeHair}
						onChange={(e) => setIncludeHair(e.currentTarget.checked)}
					/>
					<Button size="xs" variant="light" onClick={handleSaveOutfit} fullWidth>
						{t("ui.common.save")}
					</Button>
				</Stack>
			</Modal>

			<Modal
				opened={!!shareModal}
				onClose={() => { setShareModal(null); setShareResult(null); }}
				title={t("ui.outfits.share_outfit")}
				centered
				size="sm"
			>
				<Stack spacing={8}>
					<Text size="xs" color="dimmed">
						{t("ui.outfits.share_hint", shareModal?.name || t("ui.outfits.this_outfit"))}
					</Text>
					<NumberInput
						size="xs"
						label={t("ui.outfits.max_uses")}
						value={shareMaxUses}
						onChange={(v) => setShareMaxUses(typeof v === "number" ? v : 0)}
						min={0}
					/>
					<NumberInput
						size="xs"
						label={t("ui.outfits.expires_hours")}
						value={shareTtlHours}
						onChange={(v) => setShareTtlHours(typeof v === "number" ? v : 0)}
						min={0}
					/>
					<Button size="xs" variant="light" onClick={handleGenerateShare} fullWidth>
						{t("ui.outfits.generate_code")}
					</Button>
					{shareResult && (
						<Group spacing={6} position="center">
							<Text size="md" weight={700} sx={{ letterSpacing: 2 }}>{shareResult}</Text>
							<CopyButton value={shareResult}>
								{({ copied, copy }) => (
									<ActionIcon size="xs" variant="light" onClick={copy} color={copied ? "teal" : accentColor}>
										<TbCopy size={12} />
									</ActionIcon>
								)}
							</CopyButton>
						</Group>
					)}
				</Stack>
			</Modal>

			<Modal
				opened={importModal}
				onClose={() => { setImportModal(false); setImportCode(""); }}
				title={t("ui.outfits.import_share_code")}
				centered
				size="sm"
			>
				<Stack spacing={8}>
					<TextInput
						size="xs"
						label={t("ui.outfits.share_code")}
						value={importCode}
						onChange={(e) => setImportCode(e.currentTarget.value)}
						placeholder={t("ui.outfits.share_code_placeholder")}
						styles={{ input: { textTransform: "uppercase", letterSpacing: 2 } }}
					/>
					<Button size="xs" variant="light" onClick={handleImportShare} fullWidth>
						{t("ui.common.import")}
					</Button>
				</Stack>
			</Modal>

			<Modal
				opened={!!marketModal}
				onClose={() => setMarketModal(null)}
				title={t("ui.outfits.list_on_marketplace")}
				centered
				size="sm"
			>
				<Stack spacing={8}>
					<Text size="xs" color="dimmed">
						{t("ui.outfits.marketplace_hint", marketModal?.name || t("ui.outfits.this_outfit"))}
					</Text>
					<NumberInput
						size="xs"
						label={t("ui.common.price")}
						value={marketPrice}
						onChange={(v) => setMarketPrice(typeof v === "number" ? v : 0)}
						min={marketplace.minPrice ?? 0}
						max={marketplace.maxPrice}
						step={marketplace.priceStep ?? 1}
					/>
					<TextInput
						size="xs"
						label={t("ui.common.description_optional")}
						value={marketDesc}
						onChange={(e) => setMarketDesc(e.currentTarget.value)}
					/>
					<Button size="xs" variant="light" onClick={handleListMarketplace} fullWidth>
						{t("ui.outfits.list")}
					</Button>
				</Stack>
			</Modal>
		</Box>
	);
};

export default Outfits;
