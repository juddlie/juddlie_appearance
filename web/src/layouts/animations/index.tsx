import React, { useEffect, useState } from "react";
import { Box, ScrollArea, Stack, Text, SegmentedControl, Switch, Group, UnstyledButton, createStyles } from "@mantine/core";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { useConfig } from "../../store/config";
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
	emoteBtn: {
		padding: "8px 12px",
		backgroundColor: theme.colors.dark[7],
		textAlign: "center",
		transition: "background-color 150ms",
		"&:hover": { backgroundColor: theme.colors.dark[6] },
	},
	emoteBtnActive: {
		backgroundColor: theme.colors.dark[6],
		color: theme.colors[theme.primaryColor][4],
		borderLeft: `2px solid ${theme.colors[theme.primaryColor][5]}`,
	},
}));

const Animations: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const animations = useConfig((s) => s.animations);
	const [activeAnim, setActiveAnim] = useState<string>("");

	useEffect(() => {
		if (!activeAnim && animations[0]?.value) {
			setActiveAnim(animations[0].value);
		}
	}, [activeAnim, animations]);

	const handlePlay = (anim: string) => {
		setActiveAnim(anim);
		fetchNui("appearance:playAnimation", { animation: anim });
	};

	return (
		<Box className={classes.container}>
			<Text size="lg" weight={700}>{t("ui.animations.title")}</Text>
			<Text size="xs" color="dimmed">{t("ui.animations.description")}</Text>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={8}>
					<PanelCard>
						<SectionHeader>{t("ui.animations.movement")}</SectionHeader>
						<Stack spacing={4}>
							{animations.map((anim) => (
								<UnstyledButton
									key={anim.value}
									className={cx(classes.emoteBtn, activeAnim === anim.value && classes.emoteBtnActive)}
									onClick={() => handlePlay(anim.value)}
								>
									<Group position="apart">
										<Text size="xs" weight={600}>{anim.label}</Text>
										<Text size={10} color="dimmed">{anim.desc}</Text>
									</Group>
								</UnstyledButton>
							))}
						</Stack>
					</PanelCard>
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Animations;
