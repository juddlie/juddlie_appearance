import React, { useEffect, useState } from "react";
import {
	Box, ScrollArea, Stack, Text, Switch, Button, Group, TextInput,
	Slider, Badge, createStyles,
} from "@mantine/core";
import { TbRefresh, TbLock, TbLockOpen, TbArrowBack, TbPlayerPlay, TbPlayerPause } from "react-icons/tb";
import { useAppearance } from "../../store/appearance";
import { useConfig } from "../../store/config";
import { useLocale } from "../../store/locale";
import { useHistory } from "../../store/history";
import { SectionHeader, PanelCard } from "../../components/Shared";
import { fetchNui } from "../../utils/fetchNui";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1,
		minHeight: 0,
		display: "flex",
		flexDirection: "column",
		padding: 12,
		gap: 8,
	},
	lockRow: {
		display: "flex",
		alignItems: "center",
		justifyContent: "space-between",
		padding: "6px 8px",
		borderRadius: theme.radius.sm,
		"&:hover": { backgroundColor: theme.colors.dark[6] },
	},
}));

const Randomizer: React.FC = () => {
	const { classes } = useStyles();
	const t = useLocale((s) => s.t);
	const randomizerCategories = useConfig((s) => s.randomizerCategories);
	const randomizerDefaultSpeed = useConfig((s) => s.randomizerDefaultSpeed);
	const randomizerSpeedRange = useConfig((s) => s.randomizerSpeedRange);
	const [autoplay, setAutoplay] = useState(false);
	const [speed, setSpeed] = useState(0);

	const locks = useAppearance((s) => s.locks);
	const setLock = useAppearance((s) => s.setLock);
	const current = useAppearance((s) => s.current);
	const pushEntry = useHistory((s) => s.pushEntry);

	useEffect(() => {
		setSpeed(randomizerDefaultSpeed);
	}, [randomizerDefaultSpeed]);

	const handleRandomize = () => {
		pushEntry("Randomize", current);
		const unlockedCategories = randomizerCategories.filter((c) => !locks[c.key as keyof typeof locks]).map((c) => c.key);
		fetchNui("appearance:randomize", { categories: unlockedCategories });
	};

	const handleUndo = () => {
		fetchNui("appearance:revert", {});
	};

	const toggleAutoplay = () => {
		const next = !autoplay;
		setAutoplay(next);
		fetchNui("appearance:autoRandomize", { enabled: next, speed, locks });
	};

	return (
		<Box className={classes.container}>
			<Text size="lg" weight={700}>{t("ui.randomizer.title")}</Text>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }}>
				<Stack spacing={8}>
					<PanelCard>
						<SectionHeader>{t("ui.randomizer.lock_categories")}</SectionHeader>
						<Text size={10} color="dimmed" mb={4}>{t("ui.randomizer.lock_hint")}</Text>
						<Stack spacing={2}>
						{randomizerCategories.map((cat) => (
							<Box key={cat.key} className={classes.lockRow}>
								<Group spacing={8}>
									{locks[cat.key as keyof typeof locks] ? <TbLock size={14} /> : <TbLockOpen size={14} />}
									<Text size="xs">{cat.label}</Text>
								</Group>
								<Switch
									size="xs"
									checked={locks[cat.key as keyof typeof locks]}
									onChange={(e) => setLock(cat.key as keyof typeof locks, e.currentTarget.checked)}

									/>
								</Box>
							))}
						</Stack>
					</PanelCard>

					<PanelCard>
						<SectionHeader>{t("ui.randomizer.generate")}</SectionHeader>
						<Stack spacing={8}>
							<Button
								fullWidth
								size="xs"
								variant="light"
								leftIcon={<TbRefresh size={14} />}
								onClick={handleRandomize}
							>
								{t("ui.randomizer.randomize")}
							</Button>
							<Button
								fullWidth
								size="xs"
								variant="subtle"
								color="gray"
								leftIcon={<TbArrowBack size={14} />}
								onClick={handleUndo}
							>
								{t("ui.history.undo")}
							</Button>
						</Stack>
					</PanelCard>

					<PanelCard>
						<SectionHeader>{t("ui.randomizer.cycle_until_liked")}</SectionHeader>
						<Group spacing={8} mb={8}>
							<Text size="xs" color="dimmed">{t("ui.randomizer.speed_seconds")}</Text>
							<Slider
								sx={{ flex: 1 }}
								size="xs"
								min={randomizerSpeedRange.min}
								max={randomizerSpeedRange.max}
								step={randomizerSpeedRange.step}
								value={speed}
								onChange={setSpeed}
								label={(v) => `${v}s`}
							/>
						</Group>
						<Button
							fullWidth
							size="xs"
							variant={autoplay ? "filled" : "light"}
							color={autoplay ? "red" : undefined}
							leftIcon={autoplay ? <TbPlayerPause size={14} /> : <TbPlayerPlay size={14} />}
							onClick={toggleAutoplay}
						>
							{autoplay ? t("ui.randomizer.stop") : t("ui.randomizer.start_cycling")}
						</Button>
					</PanelCard>
				</Stack>
			</ScrollArea>
		</Box>
	);
};

export default Randomizer;
