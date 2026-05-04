import { useEffect, useRef } from "react";
import { noop } from "../utils/misc";
import { fetchNui } from "../utils/fetchNui";

type FrameVisibleSetter = (bool: boolean) => void;

const listenedKeys = ["Escape"];

export const useExitListener = (visibleSetter: FrameVisibleSetter, cb?: () => void) => {
	const setterRef = useRef<FrameVisibleSetter>(noop);

	useEffect(() => {
		setterRef.current = visibleSetter;
	}, [visibleSetter]);

	useEffect(() => {
		const keyHandler = (e: KeyboardEvent) => {
			if (listenedKeys.includes(e.code)) {
				setterRef.current(false);

				cb && cb()

				fetchNui("appearance:exit", {});
			}
		};

		window.addEventListener("keyup", keyHandler);

		return () => window.removeEventListener("keyup", keyHandler);
	}, []);
};