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
	return `Manage and view factions.\nYou can \`list\` current factions, \`add\` a new one or \`clear\` an existing faction. \
					\n\`bonus\` points can be \`add\`ed or \`sub\`tracted for each faction at will.\
					\nUse the \`join\` command to actually join one of the factions. \
					\nUsage: \`${config.prefix}${command} [add|clear|list|bonus] [add|sub] [role name] [amount]\` \
					\nExamples: \`${config.prefix}${command} list\`, \`${config.prefix}${command} add Cool Crew\`, \`${config.prefix}${command} clear Uncool Unity\`, \`${config.prefix}${command} bonus add 50 Cool Crew\``;
}

// Command logic:
exports.call = (args, info) => {

	if(!info.message.guild) {
		return "Cannot manage factions inside DMs."
	}

	var guild_mem = info.memory.guilds[info.message.guild.id];

	return info.core.commandSwitch(args, {

		add: args => {
			// If there is no role given to turn into a joinable faction, complain.
			if(args.length === 0) {
				return "You didn't tell me which role to add as a joinable faction.";
			}

			// Initialize faction memory if it doesn't exist yet.
			if(!guild_mem.hasOwnProperty("factions")) {
				guild_mem.factions = {};
			}

			// Grab the given role by its name.
			var role_name = args.join(" ");

			var role = info.message.guild.roles.find("name", role_name);
			if(!role) {
				return `There is no \`${role_name}\` role on this server. Check for typos!`
			}

			// Check if faction already exists.
			// If so, complain.
			if(Object.keys(guild_mem.factions).indexOf(role_name) !== -1) {
				return `The \`${role_name}\` role is already a faction.`;
			}

			// Else, commit to memory and affirm.
			else {
				guild_mem.factions[role_name] = {
					"activity_points": 0,
					"bonus_points": 0,
				};
				return `Added \`${role_name}\` as a joinable faction.`;
			}
		},


		// Remove the given role name from the joinable factions.
		clear: args => {
			// If there is no role name given to remove from factions, complain.
			if(args.length === 0) {
				return "You didn't tell me which role to remove from the joinable factions.";
			}

			// Grab the given role by its name.
			var role_name = args.join(" ");

			// Check if faction already exists.
			// If not, complain.
			if(guild_mem.factions === undefined || !guild_mem.factions.hasOwnProperty(role_name)) {
				return `The \`${role_name}\` role was not a joinable faction to begin with.`;
			}

			// Else, remove it from the factions and affirm.
			else {
				var cur_faction = guild_mem.factions[role_name];
				var return_string = `Removed the \`${role_name}\` role from the list of joinable factions. \
								\nMembers: \`${info.message.guild.roles.find("name", role_name).members.size}\` - Score: \`${Math.floor(cur_faction.activity_points) + Math.floor(cur_faction.bonus_points)}\` (\`${Math.floor(cur_faction.activity_points)}AP\` + \`${Math.floor(cur_faction.bonus_points)}BP\`)`;
				delete guild_mem.factions[role_name];
				if(Object.keys(guild_mem.factions).length === 0) {
					delete guild_mem.factions;
				}
				return return_string;
			}

		},


		// Print out a list of joinable factions and their members + scores.
		list: () => {
			// If there are joinable factions, loop over them.
			if(guild_mem.factions && Object.keys(guild_mem.factions).length > 0) {
				var return_string = `**All factions:**`;

				Object.keys(guild_mem.factions).forEach(role_name => {
					var cur_faction = guild_mem.factions[role_name];

					var faction_string = `\`${role_name}\`: Members: \`${info.message.guild.roles.find("name", role_name).members.size}\` - Score: \`${Math.floor(cur_faction.activity_points) + Math.floor(cur_faction.bonus_points)}\` (\`${Math.floor(cur_faction.activity_points)}AP\` + \`${Math.floor(cur_faction.bonus_points)}BP\`)`;
					return_string = `${return_string}\n${faction_string}`;
				});

				return return_string;
			}

			// If no factions are found, complain.
			else {
				return "There are no factions to be found!";
			}
		},


		// Reset all cooldowns.
		resetcooldowns: () => {
			if(guild_mem.hasOwnProperty("faction_messages_sent")) {
				delete guild_mem.faction_messages_sent;
			}
			return "Reset all faction cooldowns.";
		},


		// Add or subtract bonus points for the given faction.
		bonus: args => {
			if(args.length === 0 || (args[0] !== "add" && args[0] !== "sub")) {
				return "You didn't tell me whether you want to \`add\` or \`sub\` bonus points.";
			}

			if(args.length < 3) {
				return "You'll need to tell me the amount of points and the faction to apply to as well.";
			}

			// Verify the rest of the inputs.
			var operation = args.shift();
			var amount = args.shift();
			var role_name = args.join(" ");

			if(isNaN(amount)) {
				return `I don't understand the amount of points you want me to ${operation}, \`${amount}\` doesn't look like a number.`;
			}

			if(!guild_mem.factions.hasOwnProperty(role_name)) {
				return `There is no \`${role_name}\` faction. Check for typos!`;
			}

			// Perform the operation and affirm.
			var cur_faction = guild_mem.factions[role_name];
			amount = parseInt(amount, 10);
			if(operation === "add") {
				cur_faction.bonus_points += amount;
			}
			else if(operation === "sub") {
				cur_faction.bonus_points -= amount;
			}

			return `The \`${role_name}\` faction ${operation === "add" ? "gained" : "lost"} \`${amount}\` Bonus Points. \
							\nScore: \`${Math.floor(cur_faction.activity_points) + Math.floor(cur_faction.bonus_points)}\` (\`${Math.floor(cur_faction.activity_points)}AP\` + \`${Math.floor(cur_faction.bonus_points)}BP\`)`;

		},

		// Without arguments return the help string.
		default: function () {
			return info.core.getHelpString(info.command, info.message);
		},

	});
}