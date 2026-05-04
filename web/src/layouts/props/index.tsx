import React, { useMemo } from "react";
import { Box, ScrollArea, Stack, Text, Group, ActionIcon, createStyles } from "@mantine/core";
import { TbStar, TbStarFilled } from "react-icons/tb";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { useMaxValues } from "../../store/maxValues";
import { useFavorites, favKey } from "../../store/favorites";
import { useLocale } from "../../store/locale";
import { IndexSelector, SectionHeader, PanelCard } from "../../components/Shared";
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

const Props: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);

	const propIds = useConfig((s) => s.propIds);
	const propLabels = useConfig((s) => s.propLabels);
	const props = useAppearance((s) => s.current.props);
	const setProp = useAppearance((s) => s.setProp);
	const propMaxValues = useMaxValues((s) => s.props);
	const favoriteKeys = useFavorites((s) => s.keys);
	const toggleFavorite = useFavorites((s) => s.toggle);
	const showOnlyFavorites = useFavorites((s) => s.showOnlyFavorites);
	const setShowOnlyFavorites = useFavorites((s) => s.setShowOnlyFavorites);

	const getPropMax = (propId: number) => {
		return propMaxValues[String(propId)] ?? { maxDrawable: 0, maxTexture: 0 };
	};

	const getPropValue = (propId: number) => {
		const existing = props.find((p) => p.prop === propId);
		return { drawable: existing?.drawable ?? -1, texture: existing?.texture ?? 0 };
	};

	const handleDrawableChange = (propId: number, drawable: number) => {
		setProp(propId, drawable, 0);
		fetchNui("appearance:setProp", { prop: propId, drawable, texture: 0 });
	};

	const handleTextureChange = (propId: number, texture: number) => {
		const current = getPropValue(propId);
		setProp(propId, current.drawable, texture);
		fetchNui("appearance:setProp", { prop: propId, drawable: current.drawable, texture });
	};

	return (
		<Box className={classes.container}>
			<Group position="apart">
				<Text size="lg" weight={700}>{t("ui.props.title")}</Text>
				<ActionIcon size="xs" variant={showOnlyFavorites ? "filled" : "subtle"}
					color={showOnlyFavorites ? "yellow" : "gray"}
					onClick={() => setShowOnlyFavorites(!showOnlyFavorites)}>
					{showOnlyFavorites ? <TbStarFilled size={12} /> : <TbStar size={12} />}
				</ActionIcon>
			</Group>
			<Text size="xs" color="dimmed">{t("ui.props.remove_hint")}</Text>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={8}>
				{propIds
					.filter((propId) => !showOnlyFavorites || favoriteKeys.has(favKey.prop(propId, getPropValue(propId).drawable)))
					.map((propId) => {
					const val = getPropValue(propId);
					const fk = favKey.prop(propId, val.drawable);
					return (
						<PanelCard key={propId}>
							<Group position="apart">
								<SectionHeader>{propLabels[propId] ?? t("ui.props.slot", propId)}</SectionHeader>
								<ActionIcon size={16} variant="subtle"
									color={favoriteKeys.has(fk) ? "yellow" : "gray"}
									onClick={() => toggleFavorite(fk)}>
									{favoriteKeys.has(fk) ? <TbStarFilled size={10} /> : <TbStar size={10} />}
								</ActionIcon>
							</Group>
								<IndexSelector
									label={t("ui.clothing.drawable")}
									value={val.drawable}
									onChange={(v) => handleDrawableChange(propId, v)}
									max={getPropMax(propId).maxDrawable}
									min={-1}
								/>
								<IndexSelector
									label={t("ui.clothing.texture")}
									value={val.texture}
									onChange={(v) => handleTextureChange(propId, v)}
									max={getPropMax(propId).maxTexture}
								/>
							</PanelCard>
						);
					})}
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Props;
