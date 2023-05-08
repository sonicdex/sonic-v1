exports.log = (type, data) =>
	console.log(`[${type}][${new Date().toLocaleString()}]\n${data}`);
