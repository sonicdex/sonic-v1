import { useCallback, useEffect, useMemo, useState } from 'react';
import { env } from '@/constants';
import { AppLog } from '@/utils';

const createClient = (): WebSocket => {
  const ws = new WebSocket(env.websocketHost);
  ws.onopen = () => {
    AppLog.warn(`WebSocket connection opened to ${env.websocketHost}`);
  };
  return ws;
};

export type WebsocketMessage = { id: number; event: MessageEvent<string> };

export type WebsocketClient = {
  messages: WebsocketMessage[];
  clear: () => void;
  state: number;
};

export const useWebsocketClient = (): WebsocketClient => {
  const ws = useMemo<WebSocket>(() => createClient(), []);
  const [messages, setMessages] = useState<WebsocketMessage[]>([]);
  const [state, setState] = useState<number>(ws.readyState);

  const clear = useCallback(() => {
    setMessages([]);
  }, [setMessages]);

  useEffect(() => {
    ws.onmessage = (event) => {
      setMessages([...messages, { event, id: Date.now() }]);
    };
  }, [ws, messages]);

  useEffect(() => {
    const stateChangeCallback = (): void => setState(ws.readyState);
    ws.onclose = stateChangeCallback;
    ws.onerror = stateChangeCallback;
    ws.onopen = stateChangeCallback;
  }, [ws, setState]);

  return { messages, clear, state };
};
