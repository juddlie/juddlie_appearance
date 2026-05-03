import React from "react";
import { Box, ScrollArea, Stack, Text, Group, ActionIcon, Divider, Slider, createStyles } from "@mantine/core";
import { TbStar, TbStarFilled } from "react-icons/tb";
import { useAppearance } from "../../store/appearance";
import { ValueSlider, IndexSelector, SectionHeader, PanelCard } from "../../components/Shared";
import { useMaxValues } from "../../store/maxValues";
import { useConfig } from "../../store/config";
import { useFavorites, favKey } from "../../store/favorites";
import { useLocale } from "../../store/locale";
import { fetchNui } from "../../utils/fetchNui";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
}));

const defaultOverlay = { value: -1, opacity: 1, firstColor: 0, secondColor: 0 };

const Hair: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);
	const overlayLabels = useConfig((s) => s.overlayLabels);
	const hairOverlayIndices = useConfig((s) => s.overlayGroups.hair);

	const hair = useAppearance((s) => s.current.hair);
	const overlays = useAppearance((s) => s.current.headOverlays);
	const setHair = useAppearance((s) => s.setHair);
	const setHeadOverlay = useAppearance((s) => s.setHeadOverlay);
	const hairMax = useMaxValues((s) => s.hair);
	const overlayMaxValues = useMaxValues((s) => s.overlays);
	const favoriteKeys = useFavorites((s) => s.keys);
	const toggleFavorite = useFavorites((s) => s.toggle);
	const isFavorite = (key: string) => favoriteKeys.has(key);

	const handleHairChange = (key: string, value: number) => {
		setHair({ [key]: value });
		if (key === "color" || key === "highlight") {
			const color = key === "color" ? value : hair.color;
			const highlight = key === "highlight" ? value : hair.highlight;
			fetchNui("appearance:setHairColor", { color, highlight });
		} else {
			fetchNui("appearance:setHair", { ...hair, [key]: value });
		}
	};

	const handleOverlayChange = (index: number, key: string, value: number) => {
		const current = overlays[index] ?? defaultOverlay;
		const next = { ...current, [key]: value };

		setHeadOverlay(index, { [key]: value });
		fetchNui("appearance:setOverlay", { index, ...next });
	};

	return (
		<Box className={classes.container}>
			<Text size="lg" weight={700}>{t("ui.hair.title")}</Text>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={8}>
					<PanelCard>
						<Group position="apart">
							<SectionHeader>{t("ui.hair.style")}</SectionHeader>
							<ActionIcon size={16} variant="subtle"
								color={isFavorite(favKey.hair(hair.style)) ? "yellow" : "gray"}
								onClick={() => toggleFavorite(favKey.hair(hair.style))}>
								{isFavorite(favKey.hair(hair.style))
									? <TbStarFilled size={10} /> : <TbStar size={10} />}
							</ActionIcon>
						</Group>
						<IndexSelector
							label={t("ui.hair.style")}
							value={hair.style}
							onChange={(v) => handleHairChange("style", v)}
							max={hairMax.maxStyle}
						/>
						<IndexSelector
							label={t("ui.hair.color")}
							value={hair.color}
							onChange={(v) => handleHairChange("color", v)}
							max={hairMax.maxColor}
						/>
						<IndexSelector
							label={t("ui.hair.highlight")}
							value={hair.highlight}
							onChange={(v) => handleHairChange("highlight", v)}
							max={hairMax.maxColor}
						/>
					</PanelCard>

					{hairOverlayIndices.map((index) => {
						const overlay = overlays[index] ?? defaultOverlay;
						return (
							<PanelCard key={index}>
								<SectionHeader>{overlayLabels[index] ?? t("ui.colors.overlay_color")}</SectionHeader>
								<IndexSelector
									label={t("ui.hair.style")}
									value={overlay.value}
									onChange={(v) => handleOverlayChange(index, "value", v)}
									max={Number(overlayMaxValues[String(index)]) || 0}
									min={-1}
								/>
								<ValueSlider
									label={t("ui.hair.opacity")}
									value={overlay.opacity}
									onChange={(v) => handleOverlayChange(index, "opacity", v)}
									min={0}
									max={1}
									step={0.05}
									precision={2}
								/>
								<IndexSelector
									label={t("ui.colors.primary")}
									value={overlay.firstColor}
									onChange={(v) => handleOverlayChange(index, "firstColor", v)}
									max={hairMax.maxColor}
								/>
								<IndexSelector
									label={t("ui.colors.secondary")}
									value={overlay.secondColor}
									onChange={(v) => handleOverlayChange(index, "secondColor", v)}
									max={hairMax.maxColor}
								/>
							</PanelCard>
						);
					})}
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Hair;
