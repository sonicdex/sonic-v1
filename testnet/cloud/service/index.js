import { startServer } from './server.js';

const [port = 3999] = process.argv.slice(2);

startServer(port);
