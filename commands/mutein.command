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
	return `Keeps the bot from reacting to anything posted in the given channel. \
					\nTo allow it again, simply use this command on the same channel again. \
					\nUsage: \`${config.prefix}${command} [#channel-name]\``;
}

// Command logic:
exports.call = (args, info) => {

	if(!info.message.guild) {
		return "There are no channels in DMs.";
	}

	if(args.length === 0) {
		return "You'll have to give me a channel to mute.";
	}

	// Get the channel object from the argument.
	var channel_name = args[0];
	var channel = undefined;

	// If it's a channel link, get the object and name.
	if(channel_name.indexOf("<") === 0) {
		channel_name = args[0].replace("#", "").replace("<", "").replace(">", "");
		channel = info.message.guild.channels.get(channel_name);
		if(channel) {
			channel_name = channel.name;
		}
	}
	// If it's a plaintext channel name, find the channel object from there.
	else {
		channel_name = args[0].replace("#", "");
		channel = info.message.guild.channels.find("name", channel_name);
	}


	if(!channel) {
		return `There is no \`#${channel_name}\` channel.`;
	}

	// Store the mute property toggle.
	var channel_mem = info.memory.channels[channel.id];
	if(!channel_mem.muted_in) {
		channel_mem.muted_in = true;
		return `Muted myself in <#${channel.id}>.`;
	} else {
		delete channel_mem.muted_in;
		return `Unmuted myself in <#${channel.id}>.`;
	}

}