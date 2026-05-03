import React, { useState, useCallback, useMemo } from "react";
import {
	Box, Stack, Text, ScrollArea, createStyles, Portal,
	UnstyledButton, Divider,
} from "@mantine/core";
import { useNavigate, useLocation } from "react-router-dom";
import {
	TbMoodSmile, TbBrush, TbShirt, TbSunglasses, TbWriting,
	TbPalette, TbBookmark, TbHanger, TbCamera, TbDice5, TbRun,
	TbLayoutSidebarLeftCollapse, TbLayoutSidebarLeftExpand,
	TbUser, TbWalk, TbDeviceWatch, TbHistory,
	TbBuildingStore, TbGift, TbDoorEnter,
} from "react-icons/tb";
import { useConfig } from "../store/config";
import { useLocale } from "../store/locale";

const collapsedWidth = 46;
const expandedWidth = 130;

const useStyles = createStyles((theme, { collapsed }: { collapsed: boolean }) => ({
	sidebar: {
		width: collapsed ? collapsedWidth : expandedWidth,
		minWidth: collapsed ? collapsedWidth : expandedWidth,
		height: "100%",
		backgroundColor: theme.colors.dark[7],
		borderRight: `1px solid ${theme.colors.dark[5]}`,
		display: "flex",
		flexDirection: "column",
		minHeight: 0,
		transition: "width 200ms ease, min-width 200ms ease",
	},
	navItem: {
		display: "flex",
		alignItems: "center",
		justifyContent: collapsed ? "center" : "flex-start",
		gap: 8,
		width: "100%",
		padding: collapsed ? "8px 0" : "6px 10px",
		color: theme.colors.dark[1],
		fontSize: 12,
		transition: "background-color 150ms",
		"&:hover": {
			backgroundColor: theme.colors.dark[6],
			color: theme.white,
		},
	},
	navItemActive: {
		backgroundColor: theme.colors.dark[6],
		color: theme.colors[theme.primaryColor][4],
		borderLeft: collapsed ? "none" : `2px solid ${theme.colors[theme.primaryColor][5]}`,
		"&:hover": {
			color: theme.colors[theme.primaryColor][3],
		},
	},
	tooltip: {
		position: "fixed" as const,
		pointerEvents: "none" as const,
		padding: "4px 8px",
		backgroundColor: theme.colors.dark[5],
		color: theme.white,
		fontSize: 11,
		fontWeight: 500,
		borderRadius: theme.radius.sm,
		whiteSpace: "nowrap" as const,
		zIndex: 10000,
	},
	navList: {
		padding: collapsed ? "8px 4px" : "8px 6px",
		flex: 1,
	},
	sectionLabel: {
		fontSize: 9,
		color: theme.colors.dark[3],
		textTransform: "uppercase",
		fontWeight: 700,
		padding: collapsed ? "6px 0 2px 0" : "6px 10px 2px 10px",
		letterSpacing: 0.5,
		textAlign: collapsed ? "center" : "left",
	},
	toggleBtn: {
		display: "flex",
		alignItems: "center",
		justifyContent: "center",
		padding: "8px 0",
		color: theme.colors.dark[2],
		borderTop: `1px solid ${theme.colors.dark[5]}`,
		"&:hover": {
			color: theme.white,
			backgroundColor: theme.colors.dark[6],
		},
	},
}));

interface NavItem {
	label: string;
	path: string;
	section?: string;
	icon: React.ReactNode;
	tabKey: string;
}

interface TooltipState {
	label: string;
	top: number;
	left: number;
}

