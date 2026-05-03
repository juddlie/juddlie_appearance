import React, { useState, useMemo, useCallback, useEffect } from "react";
import {
	Box, ScrollArea, Stack, Text, SegmentedControl, Badge,
	Group, ActionIcon, TextInput, createStyles,
} from "@mantine/core";
import { TbTrash, TbPlus, TbSearch, TbX, TbArrowLeft } from "react-icons/tb";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { useLocale } from "../../store/locale";
import type { TattooData } from "../../types";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
	tattooItem: {
		display: "flex",
		alignItems: "center",
		padding: "6px 8px",
		borderRadius: theme.radius.sm,
		gap: 8,
		"&:hover": { backgroundColor: theme.colors.dark[6] },
	},
}));

const Tattoos: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);
	const tattooZones = useConfig((s) => s.tattooZones);
	const [zone, setZone] = useState("");
	const [search, setSearch] = useState("");
	const [browsing, setBrowsing] = useState(false);
	const [available, setAvailable] = useState<TattooData[]>([]);

	const tattoos = useAppearance((s) => s.current.tattoos);
	const addTattoo = useAppearance((s) => s.addTattoo);
	const removeTattoo = useAppearance((s) => s.removeTattoo);
	const clearTattoos = useAppearance((s) => s.clearTattoos);

	useEffect(() => {
		if (!zone || !tattooZones.some((item) => item.value === zone)) {
			setZone(tattooZones[0]?.value || "");
		}
	}, [tattooZones, zone]);

	useNuiEvent<{ zone: string; tattoos: TattooData[] }>("tattooList", (data) => {
		if (data?.tattoos) {
			setAvailable(data.tattoos);
			setBrowsing(true);
		}
	});

	const zoneTattoos = useMemo(() => {
		return tattoos.filter((t) => t.zone === zone && (!search || t.label.toLowerCase().includes(search.toLowerCase())));
	}, [tattoos, zone, search]);

	const allZoneTattoos = useMemo(() => tattoos.filter((t) => t.zone === zone), [tattoos, zone]);

	const filteredAvailable = useMemo(() => {
		const applied = new Set(tattoos.map((t) => `${t.collection}:${t.overlay}`));
		return available.filter((t) =>
			!applied.has(`${t.collection}:${t.overlay}`) &&
			(!search || t.label.toLowerCase().includes(search.toLowerCase()))
		);
	}, [available, tattoos, search]);

	const handleAdd = () => {
		fetchNui("appearance:browseTattoos", { zone });
	};

	const handleSelectTattoo = useCallback((tattoo: TattooData) => {
		addTattoo(tattoo);
		fetchNui("appearance:addTattoo", { collection: tattoo.collection, overlay: tattoo.overlay });
	}, [addTattoo]);

	const handleRemove = useCallback((collection: string, overlay: string) => {
		removeTattoo(collection, overlay);
		const remaining = tattoos.filter((t) => !(t.collection === collection && t.overlay === overlay));
		fetchNui("appearance:reapplyTattoos", remaining);
	}, [removeTattoo, tattoos]);

	const handleClearAll = () => {
		clearTattoos();
		fetchNui("appearance:clearTattoos", {});
	};

	const handleBack = () => {
		setBrowsing(false);
		setSearch("");
	};

	return (
		<Box className={classes.container}>
			<Group position="apart">
				<Group spacing={4}>
					{browsing && (
						<ActionIcon size="xs" variant="subtle" onClick={handleBack}>
							<TbArrowLeft size={14} />
						</ActionIcon>
					)}
					<Text size="lg" weight={700}>{browsing ? t("ui.tattoos.browse_title") : t("ui.tattoos.title")}</Text>
				</Group>
				<Group spacing={4}>
					<Badge size="xs" variant="light">{t("ui.tattoos.total", tattoos.length)}</Badge>
					{!browsing && (
						<ActionIcon size="xs" variant="subtle" color="red" onClick={handleClearAll}>
							<TbX size={12} />
						</ActionIcon>
					)}
				</Group>
			</Group>

			{!browsing && (
				<SegmentedControl
					fullWidth
					size="xs"
					value={zone}
					onChange={(v) => setZone(v)}
					data={tattooZones.map((z) => ({ value: z.value, label: z.label }))}
				/>
			)}

			<TextInput
				size="xs"
				placeholder={browsing ? t("ui.tattoos.search_available") : t("ui.tattoos.search_placeholder")}
				icon={<TbSearch size={14} />}
				value={search}
				onChange={(e) => setSearch(e.currentTarget.value)}
			/>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={4}>
					{browsing ? (
						<PanelCard>
							<SectionHeader>{t("ui.tattoos.available", filteredAvailable.length)}</SectionHeader>
							{filteredAvailable.length === 0 ? (
								<Text size="xs" color="dimmed" align="center" py={16}>
									{t("ui.tattoos.no_available")}
								</Text>
							) : (
								<Stack spacing={2}>
									{filteredAvailable.map((tattoo, idx) => (
										<Box key={`${tattoo.collection}-${tattoo.overlay}-${idx}`} className={classes.tattooItem}>
											<Text size="xs" sx={{ flex: 1 }}>{tattoo.label}</Text>
											<Text size={10} color="dimmed">{tattoo.collection}</Text>
											<ActionIcon size="xs" variant="light" onClick={() => handleSelectTattoo(tattoo)}>
												<TbPlus size={12} />
											</ActionIcon>
										</Box>
									))}
								</Stack>
							)}
						</PanelCard>
					) : (
						<PanelCard>
							<Group position="apart" mb={4}>
								<SectionHeader>{t("ui.tattoos.zone_count", tattooZones.find((z) => z.value === zone)?.label || "", allZoneTattoos.length)}</SectionHeader>
								<ActionIcon size="xs" variant="light" onClick={handleAdd}>
									<TbPlus size={12} />
								</ActionIcon>
							</Group>

							{zoneTattoos.length === 0 ? (
								<Text size="xs" color="dimmed" align="center" py={16}>
									{t("ui.tattoos.no_applied")}
								</Text>
							) : (
								<Stack spacing={2}>
									{zoneTattoos.map((tattoo, idx) => (
										<Box key={`${tattoo.collection}-${tattoo.overlay}-${idx}`} className={classes.tattooItem}>
											<Text size="xs" sx={{ flex: 1 }}>{tattoo.label || tattoo.overlay}</Text>
											<Text size={10} color="dimmed">{tattoo.collection}</Text>
											<ActionIcon size="xs" variant="subtle" color="red" onClick={() => handleRemove(tattoo.collection, tattoo.overlay)}>
												<TbTrash size={12} />
											</ActionIcon>
										</Box>
									))}
								</Stack>
							)}
						</PanelCard>
					)}
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Tattoos;
