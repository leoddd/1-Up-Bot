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
exports.help = (config, command, message) => {
	return `Make me respond to certain message texts with certain commands.\nYou can \`list\` current hooks, \`add\` a new hook or \`clear\` an existing hook using its string ID given in the \`list\`. \
					\nUsage: \`${config.prefix}${command} [add|clear|list] [string|regex] [command]\` \
					\nExamples: \`${config.prefix}${command} list\`, \`${config.prefix}${command} add ping say pong\`, \`${config.prefix}${command} clear ping\`, \`${config.prefix}${command} add /{(.*?)}/g ygo.\`, \`${config.prefix}${command} add bear bear.\`, \`${config.prefix}${command} add /^(?:can|should|will)\\040(.*?)\\?/ 8ball\``;
}

// Command logic:
var escapeRegex = require('escape-string-regexp');

exports.call = (args, info) => {

	return info.core.commandSwitch(args, {

		add: args => {
			// If there aren't at least a command a string or regex, complain.
			if(args.length < 2) {
				return "I need to know a command and a phrase or regex to look out for!";
			}

			// Save the first argument for later.
			var original_regex = args.shift();
			var regex = original_regex;
			var regex_options = undefined;

			// For presentation.
			var wrap_l = "regular expression \`";
			var wrap_r = "\`";

			// Check for command validity on the second argument.
			var command = args.shift();

			if(!info.core.hasCommand(command)) {
				return `Oi oi oi, I don't know of any such \`${command}\` command, kid.`;
			}

			/////
			// Take the original first argument and turn it into regex.

			// If the first character is a forward slash, this is regex.
			if(regex.charAt(0) === "/") {
				// Delete starting slash to break it into regex string and options.
				regex = regex.substr(1);
				regex = regex.split("/");

				if(regex.length < 2) {
					return `Regex \`${original_regex}\` is not valid. Make sure to include the options slash even if you don't want to use any options.`;
				}

				// Build the regex object.
				regex_options = regex.pop();
				regex = regex.join("/");
			}

			// If the first character is not a slash, plain text regex.
			else {
				// Here, if the first character is a backslash, erase it as it may have been there to escape a forward slash.
				if(regex.charAt(0) === "\\") {
					regex = regex.substr(1);
				}

				// Build the regex object.
				regex = escapeRegex(regex);

				wrap_l = "when anyone says \`";
				wrap_r = "\`";
			}

			// After getting the data, verify the regex.
			try {
				new RegExp(regex, regex_options);
			} catch(err) {
				return `\`${original_regex}\` is invalid regex. Make sure it's valid using an online regex tester or something to that effect.`
			}

			return info.core.setHook({
				"command": command,
				"args": args,
				"regex_string": regex,
				"regex_options": regex_options,

				"guild": info.message.guild.id,
			})
				?
				`Hooked \`${command} ${args.join(" ")}\` up to ${wrap_l}${original_regex}${wrap_r}. Can't wait.`
				:
				`There already is a hook on ${wrap_l}${original_regex}${wrap_r}. One at a time!`
				;

		},


		// Clears the hook for the given regex.
		clear: args => {
			if(args.length === 0) {
				return "You'll have to tell me which hook to clear if you want anything done around here.";
			}

			// If hook exists, call the core clear function on it.
			var guild_id = info.message.guild.id;
			var regex_string = args[0];
			var perm_hooks = info.memory.guilds[guild_id].hooks;

			// Hook exists.
			if(perm_hooks && perm_hooks[regex_string]) {
				info.core.clearHook(guild_id, regex_string);
				if(Object.keys(perm_hooks).length === 0) {
					delete info.memory.guilds[guild_id].hooks;
				}
				return `Won't listen to \`${regex_string}\` any more.`;
			}

			// Hook does not exist.
			else {
				return `I don't have any \`${regex_string}\` hook!`;
			}
		},


		// Print out a list of currently active message hooks.
		list: () => {
			var temp_hooks = info.temp.guilds[info.message.guild.id].hooks;

			// If there are hooks set, loop over them.
			if(temp_hooks && Object.keys(temp_hooks).length > 0) {
				var hook_num = Object.keys(temp_hooks).length;
				var return_string = `**Found ${hook_num} hook${hook_num > 1 ? "s" : ""}:**`;

				Object.keys(temp_hooks).forEach(regex_string => {
					var cur_hook = temp_hooks[regex_string];

					var hook_string = `\`${regex_string}\`: \`${cur_hook.command} ${cur_hook.args.join(" ")}\`${cur_hook.regex.global ? " [global]" : ""}`;
					return_string = `${return_string}\n${hook_string}`;
				});

				return return_string;
			}

			// If no hooks are found.
			else {
				return "There are no hooks to be found!";
			}
		},

		// Without arguments return the help string.
		default: function () {
			return info.core.getHelpString(info.command, info.message);
		},

	});


}