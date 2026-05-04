import React, { useEffect, useMemo, useState } from "react";
import { Box, ScrollArea, SegmentedControl, Stack, Text, Divider, createStyles } from "@mantine/core";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { useHistory } from "../../store/history";
import { useLocale } from "../../store/locale";
import { ValueSlider, SectionHeader, PanelCard } from "../../components/Shared";
import type { FaceFeatures } from "../../types";
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
	header: {
		display: "flex",
		alignItems: "center",
		justifyContent: "space-between",
	},
}));

const featureLabel = (key: string): string =>
	key.replace(/([A-Z])/g, " $1").replace(/^./, (s) => s.toUpperCase());

const Face: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);
	const faceRegions = useConfig((s) => s.faceRegions);
	const faceFeatureLabels = useConfig((s) => s.faceFeatureLabels);
	const headBlendRanges = useConfig((s) => s.headBlendRanges);
	const regionNames = useMemo(() => faceRegions.map((r) => r.name), [faceRegions]);
	const [region, setRegion] = useState("");

	const faceFeatures = useAppearance((s) => s.current.faceFeatures);
	const headBlend = useAppearance((s) => s.current.headBlend);
	const setFaceFeature = useAppearance((s) => s.setFaceFeature);
	const setHeadBlend = useAppearance((s) => s.setHeadBlend);
	const current = useAppearance((s) => s.current);
	const pushEntry = useHistory((s) => s.pushEntry);

	useEffect(() => {
		if (!region || !regionNames.includes(region)) {
			setRegion(regionNames[0] || "");
		}
	}, [region, regionNames]);

	const handleFeatureChange = (key: keyof FaceFeatures, value: number) => {
		setFaceFeature(key, value);
		fetchNui("appearance:setFaceFeature", { key, value });
	};

	const handleBlendChange = (key: string, value: number) => {
		pushEntry(t("ui.face.heritage_entry", key), current);
		setHeadBlend({ [key]: value });
		fetchNui("appearance:setHeadBlend", { [key]: value });
	};

	return (
		<Box className={classes.container}>
			<Box className={classes.header}>
				<Text size="lg" weight={700}>{t("ui.face.title")}</Text>
			</Box>

			<ScrollArea sx={{ flex: 1, minHeight: 0, minWidth: 0 }}>
				<Stack spacing={8} sx={{ minWidth: 0, minHeight: 0 }}>
					<PanelCard>
						<SectionHeader>{t("ui.face.heritage")}</SectionHeader>
						<ValueSlider
							label={t("ui.face.mother")}
							value={headBlend.shapeFirst}
							onChange={(v) => handleBlendChange("shapeFirst", v)}
							min={headBlendRanges.parent.min}
							max={headBlendRanges.parent.max}
							step={headBlendRanges.parent.step}
							precision={0}
						/>
						<ValueSlider
							label={t("ui.face.father")}
							value={headBlend.shapeSecond}
							onChange={(v) => handleBlendChange("shapeSecond", v)}
							min={headBlendRanges.parent.min}
							max={headBlendRanges.parent.max}
							step={headBlendRanges.parent.step}
							precision={0}
						/>
						<Divider my={4} color="dark.5" />
						<ValueSlider
							label={t("ui.face.shape_mix")}
							value={headBlend.shapeMix}
							onChange={(v) => handleBlendChange("shapeMix", v)}
							min={headBlendRanges.mix.min}
							max={headBlendRanges.mix.max}
							step={headBlendRanges.mix.step}
							precision={2}
						/>
						<ValueSlider
							label={t("ui.face.skin_mix")}
							value={headBlend.skinMix}
							onChange={(v) => handleBlendChange("skinMix", v)}
							min={headBlendRanges.mix.min}
							max={headBlendRanges.mix.max}
							step={headBlendRanges.mix.step}
							precision={2}
						/>
						<ValueSlider
							label={t("ui.face.skin_tone_1")}
							value={headBlend.skinFirst}
							onChange={(v) => handleBlendChange("skinFirst", v)}
							min={headBlendRanges.skin.min}
							max={headBlendRanges.skin.max}
							step={headBlendRanges.skin.step}
							precision={0}
						/>
						<ValueSlider
							label={t("ui.face.skin_tone_2")}
							value={headBlend.skinSecond}
							onChange={(v) => handleBlendChange("skinSecond", v)}
							min={headBlendRanges.skin.min}
							max={headBlendRanges.skin.max}
							step={headBlendRanges.skin.step}
							precision={0}
						/>
					</PanelCard>

					<PanelCard>
						<SectionHeader>{t("ui.face.features")}</SectionHeader>
						<SegmentedControl
							fullWidth
							size="xs"
							value={region}
							onChange={setRegion}
							data={regionNames}
						/>
						<Stack spacing={0} mt={8}>
							{faceRegions.find((r) => r.name === region)?.features.map((key) => (
								<ValueSlider
									key={key}
									label={faceFeatureLabels[key] || featureLabel(key)}
									value={faceFeatures[key as keyof FaceFeatures]}
									onChange={(v) => handleFeatureChange(key as keyof FaceFeatures, v)}
									min={-1}
									max={1}
									step={0.01}
									precision={2}
								/>
							))}
						</Stack>
					</PanelCard>
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Face;