const Sidebar: React.FC = () => {
	const [collapsed, setCollapsed] = useState(true);
	const [tooltip, setTooltip] = useState<TooltipState | null>(null);
	const { classes, cx } = useStyles({ collapsed });
	const navigate = useNavigate();
	const location = useLocation();
	const t = useLocale((s) => s.t);

	const tr = useCallback((key: string, fallback: string) => {
		const value = t(key);
		return value === key ? fallback : value;
	}, [t]);

	const showTooltip = useCallback((e: React.MouseEvent, label: string) => {
		const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
		setTooltip({ label, top: rect.top + rect.height / 2, left: rect.right + 8 });
	}, []);

	const hideTooltip = useCallback(() => setTooltip(null), []);

	const navItems = useMemo<NavItem[]>(() => [
		{ label: tr("ui.sidebar.ped", "Ped"), path: "/ped", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "ped", icon: <TbUser size={16} /> },
		{ label: tr("ui.sidebar.face", "Face"), path: "/face", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "face", icon: <TbMoodSmile size={16} /> },
		{ label: tr("ui.sidebar.hair", "Hair"), path: "/hair", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "hair", icon: <TbBrush size={16} /> },
		{ label: tr("ui.sidebar.clothing", "Appearance"), path: "/clothing", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "clothing", icon: <TbShirt size={16} /> },
		{ label: tr("ui.sidebar.props", "Props"), path: "/props", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "props", icon: <TbSunglasses size={16} /> },
		{ label: tr("ui.sidebar.tattoos", "Tattoos"), path: "/tattoos", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "tattoos", icon: <TbWriting size={16} /> },
		{ label: tr("ui.sidebar.colors", "Colors"), path: "/colors", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "colors", icon: <TbPalette size={16} /> },
		{ label: tr("ui.sidebar.walkstyle", "Walk Style"), path: "/walkstyle", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "walkstyle", icon: <TbWalk size={16} /> },
		{ label: tr("ui.sidebar.accessories", "Accessories"), path: "/accessories", section: tr("ui.sidebar.appearance", "Appearance"), tabKey: "accessories", icon: <TbDeviceWatch size={16} /> },
		{ label: tr("ui.sidebar.presets", "Presets"), path: "/presets", section: tr("ui.sidebar.library", "Library"), tabKey: "presets", icon: <TbBookmark size={16} /> },
		{ label: tr("ui.sidebar.outfits", "Outfits"), path: "/outfits", section: tr("ui.sidebar.library", "Library"), tabKey: "outfits", icon: <TbHanger size={16} /> },
		{ label: tr("ui.sidebar.wardrobe", "Wardrobe"), path: "/wardrobe", section: tr("ui.sidebar.library", "Library"), tabKey: "wardrobe", icon: <TbDoorEnter size={16} /> },
		{ label: tr("ui.sidebar.marketplace", "Marketplace"), path: "/marketplace", section: tr("ui.sidebar.social", "Social"), tabKey: "marketplace", icon: <TbBuildingStore size={16} /> },
		{ label: tr("ui.sidebar.drops", "Drops"), path: "/drops", section: tr("ui.sidebar.social", "Social"), tabKey: "drops", icon: <TbGift size={16} /> },
		{ label: tr("ui.sidebar.camera", "Camera"), path: "/camera", section: tr("ui.sidebar.tools", "Tools"), tabKey: "camera", icon: <TbCamera size={16} /> },
		{ label: tr("ui.sidebar.history", "History"), path: "/history", section: tr("ui.sidebar.tools", "Tools"), tabKey: "history", icon: <TbHistory size={16} /> },
		{ label: tr("ui.sidebar.randomizer", "Randomizer"), path: "/randomizer", section: tr("ui.sidebar.tools", "Tools"), tabKey: "randomizer", icon: <TbDice5 size={16} /> },
		{ label: tr("ui.sidebar.animations", "Animations"), path: "/animations", section: tr("ui.sidebar.tools", "Tools"), tabKey: "animations", icon: <TbRun size={16} /> },
	], [tr]);

	const allowedTabs = useConfig((s) => s.allowedTabs);

	const filteredNavItems = useMemo(() => {
		if (!allowedTabs) return navItems;
		return navItems.filter((item) => allowedTabs.includes(item.tabKey));
	}, [allowedTabs, navItems]);

	let lastSection = "";

	return (
		<Box className={classes.sidebar}>
			<ScrollArea sx={{ flex: 1, minHeight: 0, minWidth: 0 }}>
				<Stack spacing={2} className={classes.navList} sx={{ minWidth: 0, minHeight: 0 }}>
					{filteredNavItems.map((item, idx) => {
						const showSection = item.section && item.section !== lastSection;
						if (item.section) lastSection = item.section;
						const isActive = location.pathname === item.path;

						return (
							<React.Fragment key={item.path}>
								{showSection && idx > 0 && <Divider my={4} color="dark.5" />}
								{showSection && !collapsed && (
									<Text className={classes.sectionLabel}>{item.section}</Text>
								)}
								<UnstyledButton
									className={cx(classes.navItem, isActive && classes.navItemActive)}
									onClick={() => navigate(item.path)}
									onMouseEnter={collapsed ? (e) => showTooltip(e, item.label) : undefined}
									onMouseLeave={collapsed ? hideTooltip : undefined}
									tabIndex={0}
								>
									{item.icon}
									{!collapsed && <Text size="xs">{item.label}</Text>}
								</UnstyledButton>
							</React.Fragment>
						);
					})}
				</Stack>
			</ScrollArea>
			<UnstyledButton className={classes.toggleBtn} onClick={() => setCollapsed((c) => !c)}>
				{collapsed ? <TbLayoutSidebarLeftExpand size={16} /> : <TbLayoutSidebarLeftCollapse size={16} />}
			</UnstyledButton>
			{tooltip && (
				<Portal>
					<Box
						className={classes.tooltip}
						style={{ top: tooltip.top, left: tooltip.left, transform: "translateY(-50%)" }}
					>
						{tooltip.label}
					</Box>
				</Portal>
			)}
		</Box>
	);
};

export default Sidebar;
