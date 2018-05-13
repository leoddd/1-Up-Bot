//////////////////////////////
// Command file for leod's bot.
/////
//
// Needs to export a 'call' function that returns a response object as specified in bot_core.
// function call(args, memory, bot, message, config)
//   args: Arguments passed in by the user, like "m!markov arguments are these words"
//   info: An object with information about the current bot state. Keys:
//     memory: The global memory object the bot posesses. Can be manipulated by returning a "memory" dict in the response.
//     message: Discord.js's Message object. Represents the message that triggered this command, if it is a command.
//     command: The name of the command being called, if it is a command.
//     hook: If set, the command was called through a message hook instead of an explicit command.
//     bot: Discord.js Client object. Represents the bot.
//     config: The config object.
//     core: A subset of bot_core to expose some functions to commands. Is eventEmitter, look at its definition in init() for functions.
//           Pay special attention to the command* helper functions.
//
// Additionally, exports a 'help' function that is to return a help string about how to use the command. It receives the following:
// 	 config: The config object. Useful for prefixes or to check if a functionality is enabled.
//   command: The name of the command being asked for help on.
//   message: Discord.js's Message object. Represents the message that asked for help.
//
// Lastly, exports a "level" string, which denotes the power level needed to use this command.
//  "all" means that anyone can use it.
//  "staff" means that only staff members can use it (if use_hierarchy is true).
//  "admin" means that only the bot owner can use it.
/////

// Level of authority required.
exports.level = "admin";

// Help function:
exports.help = (config, command, message) => {
	return `Makes me post a dump of my current memory, either permanent or temporary. \
					\nUsage: \`${config.prefix}${command} [perm|temp]\``;
}

// Command logic:
exports.call = (args, info) => {

	return info.core.commandSwitch(args, {
		temp: args => {
			var memory = JSON.stringify(cloneSafeJSON(info.temp, 20), null, "\t")

			info.message.channel.send("My temporary memory is attached.", {"file": {
				"name": "temp-memory.json",
				"attachment": Buffer.from(memory),
			}});

			return {"log": memory};
		},
		default: args => {
			var memory = JSON.stringify(cloneSafeJSON(info.memory, 20), null, "\t")

			info.message.channel.send("My memory is attached.", {"file": {
				"name": "main-memory.json",
				"attachment": Buffer.from(memory),
			}});

			return {"log": memory};
		}
	});

}

// Creates and returns a safe-for-stringifying copy of the given Object.
// Taken from https://stackoverflow.com/questions/13594621/
function cloneSafeJSON(obj, depth){
	var undef;
	var refs = []; //reference to cloned objects
	depth = +depth > 0 && +depth || 6; //max recursion level

	var layerNumber = 0; //current layer being checked
	var ret = clone(obj); //start cloning

	//cleanup reference checks
	while(refs.length) {
		delete (refs.shift()).___copied;
	}

	//return the result
	return ret;

	//recursive clone method
	function clone(obj) {
		if (typeof obj == "function") return undef; //no function replication

		// Handle the 3 simple types, and null or undefined
		if (null == obj || "object" != typeof obj) return obj;

		// Handle Date
		if (obj instanceof Date) {
			var copy = new Date();
			copy.setTime(obj.getTime());
			return copy;
		}

		// Handle Array
		if (obj instanceof Array) {
			var copy = [];
			for (var i = 0, len = obj.length; i < len; i++) {
				copy[i] = clone(obj[i]);
			}
			return copy;
		}

		// Handle Object
		if (obj instanceof Object) {
			//max recursion reached
			if (++layerNumber >= depth) {
				layerNumber--;
				return undef;
			}

			//handle circular and duplicate references
			if (obj.___copied) return undef; //already included
			obj.___copied = true;
			refs.push(obj);

			var copy = {};

			//export prototype
			//var m = obj.constructor && obj.constructor.toString().match(/function\s+([^\(]+)/);
			//if (m && m[1]) copy._prototype = m[1];

			//get expected properties from any error
			if (obj instanceof Error) {
				copy.message = obj.message || "Error";
				if (obj.stack) copy.stack = obj.stack;
				if (obj.number) copy.number = obj.number;
				if (obj.description) copy.description = obj.description;
				if (obj.name) copy.name = obj.name;
			}

			for (var attr in obj) {
				if (attr == "___copied") continue;
				if (obj.hasOwnProperty(attr)) copy[attr] = clone(obj[attr]);
			}
			if (obj.prototype) {
				for (var attr in obj.prototype) {
					if (obj.prototype.hasOwnProperty(attr) && typeof obj.prototype[attr] !== 'function') copy[attr] = clone(obj.prototype[attr]);
					delete obj.prototype[attr].___copied; //allow prototypes to be re-scanned
				}
			}
			layerNumber--;
			return copy;
		}

		//throw new Error("Unable to copy obj! Its type isn't supported.");
		console.log("Unable to copy obj! Unsupported type: %s", typeof obj);
		return undef; //unable to clone the object in question
	}
}