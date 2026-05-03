import React, { useMemo, useState } from "react";
import {
	Box, ScrollArea, Stack, Text,
	Select, createStyles,
} from "@mantine/core";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { useLocale } from "../../store/locale";
import { useMaxValues } from "../../store/maxValues";
import { IndexSelector, SectionHeader, PanelCard, ValueSlider } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		minWidth: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
	panelCard: {
		minWidth: 0,
		overflowX: "auto",
	},
	panelContent: {
		minWidth: 0,
		width: "100%",
		overflowX: "auto",
		display: "flex",
		flexDirection: "column",
		gap: 8,
	},
}));

const defaultOverlay = { value: -1, opacity: 1, firstColor: 0, secondColor: 0 };

const Colors: React.FC = () => {
	const { classes } = useStyles();

	const [overlayIndex, setOverlayIndex] = useState(0);

	const overlayLabels = useConfig((s) => s.overlayLabels);
	const overlayGroups = useConfig((s) => s.overlayGroups);
	const eyeColorMax = useConfig((s) => s.eyeColorMax);
	const overlayMaxValues = useMaxValues((s) => s.overlays);
	const hairMax = useMaxValues((s) => s.hair);
	const t = useLocale((s) => s.t);

	const eyeColor = useAppearance((s) => s.current.eyeColor);
	const overlays = useAppearance((s) => s.current.headOverlays);
	const setEyeColor = useAppearance((s) => s.setEyeColor);
	const setHeadOverlay = useAppearance((s) => s.setHeadOverlay);

	const hairOverlayIndices = useMemo(() => new Set(overlayGroups.hair), [overlayGroups.hair]);
	const colorableOverlayIndices = useMemo(() => new Set(overlayGroups.colorable), [overlayGroups.colorable]);

	const overlayOptions = useMemo(() => overlayLabels
		.map((label, i) => ({ value: String(i), label }))
		.filter((option) => !hairOverlayIndices.has(Number(option.value))), [overlayLabels, hairOverlayIndices]);

	const selectedOverlay = overlays[overlayIndex] ?? defaultOverlay;
	const selectedOverlayMax = Number(overlayMaxValues[String(overlayIndex)]) || 0;
	const selectedOverlayHasColor = colorableOverlayIndices.has(overlayIndex);

	const handleEyeColorChange = (value: number) => {
		setEyeColor(value);
		fetchNui("appearance:setEyeColor", { color: value });
	};

	const handleOverlayChange = (index: number, key: string, value: number) => {
		const current = overlays[index] ?? defaultOverlay;
		const next = { ...current, [key]: value };

		setHeadOverlay(index, { [key]: value });
		fetchNui("appearance:setOverlay", { index, ...next });
	};

	return (
		<Box className={classes.container}>
			<Text size="lg" weight={700}>{t("ui.colors.title")}</Text>

			<ScrollArea sx={{ flex: 1, minHeight: 0, minWidth: 0 }}>
				<Stack spacing={8} sx={{ minWidth: 0, minHeight: 0 }}>
					<PanelCard sx={classes.panelCard}>
						<Box className={classes.panelContent}>
							<SectionHeader>{t("ui.colors.eye_color")}</SectionHeader>
							<IndexSelector
								label={t("ui.colors.color")}
								value={eyeColor}
								onChange={handleEyeColorChange}
								max={eyeColorMax}
							/>
						</Box>
					</PanelCard>

					<PanelCard sx={classes.panelCard}>
						<Box className={classes.panelContent}>
							<SectionHeader>{t("ui.colors.overlay_details")}</SectionHeader>
							<Select
								size="xs"
								value={String(overlayIndex)}
								onChange={(v) => v && setOverlayIndex(Number(v))}
								data={overlayOptions}
								sx={{ marginBottom: 8, width: "100%" }}
							/>
							<Stack spacing={4} mt={4} sx={{ minWidth: 0 }}>
								<IndexSelector
									label={t("ui.colors.style")}
									value={selectedOverlay.value}
									onChange={(v) => handleOverlayChange(overlayIndex, "value", v)}
									min={-1}
									max={selectedOverlayMax}
								/>
								<ValueSlider
									label={t("ui.hair.opacity")}
									value={selectedOverlay.opacity}
									onChange={(v) => handleOverlayChange(overlayIndex, "opacity", v)}
									min={0}
									max={1}
									step={0.05}
									precision={2}
								/>
								{selectedOverlayHasColor ? (
									<>
										<IndexSelector
											label={t("ui.colors.primary")}
											value={selectedOverlay.firstColor}
											onChange={(v) => handleOverlayChange(overlayIndex, "firstColor", v)}
											max={hairMax.maxColor}
										/>
										<IndexSelector
											label={t("ui.colors.secondary")}
											value={selectedOverlay.secondColor}
											onChange={(v) => handleOverlayChange(overlayIndex, "secondColor", v)}
											max={hairMax.maxColor}
										/>
									</>
								) : (
									<Text size="xs" color="dimmed">
										{t("ui.colors.style_opacity_only")}
									</Text>
								)}
							</Stack>
						</Box>
					</PanelCard>
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Colors;
