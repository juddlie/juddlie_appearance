import React from "react";
import {
	Box, Group, Text, Slider, NumberInput, ActionIcon, Select,
	UnstyledButton, createStyles, ColorSwatch as MantineColorSwatch,
} from "@mantine/core";
import { TbEye, TbEyeOff, TbChevronUp, TbChevronDown, TbSettings, TbMinus, TbPlus } from "react-icons/tb";

const useSliderStyles = createStyles((theme) => ({
	root: {
		display: "flex",
		alignItems: "center",
		gap: 6,
		padding: "4px 0",
	},
	label: {
		fontSize: 11,
		color: theme.colors.dark[1],
		width: 70,
		flexShrink: 0,
		whiteSpace: "nowrap" as const,
		overflow: "hidden",
		textOverflow: "ellipsis",
	},
	slider: {
		flex: 1,
		minWidth: 0,
	},
	stepBtn: {
		flexShrink: 0,
		color: theme.colors.dark[1],
		"&:hover": { color: theme.white, backgroundColor: theme.colors.dark[6] },
	},
	tail: {
		fontSize: 10,
		color: theme.colors.dark[2],
		width: 34,
		flexShrink: 0,
		textAlign: "right" as const,
		whiteSpace: "nowrap" as const,
	},
}));

interface ValueSliderProps {
	label: string;
	value: number;
	onChange: (value: number) => void;
	min?: number;
	max?: number;
	step?: number;
	precision?: number;
}

export const ValueSlider: React.FC<ValueSliderProps> = ({
	label, value, onChange, min = -1, max = 1, step = 0.01, precision = 2,
}) => {
	const { classes } = useSliderStyles();
	return (
		<Box className={classes.root}>
			<Text className={classes.label}>{label}</Text>
			<Slider
				className={classes.slider}
				value={value}
				onChange={onChange}
				min={min}
				max={max}
				step={step}
				size="xs"
				label={(v) => v.toFixed(precision)}
			/>
			<ActionIcon size="xs" className={classes.stepBtn} onClick={() => onChange(Math.max(min, value - step))}>
				<TbMinus size={10} />
			</ActionIcon>
			<ActionIcon size="xs" className={classes.stepBtn} onClick={() => onChange(Math.min(max, value + step))}>
				<TbPlus size={10} />
			</ActionIcon>
			<NumberInput
				value={value}
				onChange={(v) => v !== undefined && onChange(Math.max(min, Math.min(max, v)))}
				min={min}
				max={max}
				step={step}
				precision={precision}
				size="xs"
				hideControls
				sx={{ width: 54, flexShrink: 0 }}
			/>
			<Box className={classes.tail} />
		</Box>
	);
};

interface IndexSelectorProps {
	label: string;
	value: number;
	onChange: (value: number) => void;
	max: number;
	min?: number;
}

export const IndexSelector: React.FC<IndexSelectorProps> = ({ label, value, onChange, max, min = 0 }) => {
	const { classes } = useSliderStyles();
	return (
		<Box className={classes.root}>
			<Text className={classes.label}>{label}</Text>
			<Slider
				className={classes.slider}
				value={value}
				onChange={(v) => onChange(Math.round(v))}
				min={min}
				max={max}
				step={1}
				size="xs"
				label={(v) => String(Math.round(v))}
			/>
			<ActionIcon size="xs" className={classes.stepBtn} onClick={() => onChange(Math.max(min, value - 1))}>
				<TbMinus size={10} />
			</ActionIcon>
			<ActionIcon size="xs" className={classes.stepBtn} onClick={() => onChange(Math.min(max, value + 1))}>
				<TbPlus size={10} />
			</ActionIcon>
			<NumberInput
				value={value}
				onChange={(v) => v !== undefined && onChange(Math.max(min, Math.min(max, v)))}
				min={min}
				max={max}
				step={1}
				size="xs"
				hideControls
				sx={{ width: 54, flexShrink: 0 }}
			/>
			<Text className={classes.tail}>/ {String(max).padStart(3, "0")}</Text>
		</Box>
	);
};

