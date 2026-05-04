import React, { useState, useMemo } from "react";
import {
	Box, ScrollArea, Stack, Text, TextInput, Badge, Group, Button,
	ActionIcon, Modal, Textarea, Tooltip, createStyles, UnstyledButton,
} from "@mantine/core";
import { TbSearch, TbTrash, TbDownload, TbUpload, TbCopy, TbPlus } from "react-icons/tb";

import { usePresets } from "../../store/presets";
import { useAppearance } from "../../store/appearance";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";
import { useLocale } from "../../store/locale";
import { useConfig } from "../../store/config";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
	grid: {
		display: "flex",
		flexWrap: "wrap" as const,
		gap: 8,
	},
	presetCard: {
		width: "calc(50% - 4px)",
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		padding: 10,
		cursor: "pointer",
		transition: "background-color 150ms, border-color 150ms",
		border: `1px solid ${theme.colors.dark[5]}`,
		"&:hover": {
			backgroundColor: theme.colors.dark[6],
			borderColor: theme.colors[theme.primaryColor][5],
		},
	},
	presetCardActive: {
		borderColor: theme.colors[theme.primaryColor][5],
		backgroundColor: theme.colors.dark[6],
	},
}));

const Presets: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const share = useConfig((s) => s.share);
	const [importModal, setImportModal] = useState(false);
	const [importJson, setImportJson] = useState("");
	const [nameModal, setNameModal] = useState(false);
	const [newName, setNewName] = useState("");
	const [newTags, setNewTags] = useState("");

	const presets = usePresets((s) => s.presets);
	const searchQuery = usePresets((s) => s.searchQuery);
	const setSearchQuery = usePresets((s) => s.setSearchQuery);
	const addPreset = usePresets((s) => s.addPreset);
	const removePreset = usePresets((s) => s.removePreset);
	const hoveredPreset = usePresets((s) => s.hoveredPreset);
	const setHoveredPreset = usePresets((s) => s.setHoveredPreset);
	const importPresets = usePresets((s) => s.importPresets);
	const exportPresets = usePresets((s) => s.exportPresets);

	const current = useAppearance((s) => s.current);
	const setAppearance = useAppearance((s) => s.setAppearance);

	const filtered = useMemo(() => {
		if (!searchQuery) return presets;
		const q = searchQuery.toLowerCase();
		return presets.filter(
			(p) => p.name.toLowerCase().includes(q) || p.tags.some((t) => t.toLowerCase().includes(q))
		);
	}, [presets, searchQuery]);

	const copyToClipboard = (text: string) => {
		navigator.clipboard.writeText(text).catch(() => {});
	};

	const handleSavePreset = () => {
		const preset = {
			id: `preset-${Date.now()}`,
			name: newName || t("ui.presets.untitled"),
			tags: newTags.split(",").map((t) => t.trim()).filter(Boolean),
			data: JSON.parse(JSON.stringify(current)),
			createdAt: Date.now(),
			shareCode: btoa(JSON.stringify(current)).slice(0, share.codeLength ?? 0),
		};

		addPreset(preset);
		fetchNui("appearance:savePreset", preset);

		setNameModal(false);
		setNewName("");
		setNewTags("");
	};

	const handleApplyPreset = (presetId: string) => {
		const preset = presets.find((p) => p.id === presetId);
		if (preset) {
			setAppearance(preset.data);
			fetchNui("appearance:applyPreset", preset.data);
		}
	};

	const handleExport = () => {
		const json = exportPresets();
		copyToClipboard(json);
	};

	const handleImport = () => {
		importPresets(importJson);
		setImportModal(false);
		setImportJson("");
	};

	return (
		<Box className={classes.container}>
			<Group position="apart">
				<Text size="lg" weight={700}>{t("ui.presets.title")}</Text>
				<Group spacing={4}>
					<Tooltip label={t("ui.presets.save_current_look")} transition="pop">
						<ActionIcon size="xs" variant="light" onClick={() => setNameModal(true)}>
							<TbPlus size={12} />
						</ActionIcon>
					</Tooltip>
					<Tooltip label={t("ui.presets.export_all")} transition="pop">
						<ActionIcon size="xs" variant="subtle" onClick={handleExport}>
							<TbUpload size={12} />
						</ActionIcon>
					</Tooltip>
					<Tooltip label={t("ui.common.import")} transition="pop">
						<ActionIcon size="xs" variant="subtle" onClick={() => setImportModal(true)}>
							<TbDownload size={12} />
						</ActionIcon>
					</Tooltip>
				</Group>
			</Group>

			<TextInput
				size="xs"
				placeholder={t("ui.presets.search_placeholder")}
				icon={<TbSearch size={14} />}
				value={searchQuery}
				onChange={(e) => setSearchQuery(e.currentTarget.value)}
			/>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				{filtered.length === 0 ? (
					<PanelCard>
						<Text size="xs" color="dimmed" align="center" py={24}>
							{t("ui.presets.empty")}
						</Text>
					</PanelCard>
				) : (
					<Box className={classes.grid}>
						{filtered.map((preset) => (
							<UnstyledButton
								key={preset.id}
								className={cx(
									classes.presetCard,
									hoveredPreset === preset.id && classes.presetCardActive
								)}
								onClick={() => handleApplyPreset(preset.id)}
							>
								<Text size="xs" weight={600} lineClamp={1}>{preset.name}</Text>
								<Group spacing={4} mt={4}>
									{preset.tags.slice(0, 2).map((tag) => (
										<Badge key={tag} size="xs" variant="light">{tag}</Badge>
									))}
								</Group>
								{preset.shareCode && (
									<Group spacing={4} mt={4}>
										<Text size={10} color="dimmed">{preset.shareCode}</Text>
										<ActionIcon
											size={14}
											variant="subtle"
											onClick={(e: React.MouseEvent) => {
												e.stopPropagation();
											copyToClipboard(preset.shareCode || "");
											}}
										>
											<TbCopy size={10} />
										</ActionIcon>
									</Group>
								)}
								<ActionIcon
									size="xs"
									variant="subtle"
									color="red"
									sx={{ position: "absolute", top: 4, right: 4 }}
									onClick={(e: React.MouseEvent) => {
										e.stopPropagation();
										removePreset(preset.id);
										fetchNui("appearance:deletePreset", preset.id);
									}}
								>
									<TbTrash size={10} />
								</ActionIcon>
							</UnstyledButton>
						))}
					</Box>
				)}
			</ScrollArea>

			<Modal opened={nameModal} onClose={() => setNameModal(false)} title={t("ui.presets.save_preset")} centered size="sm">
				<Stack spacing={8}>
					<TextInput size="xs" label={t("ui.common.name")} value={newName} onChange={(e) => setNewName(e.currentTarget.value)} placeholder={t("ui.presets.name_placeholder")} />
					<TextInput size="xs" label={t("ui.presets.tags_label")} value={newTags} onChange={(e) => setNewTags(e.currentTarget.value)} placeholder={t("ui.presets.tags_placeholder")} />
					<Button size="xs" variant="light" onClick={handleSavePreset} fullWidth>{t("ui.common.save")}</Button>
				</Stack>
			</Modal>

			<Modal opened={importModal} onClose={() => setImportModal(false)} title={t("ui.presets.import_presets")} centered size="sm">
				<Stack spacing={8}>
					<Textarea size="xs" label={t("ui.presets.json")} value={importJson} onChange={(e) => setImportJson(e.currentTarget.value)} minRows={4} placeholder={t("ui.presets.json_placeholder")} />
					<Button size="xs" variant="light" onClick={handleImport} fullWidth>{t("ui.common.import")}</Button>
				</Stack>
			</Modal>
		</Box>
	);
};

export default Presets;
