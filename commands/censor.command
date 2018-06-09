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
	return `Edit words that I will not commit to memory in any way.\nYou can \`list\` current censored phrases, \`add\` a new one or \`clear\` an existing censor. \
					\nUsage: \`${config.prefix}${command} [add|clear|list] [phrase]\` \
					\nExamples: \`${config.prefix}${command} list\`, \`${config.prefix}${command} add bad phrase\`, \`${config.prefix}${command} clear not actually a bad phrase\``;
}

// Command logic:
exports.call = (args, info) => {

	var guild_mem = info.memory.guilds[info.message.guild.id];

	return info.core.commandSwitch(args, {

		add: args => {
			// If there is no phrase given to censor, complain.
			if(args.length === 0) {
				return "You didn't give me a phrase to add to the censors.";
			}

			// Initialize censor memory if it doesn't exist yet.
			if(!guild_mem.hasOwnProperty("custom_censored_words")) {
				guild_mem.custom_censored_words = [];
			}

			// Check if censor already exists.
			var phrase_to_censor = args.join(" ");

			// If so, complain.
			if(
			guild_mem.custom_censored_words.indexOf(phrase_to_censor) !== -1
			|| (!info.config.use_global_censors || info.config.global_censored_words.indexOf(phrase_to_censor) !== -1)
			) {
				return `\`${phrase_to_censor}\` was already being censored.`;
			}

			// Else, commit to memory and affirm.
			else {
				guild_mem.custom_censored_words.push(phrase_to_censor);
				return `Added \`${phrase_to_censor}\` to the list of censored phrases.`;
			}
		},


		// Clears the censor for the given phrase.
		clear: args => {
			// Extract from the message content directly, since the censoring blinds the bot. lol.
			var phrase_to_clear = info.message.content
														.replace(info.config.prefix, "")
														.replace(info.command, "")
														.replace(" clear ", "")
														.trim();

			// If there is no phrase given to clear, complain.
			if(phrase_to_clear === "" || phrase_to_clear === " ") {
				return "You didn't tell me which phrase to remove from the censors.";
			}

			// Check if censor even exists.

			var phrase_index = guild_mem.custom_censored_words.indexOf(phrase_to_clear);
			// If it's a phrase from the global list, explain how to disable it.
			if(info.config.use_global_censors && info.config.global_censored_words.indexOf(phrase_to_clear) !== -1) {
				return `\`${phrase_to_clear}\` is censored through the global censor list.\nDisable the \`use_global_censors\` config variable if you do not want to use it.`;
			}
			// If not, complain.
			if(!guild_mem.custom_censored_words || phrase_index === -1) {
				return `\`${phrase_to_clear}\` was not being censored to begin with.`;
			}

			// Else, remove it from the censors and affirm.
			else {
				guild_mem.custom_censored_words.splice(phrase_index, 1);
				if(guild_mem.custom_censored_words.length === 0) {
					delete guild_mem.custom_censored_words;
				}
				return `Removed \`${phrase_to_clear}\` from the list of censored phrases.`;
			}

		},


		list: () => {
			// Use the guild's own custom censors if available.
			var guild_censors = info.memory.guilds[info.message.guild.id].custom_censored_words;

			if(guild_censors === undefined) {
				guild_censors = [];
			}

			// Add global censors if we wish to.
			if(info.config.use_global_censors === true) {
				guild_censors = guild_censors.concat(info.config.global_censored_words);
			}

			// If there are censors set, list them.
			if(guild_censors && guild_censors.length > 0) {
				guild_censors.sort();
				var censor_num = guild_censors.length;
				return `**Found ${censor_num} censor${censor_num > 1 ? "s" : ""}:**\n\`${guild_censors.join("\`, \`")}\``;
			}

			// If no censors are found, advise enabling global ones at least.
			else {
				return "There are no censors set. If you want to use the global ones, set the \`use_global_censors\` config variable to true.";
			}
		},

		// Without arguments it gives a tiny instruction.
		default: function () {
			return info.core.getHelpString(info.command, info.message);
		},

	});


}