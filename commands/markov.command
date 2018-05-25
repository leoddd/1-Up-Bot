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
		return "No markovs in DMs.";
	}

	// Directory for the current guild.
	var flake = info.message.guild.id;
	var guild_temp = info.temp.guilds[flake];
	var markov_data = `${info.core.basePath}${info.config.guilds_dir}${flake}/${info.config.markov_file}`;

	const event_name = `markov_${info.message.guild.id}`;


	// Initialize guild's markov memory if needed.
	if(guild_temp.markov === undefined) {
		guild_temp.markov = {};
	}

	// File exists, so see if we need to read it in.
	// If we haven't started loading yet, start loding.

	if(guild_temp.markov.state === undefined) {

		// If no markov data exists, just exit.
		try {
			fs.accessSync(markov_data, fs.constants.R_OK | fs.constants.W_OK);
		}	catch(err) {
			return "There is no data for me to bungle yet. Say something, anything, that isn't a command.";
		}

		// Begin loading.
		guild_temp.markov.state = LOADING;
		guild_temp.markov.lines = 0;

		var markov_chain = Markov(2);
		guild_temp.markov.object = markov_chain;

		// Start loading and type while doing so.
		info.core.log(`Started loading markov data for guild "${info.message.guild.name}" (id: ${info.message.guild.id}).`, "markov");
		info.message.channel.startTyping();

		// Process part of the markov data set until done.
		var markov_stream = fs.createReadStream(markov_data, {encoding: "utf8", highWaterMark: 8 * 1024});
		var markov_success = true;
		var markov_lines = 0;

		markov_stream.on('data', (chunk) => {
			// Feed line by line.
			var lines = chunk.split("\n");
			lines.some(line => {
				markov_chain.seed(line);
				markov_lines += 1;
				if(markov_lines >= info.config.markov_data_limit) {
					markov_stream.destroy();
					return true;
				}
			});
		});

		// If there's an error, end here.
		markov_stream.on('error', (err) => {
			guild_temp.markov.state = undefined;
			guild_temp.markov.object = undefined;
			guild_temp.markov.lines = undefined;
			info.message.channel.send("Failed when trying to load the markov set. Oops!");
			info.core.log(`Failed to load the markov data for guild "${info.message.guild.name}" (id: ${info.message.guild.id}). Error: ${err}`, "error");
			info.core.removeAllListeners(event_name);

			markov_success = false;
		});

		// When we finished reading it in and didn't fail, call this command again.
		markov_stream.on('close', () => {
			info.message.channel.stopTyping();
			if(markov_success === true) {
				guild_temp.markov.state = READY;
				guild_temp.markov.lines = markov_lines;
				info.core.log(`Markov data for guild "${info.message.guild.name}" (id: ${info.message.guild.id}) is ready.`, "markov");
				
				info.core.emit(event_name);
			}
		});
	}



	//////
	// Executing logic.

	// If it is currently loading, try to call this command again when the data is loaded.
	if(guild_temp.markov.state === LOADING) {

		info.core.once(event_name, () => {
			info.core.callCommand(info.command, args, info.message);
		});
		return;

	}
	// If it is already loaded, just call the markov!
	else if(guild_temp.markov.state === READY) {

		var markov_response = undefined;
		var markov_chain = guild_temp.markov.object;

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

		// If there is a valid markov response, print it.
		if(markov_response.length !== 0) {
			var self_nick = info.core.getCurrentName(info.bot.user, info.message.guild);
			var author_nick = info.core.getCurrentName(info.message.author, info.message.guild);

			markov_response = markov_response.join(" ")
			.substring(0, info.config.markov_max_length)
			.replace(new RegExp(self_nick.toLowerCase(), 'g'), author_nick.toLowerCase())
			.replace(new RegExp(self_nick, 'gi'), author_nick)
			.replace(/\s+/g, " ")
			.trim();

			if(info.config.markov_output_pings === false) {
				markov_response = markov_response.replace(/\<\@.*?\>/g, `<@${info.message.author.id}>`);
			}

			return markov_response;
		} else {
			return "I have failed you, mother. I could not create the response you wished for. Punish me for my sins.";
		}

	}

}