import { isEnvBrowser } from "./misc";

interface DebugEvent<T = any> {
	action: string;
	data: T;
}

/**
 * emulates dispatching an event using SendNuiMessage in the lua scripts.
 * this is used when developing in browser
 *
 * @param events - the event you want to cover
 * @param timer - how long until it should trigger (ms)
 */
export const debugData = <P>(events: DebugEvent<P>[], timer = 1000): void => {
	if (process.env.NODE_ENV === "development" && isEnvBrowser()) {
		for (const event of events) {
			setTimeout(() => {
				window.dispatchEvent(
					new MessageEvent("message", {
						data: {
							action: event.action,
							data: event.data,
						},
					})
				);
			}, timer);
		}
	}
};