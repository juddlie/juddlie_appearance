import React, { useMemo } from "react";
import ReactDOM from "react-dom";

import { debugData } from "./utils/debugData";
import { MantineProvider } from "@mantine/core";
import { customTheme } from "./theme";
import { isEnvBrowser } from "./utils/misc";
import { fetchNui } from "./utils/fetchNui";
import { HashRouter } from "react-router-dom";
import { ModalsProvider } from "@mantine/modals";
import { useConfig } from "./store/config";
import { resolveAccentColor } from "./utils/accentColor";

import App from "./App";
import "./index.css";

debugData([
  {
    action: "setVisible",
    data: { visible: true },
  },
]);

if (isEnvBrowser()) {
  const root = document.getElementById("root");
  root!.style.backgroundImage = "url('https://i.imgur.com/3pzRj9n.png')";
  root!.style.backgroundSize = "cover";
  root!.style.backgroundRepeat = "no-repeat";
  root!.style.backgroundPosition = "center";
} else {
  fetchNui("ready", {});
}

const Root: React.FC = () => {
  const accentColor = useConfig((s) => s.accentColor);

  const theme = useMemo(() => {
    const { primaryColor, colors } = resolveAccentColor(accentColor);
    return {
      ...customTheme,
      primaryColor,
      ...(colors ? { colors: { ...customTheme.colors, ...colors } } : {}),
    };
  }, [accentColor]);

  return (
    <MantineProvider withNormalizeCSS theme={theme}>
      <ModalsProvider modalProps={{ transition: "slide-up", withinPortal: false }}>
        <HashRouter>
          <App />
        </HashRouter>
      </ModalsProvider>
    </MantineProvider>
  );
};

ReactDOM.render(
  <React.StrictMode>
    <Root />
  </React.StrictMode>,
  document.getElementById("root")
);
