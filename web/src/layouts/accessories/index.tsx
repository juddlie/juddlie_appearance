import React, { useState, useMemo } from "react";
import {
	Box, ScrollArea, Stack, Text, TextInput, Group, Button,
	ActionIcon, Modal, Tooltip, createStyles, UnstyledButton, Badge,
} from "@mantine/core";
import {
	TbSearch, TbTrash, TbPlus, TbDeviceWatch, TbCheck,
} from "react-icons/tb";

import { useAccessories } from "../../store/accessories";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { useLocale } from "../../store/locale";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";
import type { AccessorySet } from "../../types/accessory";
import type { ClothingComponent, PropData } from "../../types/appearance";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1, minHeight: 0, display: "flex", flexDirection: "column",
		padding: 12, gap: 8,
	},
	grid: { display: "flex", flexWrap: "wrap" as const, gap: 8 },
	card: {
		width: "calc(50% - 4px)", backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm, padding: 10, cursor: "pointer",
		transition: "background-color 150ms, border-color 150ms",
		border: `1px solid ${theme.colors.dark[5]}`, position: "relative" as const,
		"&:hover": {
			backgroundColor: theme.colors.dark[6],
			borderColor: theme.colors[theme.primaryColor][5],
		},
	},
	currentSection: {
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		padding: 10,
	},
	accessoryItem: {
		display: "flex", alignItems: "center", justifyContent: "space-between",
		padding: "4px 8px", borderRadius: theme.radius.sm,
		"&:hover": { backgroundColor: theme.colors.dark[6] },
	},
}));

function extractAccessories(clothing: ClothingComponent[], props: PropData[], accessoryComponentIds: number[]) {
	const accessoryComponentSet = new Set<number>(accessoryComponentIds);
	return {
		clothing: clothing.filter((c) => accessoryComponentSet.has(c.component)),
		props: [...props],
	};
}

function getAccessorySummary(
	clothing: ClothingComponent[],
	props: PropData[],
	componentLabels: Record<number, string>,
	propLabels: Record<number, string>,
	t: (key: string, ...args: (string | number)[]) => string,
): string {
	const parts: string[] = [];
	clothing.forEach((c) => {
		if (c.drawable > 0) parts.push(componentLabels[c.component] || t("ui.clothing.component"));
	});
	props.forEach((p) => {
		if (p.drawable >= 0) parts.push(propLabels[p.prop] || t("ui.props.slot", p.prop));
	});
	return parts.length > 0 ? parts.join(", ") : t("ui.accessories.none_equipped");
}

