import React, { useState, useMemo } from "react";
import {
	Box, ScrollArea, Stack, Text, Group, Button, ActionIcon,
	Modal, TextInput, Tooltip, Divider, createStyles, UnstyledButton,
} from "@mantine/core";
import {
	TbArrowBack, TbArrowForward, TbBookmark, TbTrash,
	TbHistory, TbPlus, TbClock,
} from "react-icons/tb";

import { useHistory } from "../../store/history";
import { useAppearance } from "../../store/appearance";
import { useLocale } from "../../store/locale";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1, minHeight: 0, display: "flex", flexDirection: "column",
		padding: 12, gap: 8,
	},
	entryBtn: {
		width: "100%", padding: "6px 10px",
		transition: "background-color 150ms",
		"&:hover": { backgroundColor: theme.colors.dark[6] },
	},
	entryBtnActive: {
		backgroundColor: theme.colors.dark[6],
		borderLeft: `2px solid ${theme.colors[theme.primaryColor][5]}`,
		color: theme.colors[theme.primaryColor][4],
	},
	entryBtnFuture: {
		opacity: 0.4,
	},
	snapshotCard: {
		width: "100%", padding: "8px 10px",
		backgroundColor: theme.colors.dark[7], borderRadius: theme.radius.sm,
		cursor: "pointer", position: "relative" as const,
		transition: "background-color 150ms",
		border: `1px solid ${theme.colors.dark[5]}`,
		"&:hover": {
			backgroundColor: theme.colors.dark[6],
			borderColor: theme.colors.violet[5],
		},
	},
}));

function timeAgo(ts: number, t: (key: string, ...args: (string | number)[]) => string): string {
	const diff = Math.floor((Date.now() - ts) / 1000);
	
	if (diff < 5) return t("ui.history.just_now");
	if (diff < 60) return t("ui.history.seconds_ago", diff);
	if (diff < 3600) return t("ui.history.minutes_ago", Math.floor(diff / 60));

	return t("ui.history.hours_ago", Math.floor(diff / 3600));
}

