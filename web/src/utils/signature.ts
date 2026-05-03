// deterministic SVG thumbnail generator.
//
// given any JSON-serializable input we produce an identicon-like SVG that
// is unique to that input. Goal: every outfit/listing/drop gets a distinct
// visual marker without needing an in-game screenshot.
//
// two pieces of information are encoded:
//   1. the 6 dominant colors (sampled from a hash of the data).
//   2. a 5x5 symmetrical grid of filled cells (also hash-derived).

const palette = [
	["#3B82F6", "#60A5FA"], ["#10B981", "#34D399"], ["#F59E0B", "#FBBF24"],
	["#EF4444", "#F87171"], ["#8B5CF6", "#A78BFA"], ["#EC4899", "#F472B6"],
	["#06B6D4", "#22D3EE"], ["#84CC16", "#A3E635"], ["#F97316", "#FB923C"],
	["#6366F1", "#818CF8"], ["#14B8A6", "#2DD4BF"], ["#EAB308", "#FACC15"],
];

function hash(str: string): number {
	let h = 5381;
	for (let i = 0; i < str.length; i++) {
		h = ((h << 5) + h) + str.charCodeAt(i);
		h |= 0;
	}
	return Math.abs(h);
}

export interface SignatureOptions {
	size?: number;
	seed?: string;
}

/**
 * produces an SVG data URL deterministic to the input.
 */
export function makeSignatureSvg(input: unknown, opts: SignatureOptions = {}): string {
	const size = opts.size ?? 96;
	const seed = opts.seed ?? JSON.stringify(input);
	const h = hash(seed);

	const [bg, fg] = palette[h % palette.length];
	const accent = palette[(h >> 4) % palette.length][0];

	const cell = size / 5;
	let cells = "";
	for (let y = 0; y < 5; y++) {
		for (let x = 0; x < 3; x++) {
			const bit = (h >> (x + y * 3)) & 1;
			if (bit) {
				const fill = (x + y) % 2 === 0 ? fg : accent;
				cells += `<rect x="${x * cell}" y="${y * cell}" width="${cell}" height="${cell}" fill="${fill}" rx="2" />`;
				if (x !== 2) {
					cells += `<rect x="${(4 - x) * cell}" y="${y * cell}" width="${cell}" height="${cell}" fill="${fill}" rx="2" />`;
				}
			}
		}
	}

	const svg =
		`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">` +
		`<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">` +
		`<stop offset="0%" stop-color="${bg}" stop-opacity="0.9"/>` +
		`<stop offset="100%" stop-color="${accent}" stop-opacity="0.7"/></linearGradient></defs>` +
		`<rect width="100%" height="100%" fill="url(#g)" />` +
		cells +
		`</svg>`;

	return `data:image/svg+xml;base64,${btoa(unescape(encodeURIComponent(svg)))}`;
}
