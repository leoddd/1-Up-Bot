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
exports.level = "all";

// Help function:
exports.help = (config, command, message) => {
	return `Make me talk back. If the first word after the command name is a number, I will try to restrain myself to that many words. \
					\nUsage: \`${config.prefix}${command} [optional word limit] [text]\``;
}

// Command logic:
const LOADING = 'loading';
const READY = 'ready';

var fs = require('fs');
var Markov = require('markov');

exports.call = (args, info) => {

	// No response in DMs.
	if(!info.message.guild) {
		return "No markovs in DMs. Who am I supposed to speak after!";
	}

	// Directory for the current guild.
	var flake = info.message.guild.id;
	var markov_data = `${info.core.basePath}${info.config.guilds_dir}${flake}/${info.config.markov_file}`;


	// File exists, so see if we need to read it in.
	// If we haven't started loading yet, start loding.
	if(info.temp.guilds[flake].markov_state === undefined) {

		// If no markov data exists, just exit.
		try {
			fs.accessSync(markov_data, fs.constants.R_OK | fs.constants.W_OK);
		}	catch(err) {
			return "There is no data for me to bungle yet. Say something, anything, that isn't a command.";
		}

		// Begin loading.
		info.temp.guilds[flake].markov_state = LOADING;

		var markov_chain = Markov(2);
		info.temp.guilds[flake].markov_object = markov_chain;

		// Start loading and type while doing so.
		info.core.log(`Started loading for guild "${info.message.guild.name}" (id: ${info.message.guild.id}).`, "markov");
		info.message.channel.startTyping();

		// Callback when the markov has finished reading the data.
		var markov_stream = fs.createReadStream(markov_data);
		markov_chain.seed(markov_stream, () => {
			info.temp.guilds[flake].markov_state = READY;
			info.core.callCommand('markov', args, info.message);
			info.message.channel.stopTyping();
			info.core.log(`Markov data for guild "${info.message.guild.name}" (id: ${info.message.guild.id}) is ready.`, "markov");
		});

	}

	// If it is currently loading, try to call this command again later.
	if(info.temp.guilds[flake].markov_state === LOADING) {
	}
	// If it is already loaded, just call the markov!
	else if(info.temp.guilds[flake].markov_state === READY) {

		var markov_response = undefined;
		var markov_chain = info.temp.guilds[flake].markov_object;

		// First, get the word limit. If the first argument is a number, use that.
		var limit = info.config.markov_default_max_words;

		// If there are arguments, adjust them first.
		if(args.length !== 0) {

			// If first argument is the bots' name or tag, remove it.
			if(args[0] === info.bot.user.username || args[0] === `<@!${info.bot.user.id}>`) {
				args.splice(0, 1);
			}

			// If the first argument then is a number, use it as the limit and remove it.
			if(!isNaN(args[0])) {
				limit = parseInt(args[0]);
				args.splice(0, 1);
			}

		}

		// If no args passed, pick a random key.
		if(args.length === 0) {
			markov_response = markov_chain.forward(markov_chain.pick(), limit / 2);
		}

		// If arguments were passed, respond to it as text.
		else {
			markov_response = markov_chain.respond(args.join(" "), limit / 2);
		}

		if(markov_response.length !== 0) {
			var self_nick = info.core.getCurrentName(info.bot.user, info.message.guild);
			var author_nick = info.core.getCurrentName(info.message.author, info.message.guild);

			return markov_response.join(" ")
				.substring(0, info.config.markov_max_length)
				.replace(new RegExp(self_nick, 'g'), author_nick)
				.replace(new RegExp(self_nick.toLowerCase(), 'g'), author_nick.toLowerCase());
		} else {
			return "I have failed you, mother. I could not create the response you wished for. Punish me for my sins.";
		}

	}

}