import React, { useMemo } from "react";
import { Box, Group, Text, Badge, Tooltip, Collapse, createStyles } from "@mantine/core";
import { TbCoin, TbChevronDown, TbChevronUp } from "react-icons/tb";
import { useAppearance } from "../store/appearance";
import { useConfig } from "../store/config";
import { useLocale } from "../store/locale";

const useStyles = createStyles((theme) => ({
	wrapper: {
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		overflow: "hidden",
	},
	header: {
		display: "flex",
		alignItems: "center",
		justifyContent: "space-between",
		padding: "6px 10px",
		cursor: "pointer",
		"&:hover": {
			backgroundColor: theme.colors.dark[6],
		},
	},
	details: {
		padding: "0 10px 8px",
		display: "flex",
		flexDirection: "column",
		gap: 4,
	},
	row: {
		display: "flex",
		justifyContent: "space-between",
		alignItems: "center",
		padding: "2px 0",
	},
	free: {
		color: theme.colors.green[5],
	},
}));

interface ChangeDetail {
	label: string;
	count: number;
}

function countChanges(
	original: any,
	current: any,
	t: (key: string, ...args: (string | number)[]) => string
): { details: ChangeDetail[]; totalChanges: number } {
	const details: ChangeDetail[] = [];

	// face features
	if (original.faceFeatures && current.faceFeatures) {
		let faceCount = 0;
		const keys = Object.keys(original.faceFeatures) as string[];
		for (const key of keys) {
			if (original.faceFeatures[key] !== current.faceFeatures[key]) faceCount++;
		}
		if (faceCount > 0) details.push({ label: t("ui.cost_tracker.face_features"), count: faceCount });
	}

	// head blend
	if (original.headBlend && current.headBlend) {
		let blendCount = 0;
		const keys = Object.keys(original.headBlend) as string[];
		for (const key of keys) {
			if (original.headBlend[key] !== current.headBlend[key]) blendCount++;
		}
		if (blendCount > 0) details.push({ label: t("ui.cost_tracker.heritage"), count: blendCount });
	}

	// head overlays
	if (original.headOverlays && current.headOverlays) {
		let overlayCount = 0;
		const len = Math.max(original.headOverlays.length, current.headOverlays.length);
		for (let i = 0; i < len; i++) {
			const o = original.headOverlays[i];
			const c = current.headOverlays[i];
			if (!o || !c) { overlayCount++; continue; }
			if (o.value !== c.value || o.opacity !== c.opacity || o.firstColor !== c.firstColor || o.secondColor !== c.secondColor) {
				overlayCount++;
			}
		}
		if (overlayCount > 0) details.push({ label: t("ui.cost_tracker.overlays"), count: overlayCount });
	}

	// hair
	if (original.hair && current.hair) {
		let hairChanged = false;
		if (original.hair.style !== current.hair.style || original.hair.color !== current.hair.color || original.hair.highlight !== current.hair.highlight) {
			hairChanged = true;
		}
		if (hairChanged) details.push({ label: t("ui.cost_tracker.hair"), count: 1 });
	}

	// eye color
	if (original.eyeColor !== current.eyeColor) {
		details.push({ label: t("ui.cost_tracker.eye_color"), count: 1 });
	}

	// clothing
	if (original.clothing && current.clothing) {
		let clothingCount = 0;
		const maxLen = Math.max(original.clothing.length, current.clothing.length);
		for (let i = 0; i < maxLen; i++) {
			const o = original.clothing[i];
			const c = current.clothing[i];
			if (!o || !c) { clothingCount++; continue; }
			if (o.drawable !== c.drawable || o.texture !== c.texture) clothingCount++;
		}
		if (clothingCount > 0) details.push({ label: t("ui.cost_tracker.clothing"), count: clothingCount });
	}

	// props
	if (original.props && current.props) {
		let propCount = 0;
		const maxLen = Math.max(original.props.length, current.props.length);
		for (let i = 0; i < maxLen; i++) {
			const o = original.props[i];
			const c = current.props[i];
			if (!o || !c) { propCount++; continue; }
			if (o.drawable !== c.drawable || o.texture !== c.texture) propCount++;
		}
		if (propCount > 0) details.push({ label: t("ui.cost_tracker.props"), count: propCount });
	}

	// tattoos
	const origTattoos = original.tattoos || [];
	const currTattoos = current.tattoos || [];
	if (origTattoos.length !== currTattoos.length) {
		details.push({ label: t("ui.cost_tracker.tattoos"), count: Math.abs(currTattoos.length - origTattoos.length) });
	} else {
		const origSet = new Set(origTattoos.map((t: any) => `${t.collection}:${t.overlay}`));
		const diff = currTattoos.filter((t: any) => !origSet.has(`${t.collection}:${t.overlay}`));
		if (diff.length > 0) details.push({ label: t("ui.cost_tracker.tattoos"), count: diff.length });
	}

	// walk style
	if ((original.walkStyle || "default") !== (current.walkStyle || "default")) {
		details.push({ label: t("ui.cost_tracker.walk_style"), count: 1 });
	}

	// model
	if (original.model !== current.model) {
		details.push({ label: t("ui.cost_tracker.model"), count: 1 });
	}

	const totalChanges = details.reduce((sum, d) => sum + d.count, 0);
	return { details, totalChanges };
}