interface DropdownSelectorProps {
	label: string;
	value: string;
	onChange: (value: string) => void;
	data: { value: string; label: string }[];
}

export const DropdownSelector: React.FC<DropdownSelectorProps> = ({ label, value, onChange, data }) => (
	<Group spacing={8} noWrap sx={{ padding: "4px 0" }}>
		<Text 
			size="xs" 
			color="dimmed" 
			sx={{ 
				minWidth: 60,
				maxWidth: 70, 
				overflow: "hidden", 
				textOverflow: "ellipsis", 
				whiteSpace: "nowrap" 
			}}
		>
			{label}
		</Text>
		<Select
			size="xs"
			value={value}
			onChange={(v) => v && onChange(v)}
			data={data}
			searchable
			sx={{ flex: 1 }}
		/>
	</Group>
);

const useLayerStyles = createStyles((theme) => ({
	layer: {
		display: "flex",
		alignItems: "center",
		padding: "6px 10px",
		gap: 8,
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		cursor: "grab",
		"&:hover": { backgroundColor: theme.colors.dark[6] },
	},
	layerHidden: {
		opacity: 0.5,
	},
}));

interface LayerItemProps {
	label: string;
	visible: boolean;
	onToggleVisibility: () => void;
	onMoveUp: () => void;
	onMoveDown: () => void;
	onSettings: () => void;
	isFirst: boolean;
	isLast: boolean;
}

export const LayerItem: React.FC<LayerItemProps> = ({
	label, visible, onToggleVisibility, onMoveUp, onMoveDown, onSettings, isFirst, isLast,
}) => {
	const { classes, cx } = useLayerStyles();
	return (
		<Box className={cx(classes.layer, !visible && classes.layerHidden)}>
			<ActionIcon size="xs" variant="subtle" onClick={onToggleVisibility}>
				{visible ? <TbEye size={14} /> : <TbEyeOff size={14} />}
			</ActionIcon>
			<Text size="xs" sx={{ flex: 1 }}>{label}</Text>
			<ActionIcon size="xs" variant="subtle" onClick={onMoveUp} disabled={isFirst}>
				<TbChevronUp size={12} />
			</ActionIcon>
			<ActionIcon size="xs" variant="subtle" onClick={onMoveDown} disabled={isLast}>
				<TbChevronDown size={12} />
			</ActionIcon>
			<ActionIcon size="xs" variant="subtle" onClick={onSettings}>
				<TbSettings size={12} />
			</ActionIcon>
		</Box>
	);
};

const useSwatchStyles = createStyles((theme) => ({
	swatch: {
		cursor: "pointer",
		borderRadius: theme.radius.sm,
		border: `2px solid transparent`,
		transition: "border-color 150ms",
		"&:hover": { borderColor: theme.colors[theme.primaryColor][5] },
	},
	active: {
		borderColor: theme.colors[theme.primaryColor][5],
	},
}));

interface ColorSwatchBtnProps {
	color: string;
	active?: boolean;
	onClick: () => void;
	size?: number;
}

export const ColorSwatchBtn: React.FC<ColorSwatchBtnProps> = ({ color, active, onClick, size = 24 }) => {
	const { classes, cx } = useSwatchStyles();
	return (
		<UnstyledButton onClick={onClick} className={cx(classes.swatch, active && classes.active)}>
			<MantineColorSwatch color={color} size={size} />
		</UnstyledButton>
	);
};

export const SectionHeader: React.FC<{ children: React.ReactNode }> = ({ children }) => (
	<Text size={11} color="dimmed" weight={700} transform="uppercase" sx={{ letterSpacing: 0.5, padding: "8px 0 4px" }}>
		{children}
	</Text>
);

const usePanelStyles = createStyles((theme) => ({
	panel: {
		backgroundColor: theme.colors.dark[7],
		borderRadius: theme.radius.sm,
		padding: 12,
	},
}));

export const PanelCard: React.FC<{ children: React.ReactNode; sx?: any }> = ({ children, sx }) => {
	const { classes } = usePanelStyles();
	return <Box className={classes.panel} sx={sx}>{children}</Box>;
};
