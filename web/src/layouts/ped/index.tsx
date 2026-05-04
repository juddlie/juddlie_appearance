import React, { useState, useMemo } from "react";
import { Box, ScrollArea, Stack, Text, TextInput, UnstyledButton, Badge, createStyles, useMantineTheme } from "@mantine/core";
import { TbSearch, TbCheck } from "react-icons/tb";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";
import { useLocale } from "../../store/locale";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		minWidth: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
	header: {
		display: "flex",
		alignItems: "center",
		justifyContent: "space-between",
	},
	modelItem: {
		display: "flex",
		alignItems: "center",
		justifyContent: "space-between",
		padding: "8px 10px",
		transition: "background-color 150ms",
		"&:hover": {
			backgroundColor: theme.colors.dark[6],
		},
	},
	modelItemActive: {
		backgroundColor: theme.colors.dark[6],
		borderLeft: `2px solid ${theme.colors[theme.primaryColor][5]}`,
	},
}));

const Ped: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const [search, setSearch] = useState("");

	const pedModels = useConfig((s) => s.pedModels);
	const currentModel = useAppearance((s) => s.current.model);
	const setModel = useAppearance((s) => s.setModel);

	const accentColor = useMantineTheme().primaryColor;

	const filteredModels = useMemo(() => {
		if (!search) return pedModels;
		const lower = search.toLowerCase();
		return pedModels.filter(
			(m) => m.label.toLowerCase().includes(lower) || m.value.toLowerCase().includes(lower)
		);
	}, [search, pedModels]);

	const handleSelectModel = (model: string) => {
		setModel(model);
		fetchNui("appearance:setModel", { model });
	};

	return (
		<Box className={classes.container}>
			<Box className={classes.header}>
				<Text size="lg" weight={700}>{t("ui.ped.title")}</Text>
				<Badge size="sm" variant="filled">{pedModels.length}</Badge>
			</Box>

			<TextInput
				size="xs"
				placeholder={t("ui.ped.search_placeholder")}
				icon={<TbSearch size={14} />}
				value={search}
				onChange={(e) => setSearch(e.currentTarget.value)}
			/>

			<ScrollArea sx={{ flex: 1, minHeight: 0, minWidth: 0 }}>
				<Stack spacing={8} sx={{ minWidth: 0, minHeight: 0 }}>
					<PanelCard>
						<SectionHeader>{t("ui.ped.models")}</SectionHeader>
						<Stack spacing={2}>
							{filteredModels.map((model) => {
								const isActive = currentModel === model.value;
								return (
									<UnstyledButton
										key={model.value}
										className={cx(classes.modelItem, isActive && classes.modelItemActive)}
										onClick={() => handleSelectModel(model.value)}
									>
										<Box>
										<Text size="xs" weight={isActive ? 600 : 400} color={isActive ? `${accentColor}.4` : undefined}>
											{model.label}
										</Text>
										<Text size={10} color="dimmed">{model.value}</Text>
									</Box>
									{isActive && <TbCheck size={16} color={`var(--mantine-color-${accentColor}-4)`} />}
									</UnstyledButton>
								);
							})}
							{filteredModels.length === 0 && (
								<Text size="xs" color="dimmed" align="center" py={16}>
									{t("ui.ped.no_models")}
								</Text>
							)}
						</Stack>
					</PanelCard>
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Ped;