const History: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const [snapModal, setSnapModal] = useState(false);
	const [snapName, setSnapName] = useState("");

	const entries = useHistory((s) => s.entries);
	const currentIndex = useHistory((s) => s.currentIndex);
	const snapshots = useHistory((s) => s.snapshots);
	const undo = useHistory((s) => s.undo);
	const redo = useHistory((s) => s.redo);
	const canUndo = useHistory((s) => s.canUndo);
	const canRedo = useHistory((s) => s.canRedo);
	const saveSnapshot = useHistory((s) => s.saveSnapshot);
	const removeSnapshot = useHistory((s) => s.removeSnapshot);
	const clearHistory = useHistory((s) => s.clearHistory);
	const pushEntry = useHistory((s) => s.pushEntry);

	const current = useAppearance((s) => s.current);
	const setAppearance = useAppearance((s) => s.setAppearance);

	const reversedEntries = useMemo(
		() => entries.map((e, i) => ({ ...e, index: i })).reverse(),
		[entries],
	);

	const handleUndo = () => {
		const data = undo();
		if (data) {
			setAppearance(data);
			fetchNui("appearance:applyPreset", data);
		}
	};

	const handleRedo = () => {
		const data = redo();
		if (data) {
			setAppearance(data);
			fetchNui("appearance:applyPreset", data);
		}
	};

	const handleJumpTo = (index: number) => {
		const entry = entries[index];
		if (!entry) return;
		pushEntry(t("ui.history.jump_to", entry.label), current);
		setAppearance(JSON.parse(JSON.stringify(entry.data)));
		fetchNui("appearance:applyPreset", entry.data);
	};

	const handleSaveSnapshot = () => {
		saveSnapshot(snapName || t("ui.history.snapshot"), current);
		setSnapModal(false);
		setSnapName("");
	};

	const handleApplySnapshot = (id: string) => {
		const snap = snapshots.find((s) => s.id === id);
		if (!snap) return;
		pushEntry(t("ui.history.snapshot_entry", snap.name), current);
		setAppearance(JSON.parse(JSON.stringify(snap.data)));
		fetchNui("appearance:applyPreset", snap.data);
	};

	return (
		<Box className={classes.container}>
			<Group position="apart">
				<Group spacing={6}>
					<TbHistory size={18} />
					<Text size="lg" weight={700}>{t("ui.history.title")}</Text>
				</Group>
				<Group spacing={4}>
					<Tooltip label={t("ui.history.save_snapshot")} transition="pop">
						<ActionIcon size="xs" variant="light" color="violet"
							onClick={() => setSnapModal(true)}>
							<TbPlus size={12} />
						</ActionIcon>
					</Tooltip>
				</Group>
			</Group>

			<Group grow spacing={4}>
				<Button size="xs" variant="light" leftIcon={<TbArrowBack size={14} />}
					disabled={!canUndo()} onClick={handleUndo}>
					{t("ui.history.undo")}
				</Button>
				<Button size="xs" variant="light" leftIcon={<TbArrowForward size={14} />}
					disabled={!canRedo()} onClick={handleRedo}>
					{t("ui.history.redo")}
				</Button>
			</Group>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={8}>
					{snapshots.length > 0 && (
						<PanelCard>
							<SectionHeader>{t("ui.history.snapshots")}</SectionHeader>
							<Stack spacing={4}>
								{snapshots.map((snap) => (
									<UnstyledButton key={snap.id} className={classes.snapshotCard}
										onClick={() => handleApplySnapshot(snap.id)}>
										<Group position="apart" noWrap>
											<Group spacing={6} noWrap>
												<TbBookmark size={12} color="var(--mantine-color-violet-4)" />
												<Text size="xs" weight={600} lineClamp={1}>{snap.name}</Text>
											</Group>
											<Group spacing={4} noWrap>
												<Text size={10} color="dimmed">{timeAgo(snap.timestamp, t)}</Text>
												<ActionIcon size={14} variant="subtle" color="red"
													onClick={(e: React.MouseEvent) => {
														e.stopPropagation();
														removeSnapshot(snap.id);
													}}>
													<TbTrash size={10} />
												</ActionIcon>
											</Group>
										</Group>
									</UnstyledButton>
								))}
							</Stack>
						</PanelCard>
					)}
					<PanelCard>
						<Group position="apart">
							<SectionHeader>{t("ui.history.timeline")}</SectionHeader>
							{entries.length > 0 && (
								<Tooltip label={t("ui.history.clear_history")} transition="pop">
									<ActionIcon size="xs" variant="subtle" color="red" onClick={clearHistory}>
										<TbTrash size={12} />
									</ActionIcon>
								</Tooltip>
							)}
						</Group>
						{entries.length === 0 ? (
							<Text size="xs" color="dimmed" align="center" py={16}>
								{t("ui.history.no_changes_hint")}
							</Text>
						) : (
							<Stack spacing={2}>
								{reversedEntries.map((entry) => {
									const isCurrent = entry.index === currentIndex;
									const isFuture = entry.index > currentIndex;
									return (
										<UnstyledButton key={entry.id}
											className={cx(
												classes.entryBtn,
												isCurrent && classes.entryBtnActive,
												isFuture && classes.entryBtnFuture,
											)}
											onClick={() => handleJumpTo(entry.index)}>
											<Group position="apart" noWrap>
												<Text size="xs" weight={isCurrent ? 600 : 400} lineClamp={1}>
													{entry.label}
												</Text>
												<Group spacing={4} noWrap>
													<TbClock size={10} opacity={0.5} />
													<Text size={10} color="dimmed">{timeAgo(entry.timestamp, t)}</Text>
												</Group>
											</Group>
										</UnstyledButton>
									);
								})}
							</Stack>
						)}
					</PanelCard>
				</Stack>
			</ScrollArea>

			<Modal opened={snapModal} onClose={() => setSnapModal(false)}
				title={t("ui.history.save_snapshot")} centered size="sm">
				<Stack spacing={8}>
					<TextInput size="xs" label={t("ui.common.name")} value={snapName}
						onChange={(e) => setSnapName(e.currentTarget.value)}
						placeholder={t("ui.history.snapshot_placeholder")} />
					<Text size="xs" color="dimmed">
						{t("ui.history.snapshot_hint")}
					</Text>
					<Button size="xs" variant="light" color="violet" onClick={handleSaveSnapshot} fullWidth>
						{t("ui.history.save_snapshot")}
					</Button>
				</Stack>
			</Modal>
		</Box>
	);
};

export default History;
