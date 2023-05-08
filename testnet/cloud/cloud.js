const { exec } = require('child_process');
const { log } = require('./utils');
const Settings = require('./settings.json');

const [environmentName = 'local'] = process.argv.slice(2);

const { ServicePort, DashboardPort, HttpHost, WebsocketHost } =
	Settings[environmentName];

log(
	'environment',
	`Initializing Sonic Testnet Cloud
- Service Port: ${ServicePort}
- Dashboard Port: ${DashboardPort}
- Http Host: ${HttpHost}
- Websocket Host: ${WebsocketHost}
`
);

const dashboard = exec(
	`cd dashboard && yarn && VITE_HTTP_HOST=${HttpHost} VITE_WEBSOCKET_HOST=${WebsocketHost} yarn build && npx serve dist -l ${DashboardPort}`
);
dashboard.stdout.on('data', (data) => log('dashboard', data));
dashboard.stderr.on('data', (data) => log('dashboard', data));
dashboard.on('close', (code) =>
	log('dashboard', `child process exited with code ${code}`)
);

const service = exec(`cd service && yarn && yarn start ${ServicePort}`);
service.stdout.on('data', (data) => log('service', data));
service.stderr.on('data', (data) => log('service', data));
service.on('close', (code) =>
	log('service', `child process exited with code ${code}`)
);
