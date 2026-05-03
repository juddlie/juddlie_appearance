import React, { useEffect, useState, useMemo } from "react";
import {
	Box, ScrollArea, Stack, Text, SegmentedControl, Group,
	UnstyledButton, Badge, createStyles,
} from "@mantine/core";
import { TbCheck } from "react-icons/tb";
import { PanelCard } from "../../components/Shared";
import { useConfig } from "../../store/config";
import { useAppearance } from "../../store/appearance";
import { fetchNui } from "../../utils/fetchNui";
import { useLocale } from "../../store/locale";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
	styleBtn: {
		width: "100%",
		padding: "8px 12px",
		transition: "background-color 150ms",
		"&:hover": { backgroundColor: theme.colors.dark[6] },
	},
	styleBtnActive: {
		backgroundColor: theme.colors.dark[6],
		color: theme.colors[theme.primaryColor][4],
		borderLeft: `2px solid ${theme.colors[theme.primaryColor][5]}`,
		"&:hover": {
			color: theme.colors[theme.primaryColor][3],
		},
	},
}));

const WalkStyle: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const walkStyles = useConfig((s) => s.walkStyles);
	const walkStyleCategories = useConfig((s) => s.walkStyleCategories);
	const walkStyle = useAppearance((s) => s.current.walkStyle);
	const setWalkStyle = useAppearance((s) => s.setWalkStyle);
	const [category, setCategory] = useState("");
	const allCategory = walkStyleCategories[0]?.value || "";

	useEffect(() => {
		if (!category || !walkStyleCategories.some((item) => item.value === category)) {
			setCategory(allCategory);
		}
	}, [allCategory, category, walkStyleCategories]);

	const filtered = useMemo(() => {
		if (!category || category === allCategory) return walkStyles;
		return walkStyles.filter((s: any) => s.category === category);
	}, [walkStyles, category, allCategory]);

	const categoryLabelMap = useMemo(() => {
		return walkStyleCategories.reduce<Record<string, string>>((acc, item: any) => {
			acc[item.value] = item.label;
			return acc;
		}, {});
	}, [walkStyleCategories]);

	const handleSelect = (value: string) => {
		setWalkStyle(value);
		fetchNui("appearance:setWalkStyle", { walkStyle: value });
	};

	return (
		<Box className={classes.container}>
			<Text size="lg" weight={700}>{t("ui.walkstyle.title")}</Text>
			<Text size="xs" color="dimmed">{t("ui.walkstyle.description")}</Text>

			<ScrollArea type="never" sx={{ maxWidth: "100%" }}>
				<SegmentedControl
					size="xs"
					value={category}
					onChange={setCategory}
					data={walkStyleCategories.map((c: any) => ({ value: c.value, label: c.label }))}
				/>
			</ScrollArea>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<PanelCard>
					<Stack spacing={4}>
						{filtered.map((style: any) => {
							const isActive = (walkStyle || walkStyles[0]?.value || "") === style.value;
							return (
								<UnstyledButton
									key={style.value}
									className={cx(classes.styleBtn, isActive && classes.styleBtnActive)}
									onClick={() => handleSelect(style.value)}
								>
									<Group position="apart" noWrap>
										<Group spacing={8} noWrap>
											<Text size="xs" weight={600}>{style.label}</Text>
											{categoryLabelMap[style.category] && (
												<Badge size="xs" variant="light" color="gray">
													{categoryLabelMap[style.category]}
												</Badge>
											)}
										</Group>
										{isActive && <TbCheck size={14} />}
									</Group>
								</UnstyledButton>
							);
						})}
					</Stack>
				</PanelCard>
			</ScrollArea>
		</Box>
	);
};

export default WalkStyle;
