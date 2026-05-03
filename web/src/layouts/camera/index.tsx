import React from "react";
import { Box, ScrollArea, Stack, Text, SegmentedControl, Button, Group, createStyles } from "@mantine/core";
import { TbCamera, TbRefresh } from "react-icons/tb";
import { useCamera } from "../../store/camera";
import { useConfig } from "../../store/config";
import { useLocale } from "../../store/locale";
import { ValueSlider, SectionHeader, PanelCard } from "../../components/Shared";
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

const Camera: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);

	const cameraPresets = useConfig((s) => s.cameraPresets);
	const lightingPresets = useConfig((s) => s.lightingPresets);
	const defaults = useConfig((s) => s.cameraDefaults);
	const ranges = useConfig((s) => s.cameraRanges);

	const preset = useCamera((s) => s.preset);
	const lighting = useCamera((s) => s.lighting);
	const fov = useCamera((s) => s.fov);
	const zoom = useCamera((s) => s.zoom);
	const rotation = useCamera((s) => s.rotation);
	const compareMode = useCamera((s) => s.compareMode);
	const setPreset = useCamera((s) => s.setPreset);
	const setLighting = useCamera((s) => s.setLighting);
	const setFov = useCamera((s) => s.setFov);
	const setZoom = useCamera((s) => s.setZoom);
	const setRotation = useCamera((s) => s.setRotation);
	const toggleCompare = useCamera((s) => s.toggleCompare);

	const handlePreset = (v: string) => {
		setPreset(v);
		fetchNui("appearance:setCameraPreset", { preset: v });
	};

	const handleLighting = (v: string) => {
		setLighting(v);
		fetchNui("appearance:setLighting", { lighting: v });
	};

	const handleRestoreDefaults = () => {
		setPreset(defaults.preset);
		setLighting(defaults.lighting);
		setFov(defaults.fov);
		setZoom(defaults.zoom);
		setRotation(defaults.rotation);

		fetchNui("appearance:setCameraPreset", { preset: defaults.preset });
		fetchNui("appearance:setLighting", { lighting: defaults.lighting });
		fetchNui("appearance:setFov", { fov: defaults.fov });
		fetchNui("appearance:setZoom", { zoom: defaults.zoom });
		fetchNui("appearance:setRotation", { rotation: defaults.rotation });
	};

	return (
		<Box className={classes.container}>
			<Text size="lg" weight={700}>{t("ui.camera.title")}</Text>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={8}>
					<PanelCard>
						<SectionHeader>{t("ui.camera.preset")}</SectionHeader>
						<SegmentedControl
							fullWidth
							size="xs"
							value={preset}
							onChange={handlePreset}
							data={cameraPresets}
						/>
					</PanelCard>

					<PanelCard>
						<SectionHeader>{t("ui.camera.lighting")}</SectionHeader>
						<SegmentedControl
							fullWidth
							size="xs"
							value={lighting}
							onChange={handleLighting}
							data={lightingPresets}
						/>
					</PanelCard>

					<PanelCard>
						<Group position="apart" mb={4}>
							<SectionHeader>{t("ui.camera.controls")}</SectionHeader>
							<Button
								size="xs"
								variant="subtle"
								color="gray"
								leftIcon={<TbRefresh size={12} />}
								onClick={handleRestoreDefaults}
							>
								{t("ui.camera.restore_defaults")}
							</Button>
						</Group>
						<ValueSlider
							label={t("ui.camera.fov")}
							value={fov}
							onChange={(v) => { setFov(v); fetchNui("appearance:setFov", { fov: v }); }}
							min={ranges.fov.min}
							max={ranges.fov.max}
							step={ranges.fov.step}
							precision={0}
						/>
						<ValueSlider
							label={t("ui.camera.zoom")}
							value={zoom}
							onChange={(v) => { setZoom(v); fetchNui("appearance:setZoom", { zoom: v }); }}
							min={ranges.zoom.min}
							max={ranges.zoom.max}
							step={ranges.zoom.step}
							precision={1}
						/>
						<ValueSlider
							label={t("ui.camera.rotation")}
							value={rotation}
							onChange={(v) => { setRotation(v); fetchNui("appearance:setRotation", { rotation: v }); }}
							min={ranges.rotation.min}
							max={ranges.rotation.max}
							step={ranges.rotation.step}
							precision={0}
						/>
					</PanelCard>

					<PanelCard>
						<SectionHeader>{t("ui.camera.compare")}</SectionHeader>
						<Button
							fullWidth
							size="xs"
							variant={compareMode ? "filled" : "light"}
							color={compareMode ? undefined : "gray"}
							onClick={() => {
								toggleCompare();
								fetchNui("appearance:toggleCompare", { enabled: !compareMode });
							}}
						>
							{compareMode ? t("ui.camera.exit_compare") : t("ui.camera.before_after")}
						</Button>
					</PanelCard>
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Camera;
