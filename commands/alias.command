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
	return `Allows you to \`add\`, \`clear\` and \`list\` command aliases that will trigger existing commands, including any given arguments. \
					\nUsage: \`${config.prefix}${command} add coolfaction join the cool crew\`, \`${config.prefix}${command} clear coolfaction\`, \`${config.prefix}${command} list\``;
}

// Command logic:
exports.call = (args, info) => {

	var guild_mem = info.memory.guilds[info.message.guild.id];

	return info.core.commandSwitch(args, {

		// Adds a new alias using the given name and command structure.
		add: args => {
			// If there is no new command name given, complain.
			if(args.length === 0) {
				return "You need to tell me what to call the new command.";
			}

			// Initialize alias memory if it doesn't exist yet.
			if(!guild_mem.hasOwnProperty("command_aliases")) {
				guild_mem.command_aliases = {};
			}

			// Check if the given command already exists (vanilla or as an alias) already exists.
			var alias_name = args.shift();

			// If so, complain.
			if(info.core.hasCommand(alias_name) || guild_mem.command_aliases.hasOwnProperty(alias_name)) {
				return `\`${alias_name}\` is an existing command or alias already.`;
			}

			// Else, commit to memory and affirm.
			else {
				guild_mem.command_aliases[alias_name] = {"command": args.shift(), "args": args};
				return `Added \`${alias_name}\` as an alias for \`${guild_mem.command_aliases[alias_name].command} ${guild_mem.command_aliases[alias_name].args.join(" ")}\`.`;
			}
		},


		// Clears the alias of the given name.
		clear: args => {
			if(args.length === 0) {
				return "You didn't tell me which alias to clear.";
			}

			var alias_name = args[0];

			// Check if alias even exists.
			if(!guild_mem.command_aliases || !guild_mem.command_aliases[alias_name]) {
				return `\`${alias_name}\` was not an existing alias to begin with.`;
			}

			// Else, remove it from the aliases and affirm.
			else {
				delete guild_mem.command_aliases[alias_name];
				if(Object.keys(guild_mem.command_aliases).length === 0) {
					delete guild_mem.command_aliases;
				}
				return `Removed \`${alias_name}\` from the list of aliases.`;
			}

		},


		// Posts a list of all active aliases and what they stand in for.
		list: () => {
			// If there are aliases set, list them.
			if(guild_mem.command_aliases) {
				var alias_list = Object.keys(guild_mem.command_aliases).sort();
				var alias_num = alias_list.length;
				var return_string = `**Found ${alias_num} alias${alias_num > 1 ? "es" : ""}:**`;

				alias_list.forEach(cur_alias_name => {
					var cur_alias = guild_mem.command_aliases[cur_alias_name]
					return_string = `${return_string}\n\`${cur_alias_name}\`: \`${cur_alias.command} ${cur_alias.args.join(" ")}\``;
				});

				return return_string;
			}

			// If no aliases are found, say so.
			else {
				return "There are no aliases to be found!";
			}
		},

		// Without arguments it gives a tiny instruction.
		default: function () {
			return info.core.getHelpString(info.command, info.message);
		},

	});

}