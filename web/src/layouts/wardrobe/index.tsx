import React, { useEffect, useMemo, useState } from "react";
import {
	Box, ScrollArea, Stack, Text, Group, Button, ActionIcon,
	Tooltip, createStyles, Image, Modal, TextInput,
} from "@mantine/core";
import { TbHanger, TbDeviceFloppy, TbTrash, TbHandClick } from "react-icons/tb";

import { useWardrobe, WardrobeSlot } from "../../store/wardrobe";
import { useAppearance } from "../../store/appearance";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { fetchNui } from "../../utils/fetchNui";
import { makeSignatureSvg } from "../../utils/signature";
import { useLocale } from "../../store/locale";

const useStyles = createStyles((theme) => ({
	container: {
		flex: 1, minHeight: 0, minWidth: 0, display: "flex", flexDirection: "column",
		padding: 12, gap: 8, overflow: "hidden",
	},
	scrollInner: {
		paddingRight: 6,
		paddingBottom: 8,
	},
	slot: {
		boxSizing: "border-box",
		overflow: "hidden",
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		padding: 10,
		border: `1px solid ${theme.colors.dark[5]}`,
		display: "flex",
		alignItems: "center",
		gap: 10,
	},
	emptySlot: {
		opacity: 0.55,
	},
}));

const Wardrobe: React.FC = () => {
	const { classes, cx } = useStyles();
	const t = useLocale((s) => s.t);
	const slots = useWardrobe((s) => s.slots);
	const maxSlots = useWardrobe((s) => s.maxSlots);
	const setSlots = useWardrobe((s) => s.setSlots);
	const current = useAppearance((s) => s.current);

	const [saveTarget, setSaveTarget] = useState<number | null>(null);
	const [slotName, setSlotName] = useState("");

	useEffect(() => {
		fetchNui("appearance:fetchWardrobe", {});
	}, []);

	useNuiEvent("wardrobeSlots", (data: { slots: WardrobeSlot[]; maxSlots: number }) => {
		setSlots(data.slots || [], data.maxSlots || 0);
	});

	const slotMap = useMemo(() => {
		const m: Record<number, WardrobeSlot> = {};
		slots.forEach((s) => { m[s.slot] = s; });
		return m;
	}, [slots]);

	const handleSave = () => {
		if (saveTarget === null) return;
		const data = {
			clothing: JSON.parse(JSON.stringify(current.clothing)),
			props: JSON.parse(JSON.stringify(current.props)),
			tattoos: current.tattoos ? JSON.parse(JSON.stringify(current.tattoos)) : [],
		};
		fetchNui("appearance:saveWardrobeSlot", {
			slot: saveTarget,
			name: slotName || t("ui.wardrobe.slot", saveTarget),
			data,
		});
		
		setTimeout(() => fetchNui("appearance:fetchWardrobe", {}), 200);
		setSaveTarget(null);
		setSlotName("");
	};

	const apply = (slot: number) => fetchNui("appearance:applyWardrobeSlot", { slot });
	const clear = (slot: number) => {
		fetchNui("appearance:deleteWardrobeSlot", { slot });
		setTimeout(() => fetchNui("appearance:fetchWardrobe", {}), 200);
	};

	const slotIndices = Array.from({ length: maxSlots }, (_, i) => i + 1);

	return (
		<Box className={classes.container}>
			<Group spacing={6}>
				<TbHanger size={18} />
				<Text size="lg" weight={700}>{t("ui.wardrobe.title")}</Text>
			</Group>
			<Text size="xs" color="dimmed">
				{t("ui.wardrobe.description")}
			</Text>

			<ScrollArea sx={{ flex: 1, minHeight: 0 }} type="auto" scrollbarSize={8}>
				<Stack spacing={6} className={classes.scrollInner}>
					{slotIndices.map((idx) => {
						const filled = slotMap[idx];
						const thumb = filled
							? makeSignatureSvg(filled.data, { seed: `slot-${idx}` })
							: makeSignatureSvg({ empty: idx }, { seed: `empty-${idx}` });
						return (
							<Box key={idx} className={cx(classes.slot, !filled && classes.emptySlot)}>
								<Image src={thumb} width={40} height={40} radius="sm" fit="cover" withPlaceholder />
								<Stack spacing={0} sx={{ flex: 1, minWidth: 0 }}>
									<Text size="xs" weight={600} lineClamp={1}>
										{t("ui.wardrobe.slot", idx)}
									</Text>
									<Text size={10} color="dimmed" lineClamp={1}>
										{filled ? filled.name : t("ui.wardrobe.empty")}
									</Text>
								</Stack>
								<Group spacing={4}>
									{filled && (
										<Tooltip label={t("ui.wardrobe.apply")}>
											<ActionIcon size="sm" variant="light" color="blue" onClick={() => apply(idx)}>
												<TbHandClick size={12} />
											</ActionIcon>
										</Tooltip>
									)}
									<Tooltip label={filled ? t("ui.wardrobe.overwrite_current") : t("ui.wardrobe.save_current")}>
										<ActionIcon
											size="sm" variant="light" color="green"
												onClick={() => { setSaveTarget(idx); setSlotName(filled?.name || t("ui.wardrobe.slot", idx)); }}
										>
											<TbDeviceFloppy size={12} />
										</ActionIcon>
									</Tooltip>
									{filled && (
										<Tooltip label={t("ui.wardrobe.clear")}>
											<ActionIcon size="sm" variant="light" color="red" onClick={() => clear(idx)}>
												<TbTrash size={12} />
											</ActionIcon>
										</Tooltip>
									)}
								</Group>
							</Box>
						);
					})}
				</Stack>
			</ScrollArea>

			<Modal
				opened={saveTarget !== null}
				onClose={() => setSaveTarget(null)}
				title={t("ui.wardrobe.save_to_slot", saveTarget || 0)}
				centered size="sm"
			>
				<Stack spacing={8}>
					<TextInput
						size="xs" label={t("ui.common.name")}
						value={slotName}
						onChange={(e) => setSlotName(e.currentTarget.value)}
						placeholder={t("ui.wardrobe.default_placeholder")}
					/>
					<Button size="xs" variant="light" onClick={handleSave} fullWidth>{t("ui.common.save")}</Button>
				</Stack>
			</Modal>
		</Box>
	);
};

export default Wardrobe;
