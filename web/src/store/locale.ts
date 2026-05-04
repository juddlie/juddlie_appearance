import create from "zustand";

interface LocaleState {
  strings: Record<string, string>;
  locale: string;
  setLocale: (locale: string) => void;
  setStrings: (strings: Record<string, string>) => void;
  t: (key: string, ...args: (string | number)[]) => string;
}

export const useLocale = create<LocaleState>((set, get) => ({
  strings: {},
  locale: "en",

  setLocale: (locale) => set({ locale }),

  setStrings: (strings) => set({ strings }),

  t: (key: string, ...args: (string | number)[]) => {
    const { strings } = get();
    let value = strings[key] || key;

    if (args.length > 0) {
      args.forEach((arg, i) => {
        value = value.replace(/%[sd]/, String(arg));
      });
    }

    return value;
  },
}));
