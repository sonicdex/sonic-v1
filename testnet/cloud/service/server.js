import * as http from 'http';
import { exec } from 'child_process';
import { WebSocketServer } from 'ws';
import { httpApp } from './http.js';

// Settings
let port;
let server;
let websocket;

// Server Functions
export const startServer = (serverPort) => {
	port = serverPort;
	server = http.createServer(httpApp);
	websocket = new WebSocketServer({ server });
	websocket.on('listening', () =>
		serverLog('websocket', `Listening on port ${port}`)
	);
	server.listen(port, () => serverLog('server', `Listening on port ${port}`));
};

export const serverLog = (type, data) => {
	const timestamp = new Date().toISOString();
	const message = `[sonic][${type}][${timestamp}]:\n${data}`;
	console.log(message);
	if (websocket) {
		websocket.clients.forEach((client) => {
			client.send(message);
		});
	}
};

export const resetReplica = () => {
	const replica = exec('cd ../.. && make full-deploy');
	replica.stdout.on('data', (data) => serverLog('replica', data));
	replica.stderr.on('data', (data) => serverLog('replica', data));
	replica.on('close', (code) =>
		serverLog('close', `child process exited with code ${code}`)
	);
};

export const startReplica = () => {
	const replica = exec('cd ../.. && make replica-start');
	replica.stdout.on('data', (data) => serverLog('replica', data));
	replica.stderr.on('data', (data) => serverLog('replica', data));
	replica.on('close', (code) =>
		serverLog('close', `child process exited with code ${code}`)
	);
};
