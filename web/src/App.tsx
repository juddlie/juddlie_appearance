import React, { useRef, useCallback } from "react";
import { Box, createStyles, Transition } from "@mantine/core";
import { Routes, Route, Navigate, useNavigate } from "react-router-dom";
import { useNuiEvent } from "./hooks/useNuiEvent";
import { useVisibility } from "./store/visibility";
import { useAppearance } from "./store/appearance";
import { usePresets } from "./store/presets";
import { useOutfits } from "./store/outfits";
import { useConfig, ConfigState } from "./store/config";
import { useLocale } from "./store/locale";
import { useMaxValues } from "./store/maxValues";
import { useCamera } from "./store/camera";
import { useExitListener } from "./hooks/useExitListener";
import { fetchNui } from "./utils/fetchNui";

import Sidebar from "./components/Sidebar";
import ActionBar from "./components/ActionBar";
import Face from "./layouts/face";
import Hair from "./layouts/hair";
import Clothing from "./layouts/clothing";
import Props from "./layouts/props";
import Tattoos from "./layouts/tattoos";
import Colors from "./layouts/colors";
import Presets from "./layouts/presets";
import Outfits from "./layouts/outfits";
import Camera from "./layouts/camera";
import Randomizer from "./layouts/randomizer";
import Animations from "./layouts/animations";
import Ped from "./layouts/ped";
import WalkStyle from "./layouts/walkstyle";
import Accessories from "./layouts/accessories";
import History from "./layouts/history";
import Marketplace from "./layouts/marketplace";
import Drops from "./layouts/drops";
import Wardrobe from "./layouts/wardrobe";

import type { AppearanceData, AppearancePreset } from "./types";
import type { Outfit } from "./types/outfit";

const useStyles = createStyles((theme) => ({
	container: {
		width: "100%",
		height: "100%",
		display: "flex",
		alignItems: "stretch",
	},
	main: {
		width: "100%",
		maxWidth: 520,
		minWidth: 300,
		height: "100vh",
		backgroundColor: theme.colors.dark[8],
		display: "flex",
		overflowX: "auto",
		position: "relative",
	},
	content: {
		flex: 1,
		minWidth: 0,
		overflow: "hidden",
		display: "flex",
		flexDirection: "column",
	},
	viewport: {
		flex: 1,
		height: "100%",
		cursor: "grab",
		"&:active": {
			cursor: "grabbing",
		},
	},
}));

const tabRoutes: Record<string, string> = {
	ped: "/ped",
	face: "/face",
	hair: "/hair",
	clothing: "/clothing",
	props: "/props",
	tattoos: "/tattoos",
	colors: "/colors",
	presets: "/presets",
	outfits: "/outfits",
	camera: "/camera",
	randomizer: "/randomizer",
	animations: "/animations",
	walkstyle: "/walkstyle",
	accessories: "/accessories",
	history: "/history",
	marketplace: "/marketplace",
	drops: "/drops",
	wardrobe: "/wardrobe",
};

const DefaultRedirect: React.FC = () => {
	const allowedTabs = useConfig((s) => s.allowedTabs);
	const firstTab = allowedTabs?.[0];
	const target = firstTab ? (tabRoutes[firstTab] || "/ped") : "/ped";

	return <Navigate to={target} replace />;
};

