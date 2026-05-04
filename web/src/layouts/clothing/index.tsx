import React, { useMemo, useState } from "react";
import {
	Box, ScrollArea, Stack, Text, Badge, ActionIcon, Group,
	Modal, Divider, TextInput, createStyles,
} from "@mantine/core";
import { TbSearch, TbX, TbStar, TbStarFilled } from "react-icons/tb";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { useMaxValues } from "../../store/maxValues";
import { useFavorites, favKey } from "../../store/favorites";
import { useLocale } from "../../store/locale";
import { IndexSelector, LayerItem, SectionHeader, PanelCard } from "../../components/Shared";
import type { ClothingLayer } from "../../types";
import { fetchNui } from "../../utils/fetchNui";
import useDebounce from "../../hooks/useDebounce";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
	conflictBadge: {
		cursor: "pointer",
	},
}));

const Clothing: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);
	const [editComponent, setEditComponent] = useState<number | null>(null);
	const [searchQuery, setSearchQuery] = useState("");
	const debouncedSearch = useDebounce(searchQuery, 200);

	const componentLabels = useConfig((s) => s.componentLabels);
	const clothingComponentGroups = useConfig((s) => s.clothingComponentGroups);
	const clothing = useAppearance((s) => s.current.clothing);
	const layers = useAppearance((s) => s.layers);
	const setClothing = useAppearance((s) => s.setClothing);
	const setLayers = useAppearance((s) => s.setLayers);
	const toggleLayerVisibility = useAppearance((s) => s.toggleLayerVisibility);
	const reorderLayer = useAppearance((s) => s.reorderLayer);
	const componentMaxValues = useMaxValues((s) => s.components);
	const favoriteKeys = useFavorites((s) => s.keys);
	const toggleFavorite = useFavorites((s) => s.toggle);
	const showOnlyFavorites = useFavorites((s) => s.showOnlyFavorites);
	const setShowOnlyFavorites = useFavorites((s) => s.setShowOnlyFavorites);

	const getComponentMax = (componentId: number) => {
		return componentMaxValues[String(componentId)] ?? { maxDrawable: 0, maxTexture: 0 };
	};

	const componentEntries = useMemo(() => {
		return Object.entries(componentLabels).map(([key, label]) => {
			const comp = Number(key);
			const existing = clothing.find((c) => c.component === comp);
			return { component: comp, label, drawable: existing?.drawable ?? 0, texture: existing?.texture ?? 0 };
		});
	}, [componentLabels, clothing]);

	const filteredEntries = useMemo(() => {
		const managedByDedicatedTabs = new Set(clothingComponentGroups.managedByDedicatedTabs);
		let list = componentEntries.filter((e) => !managedByDedicatedTabs.has(e.component));
		list = list.filter((e) => getComponentMax(e.component).maxDrawable > 0);
		if (showOnlyFavorites) {
			list = list.filter((e) => favoriteKeys.has(favKey.clothing(e.component, e.drawable)));
		}
		if (!debouncedSearch.trim()) return list;
		const query = debouncedSearch.toLowerCase();
		return list.filter((entry) =>
			entry.label.toLowerCase().includes(query) ||
			String(entry.component).includes(query) ||
			String(entry.drawable).includes(query)
		);
	}, [componentEntries, debouncedSearch, showOnlyFavorites, componentMaxValues, favoriteKeys, clothingComponentGroups]);

	const sortedLayers = useMemo(() => {
		if (layers.length === 0) {
			return componentEntries
				.filter((c) => clothingComponentGroups.layerOrder.includes(c.component))
				.map((c, i): ClothingLayer => ({
					id: `layer-${c.component}`,
					component: c.component,
					label: c.label,
					drawable: c.drawable,
					texture: c.texture,
					visible: true,
					order: i,
				}));
		}
		return [...layers].sort((a, b) => a.order - b.order);
	}, [layers, componentEntries, clothingComponentGroups]);

	const handleDrawableChange = (component: number, drawable: number) => {
		setClothing(component, drawable, 0);
		fetchNui("appearance:setClothing", { component, drawable, texture: 0 });
	};

	const handleTextureChange = (component: number, texture: number) => {
		const existing = clothing.find((c) => c.component === component);
		setClothing(component, existing?.drawable ?? 0, texture);
		fetchNui("appearance:setClothing", { component, drawable: existing?.drawable ?? 0, texture });
	};

	const handleMoveUp = (id: string, currentOrder: number) => {
		if (currentOrder <= 0) return;
		const above = sortedLayers.find((l) => l.order === currentOrder - 1);
		if (above) {
			reorderLayer(id, currentOrder - 1);
			reorderLayer(above.id, currentOrder);
		}
	};

	const handleMoveDown = (id: string, currentOrder: number) => {
		if (currentOrder >= sortedLayers.length - 1) return;
		const below = sortedLayers.find((l) => l.order === currentOrder + 1);
		if (below) {
			reorderLayer(id, currentOrder + 1);
			reorderLayer(below.id, currentOrder);
		}
	};

	return (
		<Box className={classes.container}>
			<Group position="apart">
				<Text size="lg" weight={700}>{t("ui.clothing.title")}</Text>
				<Group spacing={4}>
					<ActionIcon size="xs" variant={showOnlyFavorites ? "filled" : "subtle"}
						color={showOnlyFavorites ? "yellow" : "gray"}
						onClick={() => setShowOnlyFavorites(!showOnlyFavorites)}>
						{showOnlyFavorites ? <TbStarFilled size={12} /> : <TbStar size={12} />}
					</ActionIcon>
					<Badge size="xs" variant="light">{t("ui.clothing.items_count", clothing.length)}</Badge>
				</Group>
			</Group>

			<TextInput
				size="xs"
				placeholder={t("ui.clothing.search_placeholder")}
				icon={<TbSearch size={14} />}
				value={searchQuery}
				onChange={(e) => setSearchQuery(e.currentTarget.value)}
				rightSection={searchQuery ? (
					<ActionIcon size="xs" onClick={() => setSearchQuery("")} variant="subtle">
						<TbX size={12} />
					</ActionIcon>
				) : undefined}
			/>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={8}>
					<PanelCard>
						<SectionHeader>{t("ui.clothing.layers")}</SectionHeader>
						<Text size={10} color="dimmed" mb={4}>{t("ui.clothing.layers_hint")}</Text>
						<Stack spacing={4}>
							{sortedLayers.map((layer, idx) => (
								<LayerItem
									key={layer.id}
									label={layer.label}
									visible={layer.visible}
									onToggleVisibility={() => toggleLayerVisibility(layer.id)}
									onMoveUp={() => handleMoveUp(layer.id, layer.order)}
									onMoveDown={() => handleMoveDown(layer.id, layer.order)}
									onSettings={() => setEditComponent(layer.component)}
									isFirst={idx === 0}
									isLast={idx === sortedLayers.length - 1}
								/>
							))}
						</Stack>
					</PanelCard>

					<PanelCard>
						<SectionHeader>{t("ui.clothing.component")}</SectionHeader>
						{filteredEntries.length === 0 ? (
							<Text size="xs" color="dimmed" align="center" py={16}>{t("ui.clothing.no_results")}</Text>
						) : (
						<Stack spacing={4}>
							{filteredEntries.map((entry) => (
								<Box key={entry.component} sx={(theme) => ({
									padding: "6px 8px",
									borderRadius: theme.radius.sm,
									"&:hover": { backgroundColor: theme.colors.dark[6] },
								})}>
								<Group position="apart" mb={4}>
									<Text size="xs" weight={600}>{entry.label}</Text>
									<ActionIcon size={16} variant="subtle"
										color={favoriteKeys.has(favKey.clothing(entry.component, entry.drawable)) ? "yellow" : "gray"}
										onClick={() => toggleFavorite(favKey.clothing(entry.component, entry.drawable))}>
										{favoriteKeys.has(favKey.clothing(entry.component, entry.drawable))
											? <TbStarFilled size={10} /> : <TbStar size={10} />}
									</ActionIcon>
								</Group>
									<IndexSelector
										label={t("ui.clothing.drawable")}
										value={entry.drawable}
										onChange={(v) => handleDrawableChange(entry.component, v)}
										max={getComponentMax(entry.component).maxDrawable}
									/>
									<IndexSelector
										label={t("ui.clothing.texture")}
										value={entry.texture}
										onChange={(v) => handleTextureChange(entry.component, v)}
										max={getComponentMax(entry.component).maxTexture}
									/>
								</Box>
							))}
						</Stack>
						)}
					</PanelCard>
				</Stack>
			</ScrollArea>

			<Modal
				opened={editComponent !== null}
				onClose={() => setEditComponent(null)}
				title={editComponent !== null ? t("ui.clothing.edit_component", componentLabels[editComponent] ?? t("ui.clothing.component")) : ""}
				centered
				size="sm"
			>
				{editComponent !== null && (
					<Stack spacing={8}>
						<IndexSelector
							label={t("ui.clothing.drawable")}
							value={componentEntries.find((c) => c.component === editComponent)?.drawable ?? 0}
							onChange={(v) => handleDrawableChange(editComponent, v)}
							max={getComponentMax(editComponent).maxDrawable}
						/>
						<IndexSelector
							label={t("ui.clothing.texture")}
							value={componentEntries.find((c) => c.component === editComponent)?.texture ?? 0}
							onChange={(v) => handleTextureChange(editComponent, v)}
							max={getComponentMax(editComponent).maxTexture}
						/>
					</Stack>
				)}
			</Modal>
		</Box>
	);
};

export default Clothing;
