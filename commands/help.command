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
exports.help = (config, command, message, core) => {
	var commands_string = "";
	var by_levels = {};

	// Separate commands into their authority levels.
	var commands = core.listCommands();
	commands.forEach(command => {
		if(core.hasCommandPermission(command, message)) {

			var cur_level = core.getCommandLevel(command, message);
			if(!by_levels[cur_level]) {
				by_levels[cur_level] = [];
			}

			by_levels[cur_level].push(command);
		}
	});

	// Loop through authority levels.
	var order = ["all", "staff", "admin"];
	order.forEach(level => {

		if(core.hasLevel(level, message)) {
			commands_string = `${commands_string}\n\n__${capitalizeFirstLetter(level)} Commands:__\n`;
			by_levels[level].sort();

			by_levels[level].forEach(cur_command => {
				commands_string = `${commands_string}\`${cur_command}\`, `;
			});
			commands_string = commands_string.slice(0, -2);
		}

	});

	return `This command will give you information about every command I know.\nUsage: \`${config.prefix}${command} [command name]\`${commands_string}`;
}

// Command logic:
exports.call = (args, info) => {

	// If the command is called blank, explain it.
	if(args.length === 0) {
		return info.core.getHelpString(info.command, info.message);
	}

	// If the command exists, get its help and check if it had any.
	if(info.core.hasCommand(args[0])) {
		var help_string = info.core.getHelpString(args[0], info.message);

		if(help_string && help_string !== "") {
			return help_string;
		} else {
			return `There is no help available for the \`${args[0]}\` command, oops!`;
		}

	}

	else {
		return `There is no \`${args[0]}\` command.`;
	}

}

function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}