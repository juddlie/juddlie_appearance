import type { MantineThemeOverride, Tuple } from "@mantine/core";

const mantineColors = [
	"dark", "gray", "red", "pink", "grape", "violet", "indigo",
	"blue", "cyan", "teal", "green", "lime", "yellow", "orange",
];

function parseColor(input: string): [number, number, number] | null {
	const hex = input.trim();

	// hex: #RGB, #RRGGBB
	const hexMatch = hex.match(/^#?([0-9a-f]{3,8})$/i);
	if (hexMatch) {
		let h = hexMatch[1];
		if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
		if (h.length >= 6) {
			return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
		}
	}

	// rgb(R, G, B) or rgba(R, G, B, A)
	const rgbMatch = hex.match(/^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})/i);
	if (rgbMatch) {
		return [Number(rgbMatch[1]), Number(rgbMatch[2]), Number(rgbMatch[3])];
	}

	return null;
}

function clamp(v: number): number {
	return Math.max(0, Math.min(255, Math.round(v)));
}

function mix(a: number, b: number, t: number): number {
	return clamp(a + (b - a) * t);
}

function rgbToHex(r: number, g: number, b: number): string {
	return "#" + [r, g, b].map((c) => clamp(c).toString(16).padStart(2, "0")).join("");
}

/**
 * generates a 10-shade palette from a single color.
 * shade 6 = the input color (mantine's default primary shade).
 */
function generatePalette(r: number, g: number, b: number): Tuple<string, 10> {
	// shades 0-5: mix toward white (lighter), shade 6 = base, shades 7-9: mix toward black (darker)
	const lightSteps = [0.92, 0.82, 0.7, 0.54, 0.36, 0.18];
	const darkSteps = [0.15, 0.3, 0.45];

	const palette: string[] = [];

	for (const t of lightSteps) {
		palette.push(rgbToHex(mix(r, 255, t), mix(g, 255, t), mix(b, 255, t)));
	}

	palette.push(rgbToHex(r, g, b)); // shade 6

	for (const t of darkSteps) {
		palette.push(rgbToHex(mix(r, 0, t), mix(g, 0, t), mix(b, 0, t)));
	}

	return palette as unknown as Tuple<string, 10>;
}

export const customColorKey = "accent";

export interface AccentColorResult {
	/** the color key to use as primaryColor */
	primaryColor: string;
	/** extra colors to merge into the theme (only set for custom colors) */
	colors?: MantineThemeOverride["colors"];
}

/**
 * resolves an accent color value (mantine name, hex, or rgb) into theme config.
 */
export function resolveAccentColor(value: string): AccentColorResult {
	const trimmed = value.trim().toLowerCase();

	if (mantineColors.includes(trimmed)) {
		return { primaryColor: trimmed };
	}

	const rgb = parseColor(value);
	if (rgb) {
		return {
			primaryColor: customColorKey,
			colors: { [customColorKey]: generatePalette(...rgb) },
		};
	}

	return { primaryColor: "blue" };
}
