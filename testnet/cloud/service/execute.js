import { exec } from 'child_process';
import { serverLog } from './server.js';

export const execute = (command) =>
	new Promise((resolve, reject) => {
		exec(command, (error, stdout, stderr) => {
			if (error) {
				serverLog('execute', `[error][${command}]\n${error}`);
				return reject(error);
			}

			if (stderr && !stdout) {
				serverLog('execute', `[stderr][${command}]\n${stderr}`);
				return reject(stderr);
			}

			serverLog('execute', `[stdout][${command}]\n${stdout}`);
			return resolve(stdout);
		});
	});