const CostTracker: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);
	const [expanded, setExpanded] = React.useState(false);

	const shopType = useConfig((s) => s.shopType);
	const prices = useConfig((s) => s.prices);
	const original = useAppearance((s) => s.original);
	const current = useAppearance((s) => s.current);

	const price = shopType ? (prices[shopType] ?? 0) : 0;
	const shopLabelKey = shopType ? `ui.cost_tracker.${shopType}` : "";
	const translatedShopLabel = shopLabelKey ? t(shopLabelKey) : "";
	const shopLabel = shopType ? (translatedShopLabel !== shopLabelKey ? translatedShopLabel : shopType) : null;
	const currencySymbol = t("ui.common.currency_symbol");

	const { details, totalChanges } = useMemo(
		() => countChanges(original, current, t),
		[original, current, t]
	);

	// only show when in a shop with a price
	if (!shopType || price === 0) return null;

	const isFree = totalChanges === 0;

	return (
		<Box className={classes.wrapper}>
			<Box className={classes.header} onClick={() => setExpanded((v) => !v)}>
				<Group spacing={6} noWrap>
					<TbCoin size={14} color={isFree ? "#40c057" : "#fab005"} />
					<Text size="xs" weight={600}>
						{shopLabel}
					</Text>
				</Group>
				<Group spacing={6} noWrap>
					{isFree ? (
						<Text size="xs" weight={600} className={classes.free}>{t("ui.cost_tracker.free")}</Text>
					) : (
						<Badge size="xs" variant="filled" color="yellow" sx={{ textTransform: "none" }}>
							{currencySymbol}{price.toLocaleString()}
						</Badge>
					)}
					{details.length > 0 && (
						expanded ? <TbChevronUp size={12} /> : <TbChevronDown size={12} />
					)}
				</Group>
			</Box>

			<Collapse in={expanded && details.length > 0}>
				<Box className={classes.details}>
					{details.map((d) => (
						<Box key={d.label} className={classes.row}>
							<Text size={11} color="dimmed">{d.label}</Text>
							<Tooltip label={t("ui.cost_tracker.change_count", d.count)} position="left" transition="pop">
								<Badge size="xs" variant="light" color="blue">{d.count}</Badge>
							</Tooltip>
						</Box>
					))}
					<Box className={classes.row} sx={{ borderTop: "1px solid", borderColor: "dark.5", marginTop: 2, paddingTop: 4 }}>
						<Text size={11} weight={600}>{t("ui.cost_tracker.total_cost")}</Text>
						<Text size="xs" weight={700} color="yellow">
							{currencySymbol}{price.toLocaleString()}
						</Text>
					</Box>
				</Box>
			</Collapse>
		</Box>
	);
};

export default CostTracker;
