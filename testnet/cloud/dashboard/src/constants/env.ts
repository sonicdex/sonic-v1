export const env = {
  httpHost: import.meta.env.VITE_HTTP_HOST || 'http://localhost:3232',
  websocketHost: import.meta.env.VITE_WEBSOCKET_HOST || 'ws://localhost:3232',
};
