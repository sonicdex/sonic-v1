import express from 'express';
import { execute } from './execute.js';
import { resetReplica, startReplica } from './server.js';
class HttpHandler {
	constructor(handler, validator) {
		this.handler = handler;
		this.validator = validator;
	}

	handle = async (request, response) => {
		try {
			if (this.validator) await this.validator(request);
			const result = await this.handler(request);
			response.statusCode = 200;
			response.send(result);
		} catch (err) {
			console.log('err', err);
			response.statusCode = 500;
			response.send(err.message || err);
		}
	};
}

const BaseCommand = {
	'canister-ids': ['get', 'cd ../../ && make canister-ids'],
	ping: ['get', 'cd ../../ && dfx ping'],
	'root-buckets': ['get', 'cd ../../ && make root-buckets'],
};

const SpecialCommand = {
	addUser: (principal) => `cd ../../ && make add-user PRINCIPAL=${principal}`,
};

export const httpApp = express();

httpApp.use(express.json());
httpApp.use(function (req, res, next) {
	// Website you wish to allow to connect
	res.setHeader('Access-Control-Allow-Origin', '*');

	// Request methods you wish to allow
	res.setHeader(
		'Access-Control-Allow-Methods',
		'GET, POST, OPTIONS, PUT, PATCH, DELETE'
	);

	// Request headers you wish to allow
	res.setHeader(
		'Access-Control-Allow-Headers',
		'X-Requested-With,content-type'
	);

	// Set to true if you need the website to include cookies in the requests sent
	// to the API (e.g. in case you use sessions)
	res.setHeader('Access-Control-Allow-Credentials', true);

	// Pass to next layer of middleware
	next();
});

Object.entries(BaseCommand).forEach(([endpoint, [method, command]]) => {
	httpApp[method](
		`/${endpoint}`,
		new HttpHandler(async () => execute(command)).handle
	);
});

httpApp.post(
	'/add-user',
	new HttpHandler(
		async (req) => execute(SpecialCommand.addUser(req.body?.principal)),
		// Validation
		async (req) => {
			const principal = req.body?.principal;
			if (typeof principal !== 'string') {
				throw new Error('Invalid principal');
			}
		}
	).handle
);

httpApp.post(
	'/full-deploy',
	new HttpHandler(async () => {
		resetReplica();
		return 'Full deploy successful triggered';
	}).handle
);

httpApp.post(
	'/start',
	new HttpHandler(async () => {
		startReplica();
		return 'Start successful triggered';
	}).handle
);
