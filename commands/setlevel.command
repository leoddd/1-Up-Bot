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
exports.level = "staff";

// Help function:
exports.help = (config, command, message, core) => {
	return `Sets the authority level of the given command to the given value, eg. "all", "staff" or "admin". \
					\nUsage: \`${config.prefix}${command} say staff\``;
}

// Command logic:
exports.call = (args, info) => {

	// Complain if lacking info.
	if(args.length < 2) {
		return "You have to give me both a command and an authority level to set it to.";
	}

	// Check if the command exists and can be overwritten by the current users' level.
	var command_to_change = args[0];

	if(!info.core.hasCommand(command_to_change)) {
		return `Command \`${command_to_change}\` does not exist.`;
	}
	if(!info.core.hasCommandPermission(command_to_change, info.message)) {
		return `You do not have the authority to change \`${command_to_change}\`'s level.`;
	}

	// Check if this is a valid level to set it to.
	var new_level = args[1];

	if(["all", "staff", "admin"].indexOf(new_level) === -1) {
		return `\`${new_level}\` is not a valid authority level.`;
	}
	if(!info.core.hasLevel(new_level, info.message)) {
		return `You can't set command \`${command_to_change}\` to a level you are not authorized to.`;
	}

	// Create the new level setting.
	var guild_mem = info.memory.guilds[info.message.guild.id];
	if(!guild_mem.hasOwnProperty("command_levels")) {
		guild_mem.command_levels = {};
	}

	// If the new level is the same as the default security level of the given command, just clear the value.
	if(info.core.getCommandDefaultLevel(command_to_change, info.message) === new_level) {
		delete guild_mem.command_levels[command_to_change];
		if(Object.keys(guild_mem.command_levels).length === 0) {
			delete guild_mem.command_levels;
		}
	}
	// If it's not the default level, set it.
	else {
		guild_mem.command_levels[command_to_change] = new_level;
	}

	return `Set level of command \`${command_to_change}\` to \`${new_level}\`.`;
}