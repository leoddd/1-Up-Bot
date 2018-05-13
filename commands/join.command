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
	return `Lets you join a server faction to help accumulate points. Use \`none\` as the faction name to leave your current faction.\nTo get a list of all current factions, use \`list\`. \
					\nUsage: \`${config.prefix}${command} [list|none|(faction name)]\``;
}

// Command logic:
exports.call = (args, info) => {
	if(!info.message.guild) {
		return "You cannot join a faction in DMs.";
	}

	if(args.length === 0) {
		return "You'll need to tell me which faction you want to join!";
	}

	var role_name = args.join(" ");

	// If the faction is "list", that means the user simply wants to see a list of factions to join.
	if(role_name === "list") {
		var guild_mem = info.memory.guilds[info.message.guild.id];

		// If there are joinable factions, loop over them.
		if(guild_mem.factions && Object.keys(guild_mem.factions).length > 0) {
			return `**All factions:**\n\`${Object.keys(guild_mem.factions).join("\`, \`")}\``;
		}

		// If no factions are found, complain.
		else {
			return "There don't seem to be any factions for you to join right now. Oops!";
		}
	}

	var faction_mem = info.memory.guilds[info.message.guild.id].factions;
	var user_ping = `<@${info.message.author.id}>`;

	// If the user does want to actually manipulate their faction, verify that the desired faction exists.
	if((faction_mem && faction_mem.hasOwnProperty(role_name)) || role_name === "none") {
		// If it does, leave all faction roles except for the requested one.
		var had_role_already = false;
		var left_anything = false;
		var roles_to_remove = [];
		var author_member = info.message.member;

		author_member.roles.forEach((cur_role, role_id, role_list) => {
			// If the current role is a faction role, remember it for removal.
			if(faction_mem.hasOwnProperty(cur_role.name)) {
				if(cur_role.name === role_name) {
					had_role_already = true;
				}

				roles_to_remove.push(cur_role);
				left_anything = true;
			}
		});

		var channel = info.message.channel;

		author_member.removeRoles(roles_to_remove)
		.then(() => {
			// Once all are left, join the one that was requested if we didn't already have it.
			if(role_name !== "none" && had_role_already === false) {
				author_member.addRole(info.message.guild.roles.find("name", role_name))
				.then(() => {
					channel.send(`${user_ping} has joined the \`${role_name}\` faction!`);
				})
				.catch(err => {
					channel.send(`There was an issue joining the \`${role_name}\` faction; couldn't add the faction role.`);
				});
			}

			// Else, if we do not want to join any new role, report that we successfully left the old one.
			else {
				if(left_anything) {
					channel.send(`${user_ping} has left their faction.`);
				} else {
					channel.send(`${user_ping}, you were not a member of any faction to begin with.`);
				}
			}
		})
		.catch(() => {
			channel.send(`There was an issue joining the \`${role_name}\` faction; couldn't remove existing faction roles.`);
		});
	}

	// If the faction we want to join doesn't exist, complain.
	else {
		return `There is no \`${role_name}\` faction that you could join. Maybe you mistyped it?`;
	}
}