import React, { useEffect, useMemo } from "react";
import {
	Box, ScrollArea, Stack, Text, Badge, Group, Button, ActionIcon,
	Tooltip, createStyles, Image,
} from "@mantine/core";
import { TbGift, TbEye, TbEyeOff, TbDownload } from "react-icons/tb";

import { useDrops, Drop } from "../../store/drops";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { fetchNui } from "../../utils/fetchNui";
import { makeSignatureSvg } from "../../utils/signature";
import { useLocale } from "../../store/locale";
import { useConfig } from "../../store/config";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1, minHeight: 0, minWidth: 0, display: "flex", flexDirection: "column",
		padding: 12, gap: 8, overflow: "hidden",
	},
	scrollInner: {
		paddingRight: 6,
		paddingBottom: 8,
	},
	card: {
		boxSizing: "border-box",
		overflow: "hidden",
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		padding: 10,
		border: `1px solid ${theme.colors.dark[5]}`,
	},
	previewActive: { borderColor: theme.colors.yellow[6] },
}));

function formatRemaining(endsAt: number | null | undefined, t: (key: string, ...args: (string | number)[]) => string): string {
	if (!endsAt) return "";

	const ms = endsAt - Date.now();
	if (ms <= 0) return t("ui.drops.expired");

	const days = Math.floor(ms / 86400000);
	if (days > 0) return t("ui.drops.days", days);

	const hours = Math.floor(ms / 3600000);
	if (hours > 0) return t("ui.drops.hours", hours);

	return t("ui.drops.minutes", Math.floor(ms / 60000));
}

const Drops: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const dropTierColors = useConfig((s) => s.dropTierColors);
	const drops = useDrops((s) => s.drops);
	const setDrops = useDrops((s) => s.setDrops);
	const loading = useDrops((s) => s.loading);
	const setLoading = useDrops((s) => s.setLoading);
	const previewId = useDrops((s) => s.previewId);
	const setPreviewId = useDrops((s) => s.setPreviewId);

	useEffect(() => {
		setLoading(true);
		fetchNui("appearance:fetchDrops", {});

		return () => {
			if (previewId) fetchNui("appearance:endDropPreview", {});
		};
	}, []);

	useNuiEvent("dropsList", (data: { drops: Drop[] }) => {
		setDrops(data.drops || []);
	});

	useNuiEvent("dropClaimResult", (data: { ok: boolean }) => {
		if (data.ok) fetchNui("appearance:fetchDrops", {});
	});

	const togglePreview = (d: Drop) => {
		if (previewId === d.id) {
			fetchNui("appearance:endDropPreview", {});
			setPreviewId(null);
		} else {
			fetchNui("appearance:previewDrop", { id: d.id, data: d.data });
			setPreviewId(d.id);
		}
	};

	const claim = (d: Drop) => fetchNui("appearance:claimDrop", { id: d.id });

	return (
		<Box className={classes.container}>
			<Group spacing={6}>
				<TbGift size={18} />
				<Text size="lg" weight={700}>{t("ui.drops.title")}</Text>
			</Group>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }} type="auto" scrollbarSize={8}>
				<Stack spacing={6} className={classes.scrollInner}>
					{drops.length === 0 ? (
						<Text size="xs" color="dimmed" align="center" py={24}>
							{loading ? t("ui.actions.loading") : t("ui.drops.no_drops")}
						</Text>
					) : (
						drops.map((d) => {
							const thumb = makeSignatureSvg(d, { seed: d.id });
							const isPreview = previewId === d.id;
							const remaining = formatRemaining(d.endsAt, t);
							return (
								<Box key={d.id} className={cx(classes.card, isPreview && classes.previewActive)}>
									<Group spacing={8} align="flex-start" noWrap>
										<Image src={thumb} width={48} height={48} radius="sm" fit="cover" withPlaceholder />
										<Stack spacing={2} sx={{ flex: 1, minWidth: 0 }}>
											<Group position="apart" spacing={4} noWrap>
												<Text size="xs" weight={600} lineClamp={1}>{d.name}</Text>
												<Badge size="xs" color={dropTierColors[d.tier] || "gray"}>{d.tier}</Badge>
											</Group>
											{d.description && (
												<Text size={10} color="dimmed" lineClamp={2}>{d.description}</Text>
											)}
											{remaining && (
												<Text size={10} color="dimmed">{t("ui.drops.ends_in", remaining)}</Text>
											)}
										</Stack>
									</Group>
									<Group spacing={4} mt={6} position="right">
										<Tooltip label={isPreview ? t("ui.drops.stop_preview") : t("ui.drops.preview")}>
											<ActionIcon
												size="sm" variant="light"
												color={isPreview ? "yellow" : "blue"}
												onClick={() => togglePreview(d)}
											>
												{isPreview ? <TbEyeOff size={12} /> : <TbEye size={12} />}
											</ActionIcon>
										</Tooltip>
										{d.claimable && (
											<Button
												size="xs" variant="light" color="green"
												leftIcon={<TbDownload size={12} />}
												onClick={() => claim(d)}
											>{t("ui.drops.claim")}</Button>
										)}
									</Group>
								</Box>
							);
						})
					)}
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Drops;