const Accessories: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);
	const [saveModal, setSaveModal] = useState(false);
	const [newName, setNewName] = useState("");
	const accessoryComponentIds = useConfig((s) => s.accessoryComponentIds);
	const componentLabels = useConfig((s) => s.componentLabels);
	const propLabels = useConfig((s) => s.propLabels);

	const sets = useAccessories((s) => s.sets);
	const searchQuery = useAccessories((s) => s.searchQuery);
	const setSearchQuery = useAccessories((s) => s.setSearchQuery);
	const addSet = useAccessories((s) => s.addSet);
	const removeSet = useAccessories((s) => s.removeSet);

	const current = useAppearance((s) => s.current);

	const currentAccessories = useMemo(
		() => extractAccessories(current.clothing, current.props, accessoryComponentIds),
		[current.clothing, current.props, accessoryComponentIds],
	);

	const filtered = useMemo(() => {
		if (!searchQuery) return sets;
		const q = searchQuery.toLowerCase();
		return sets.filter((s) => s.name.toLowerCase().includes(q));
	}, [sets, searchQuery]);

	const handleSave = () => {
		const acc: AccessorySet = {
			id: `acc-${Date.now()}`,
			name: newName || t("ui.accessories.untitled_set"),
			clothing: JSON.parse(JSON.stringify(currentAccessories.clothing)),
			props: JSON.parse(JSON.stringify(currentAccessories.props)),
			createdAt: Date.now(),
		};
		addSet(acc);
		fetchNui("appearance:saveAccessorySet", acc);
		setSaveModal(false);
		setNewName("");
	};

	const handleApply = (setId: string) => {
		const set = sets.find((s) => s.id === setId);
		if (!set) return;
		fetchNui("appearance:applyAccessorySet", { clothing: set.clothing, props: set.props });
	};

	const handleDelete = (e: React.MouseEvent, setId: string) => {
		e.stopPropagation();
		removeSet(setId);
		fetchNui("appearance:deleteAccessorySet", setId);
	};

	return (
		<Box className={classes.container}>
			<Group position="apart">
				<Group spacing={6}>
					<TbDeviceWatch size={18} />
					<Text size="lg" weight={700}>{t("ui.accessories.title")}</Text>
				</Group>
				<Tooltip label={t("ui.accessories.save_current")} transition="pop">
					<ActionIcon size="xs" variant="light" onClick={() => setSaveModal(true)}>
						<TbPlus size={12} />
					</ActionIcon>
				</Tooltip>
			</Group>

			<Text size="xs" color="dimmed">
				{t("ui.accessories.description")}
			</Text>

			{/* Current accessories summary */}
			<PanelCard>
				<SectionHeader>{t("ui.accessories.currently_equipped")}</SectionHeader>
				<Stack spacing={2}>
					{currentAccessories.clothing.map((c) => (
						<Box key={`c-${c.component}`} className={classes.accessoryItem}>
							<Group spacing={6} noWrap>
								<Badge size="xs" variant="light" color="blue">
									{componentLabels[c.component] || t("ui.clothing.component")}
								</Badge>
								<Text size="xs">
									{c.drawable > 0 ? t("ui.accessories.item_value", c.drawable, c.texture) : t("ui.accessories.none")}
								</Text>
							</Group>
						</Box>
					))}
					{currentAccessories.props.map((p) => (
						<Box key={`p-${p.prop}`} className={classes.accessoryItem}>
							<Group spacing={6} noWrap>
								<Badge size="xs" variant="light" color="violet">
									{propLabels[p.prop] || t("ui.props.slot", p.prop)}
								</Badge>
								<Text size="xs">
									{p.drawable >= 0 ? t("ui.accessories.item_value", p.drawable, p.texture) : t("ui.accessories.none")}
								</Text>
							</Group>
						</Box>
					))}
				</Stack>
			</PanelCard>

			<SectionHeader>{t("ui.accessories.saved_sets")}</SectionHeader>

			<TextInput size="xs" placeholder={t("ui.accessories.search_placeholder")}
				icon={<TbSearch size={14} />} value={searchQuery}
				onChange={(e) => setSearchQuery(e.currentTarget.value)} />

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				{filtered.length === 0 ? (
					<PanelCard>
						<Text size="xs" color="dimmed" align="center" py={24}>
							{t("ui.accessories.none_saved")}
						</Text>
					</PanelCard>
				) : (
					<Box className={classes.grid}>
						{filtered.map((set) => (
							<UnstyledButton key={set.id} className={classes.card}
								onClick={() => handleApply(set.id)}>
								<Text size="xs" weight={600} lineClamp={1}>{set.name}</Text>
								<Text size={10} color="dimmed" mt={2} lineClamp={1}>
									{getAccessorySummary(set.clothing, set.props, componentLabels, propLabels, t)}
								</Text>
								<ActionIcon size={16} variant="subtle" color="red"
									sx={{ position: "absolute", top: 4, right: 4 }}
									onClick={(e: React.MouseEvent) => handleDelete(e, set.id)}>
									<TbTrash size={10} />
								</ActionIcon>
							</UnstyledButton>
						))}
					</Box>
				)}
			</ScrollArea>

			<Modal opened={saveModal} onClose={() => setSaveModal(false)}
				title={t("ui.accessories.save_set")} centered size="sm">
				<Stack spacing={8}>
					<TextInput size="xs" label={t("ui.common.name")} value={newName}
						onChange={(e) => setNewName(e.currentTarget.value)}
						placeholder={t("ui.accessories.name_placeholder")} />
					<Text size="xs" color="dimmed">
						{t("ui.accessories.saves", getAccessorySummary(currentAccessories.clothing, currentAccessories.props, componentLabels, propLabels, t))}
					</Text>
					<Button size="xs" variant="light" onClick={handleSave} fullWidth>{t("ui.common.save")}</Button>
				</Stack>
			</Modal>
		</Box>
	);
};

export default Accessories;