const App: React.FC = () => {
	const { classes } = useStyles();

	const [visible, setVisible] = useVisibility((state) => [state.visible, state.setVisible]);

	const setOriginal = useAppearance((s) => s.setOriginal);
	const setAppearanceData = useAppearance((s) => s.setAppearance);
	const setPresets = usePresets((s) => s.setPresets);
	const setOutfits = useOutfits((s) => s.setOutfits);
	const setConfig = useConfig((s) => s.setConfig);
	const setAllowedTabs = useConfig((s) => s.setAllowedTabs);
	const setShopType = useConfig((s) => s.setShopType);
	const setLocaleStrings = useLocale((s) => s.setStrings);
	const setLocaleName = useLocale((s) => s.setLocale);
	const setMaxValues = useMaxValues((s) => s.setMaxValues);
	const updateTextureMax = useMaxValues((s) => s.updateTextureMax);
	const setCameraPreset = useCamera((s) => s.setPreset);
	const setCameraLighting = useCamera((s) => s.setLighting);
	const setCameraFov = useCamera((s) => s.setFov);
	const setCameraZoom = useCamera((s) => s.setZoom);
	const setCameraRotation = useCamera((s) => s.setRotation);

	const navigate = useNavigate();

	useNuiEvent("setConfig", (data: Partial<ConfigState> & { localeStrings?: Record<string, string> }) => {
		if (data.localeStrings) {
			setLocaleStrings(data.localeStrings);
			delete data.localeStrings;
		}
		if (data.locale) {
			setLocaleName(data.locale);
		}
		if (data.cameraDefaults) {
			setCameraPreset(data.cameraDefaults.preset);
			setCameraLighting(data.cameraDefaults.lighting);
			setCameraFov(data.cameraDefaults.fov);
			setCameraZoom(data.cameraDefaults.zoom);
			setCameraRotation(data.cameraDefaults.rotation);
		}
		setConfig(data);
	});

	useNuiEvent("setVisible", (data?: { visible: boolean; route?: string }) => {
		if (data?.visible !== undefined) setVisible(data.visible);
		if (!data?.visible) setAllowedTabs(null);
		if (data?.route) navigate(data.route);
	});

	useNuiEvent("setAppearance", (data: AppearanceData) => {
		setOriginal(data);
	});

	useNuiEvent("updateModelAppearance", (data: AppearanceData) => {
		setAppearanceData(data);
	});

	useNuiEvent("setPresets", (data: AppearancePreset[]) => {
		setPresets(data);
	});

	useNuiEvent("setOutfits", (data: Outfit[]) => {
		setOutfits(data);
	});

	useNuiEvent("setMaxValues", (data: any) => {
		setMaxValues(data);
	});

	useNuiEvent("updateTextureMax", (data: { type: "component" | "prop"; id: number; maxTexture: number }) => {
		updateTextureMax(data.type, data.id, data.maxTexture);
	});

	useNuiEvent("setShopType", (data: { shopType: string | null }) => {
		setShopType(data.shopType ?? null);
	});

	useNuiEvent("setAllowedTabs", (data: { tabs: string[] }) => {
		setAllowedTabs(data.tabs);

		if (data.tabs && data.tabs.length > 0) {
			navigate(tabRoutes[data.tabs[0]] || "/ped");
		}
	});

	useExitListener(setVisible, () => { });

	return (
		<Box className={classes.container}>
			<Transition transition="slide-right" mounted={visible}>
				{(style) => (
					<Box className={classes.main} style={style} id="appearance-panel">
						<Sidebar />
						<Box className={classes.content}>
							<Box sx={{ flex: 1, minHeight: 0, display: "flex", flexDirection: "column" }}>
								<Routes>
									<Route path="/ped" element={<Ped />} />
									<Route path="/face" element={<Face />} />
									<Route path="/hair" element={<Hair />} />
									<Route path="/clothing" element={<Clothing />} />
									<Route path="/props" element={<Props />} />
									<Route path="/tattoos" element={<Tattoos />} />
									<Route path="/colors" element={<Colors />} />
									<Route path="/presets" element={<Presets />} />
									<Route path="/outfits" element={<Outfits />} />
									<Route path="/camera" element={<Camera />} />
									<Route path="/randomizer" element={<Randomizer />} />
									<Route path="/animations" element={<Animations />} />
									<Route path="/walkstyle" element={<WalkStyle />} />
									<Route path="/accessories" element={<Accessories />} />
									<Route path="/history" element={<History />} />
									<Route path="/marketplace" element={<Marketplace />} />
									<Route path="/drops" element={<Drops />} />
									<Route path="/wardrobe" element={<Wardrobe />} />
									<Route path="/" element={<DefaultRedirect />} />
								</Routes>
							</Box>

							<ActionBar
								onSavePreset={() => navigate("/presets")}
								onSaveOutfit={() => navigate("/outfits")}
							/>
						</Box>
					</Box>
				)}
			</Transition>
		</Box>
	);
};

export default App;
