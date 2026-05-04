import { MantineThemeOverride } from "@mantine/core";

export const customTheme: MantineThemeOverride = {
	colorScheme: "dark",
	fontFamily: "Montserrat",
	components: {
		Tooltip: {
			defaultProps: {
				transition: "pop",
			},
		},
		Badge: {
			defaultProps: {
				variant: "light",
			},
			styles: {
				root: {
					textTransform: "uppercase" as const,
				},
			},
		},
		Button: {
			styles: {
				root: {
					textTransform: "uppercase" as const,
				},
			},
		},
		Modal: {
			defaultProps: {
				withinPortal: false,
			},
			styles: (theme: any) => ({
				root: {
					position: "absolute" as const,
				},
				overlay: {
					position: "absolute" as const,
					borderRadius: theme.radius.sm,
				},
				inner: {
					position: "absolute" as const,
				},
				body: {
					maxHeight: "calc(100% - 40px)",
					overflowY: "auto" as const,
				},
				content: {
					maxHeight: "calc(100% - 60px)",
				},
			}),
		},
		Tabs: {
			styles: (theme: any) => ({
				tab: {
					"&[data-active]": {
						borderColor: theme.colors[theme.primaryColor][6],
					},
				},
			}),
		},
	},
};
