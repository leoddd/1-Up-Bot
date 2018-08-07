//////////////////////////////
// Command file for leod's bot.
/////
//
// Needs to export a 'call' function that returns a response object as specified in bot_core.
// function call(args, info)
//   args: Arguments passed in by the user, like "m!markov arguments are these words"
//   info: An object with information about the current bot state. Keys:
//     memory: The global memory object the bot posesses. Kept between reboots.
//     temp: The temporary memory object the bot posesses. Deleted upon reboot.
//     message: Discord.js's Message object. Represents the message that triggered this command, if it is a command.
//     command: The name of the command being called, if it is a command.
//     is_hook: If set, the command was called through a message hook instead of an explicit command.
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
exports.level = "admin";

// Help function:
exports.help = (config, command, message, core) => {
	return `Takes a Discord Snowflake ID and returns info about it and its type. \
					\nUsage: \`${config.prefix}${command} [ID]\``;
}

// Command logic:
exports.call = (args, info) => {
	if(args.length === 0) {
		return "Give me a Discord Snowflake ID to return info about.";
	}

	var snowflake = args[0];
	if(isNaN(snowflake)) {
		return "That doesn't look like a Discord Snowflake ID to me!";
	}


	// Figure out if it's a guild, channel or user.
	var bot = info.bot;
	var subject;

	// Is guild?
	if(bot.guilds.get(snowflake)) {
		subject = bot.guilds.get(snowflake);

		return `\`${snowflake}\` is a guild.
Name: ${subject.name}
Owner: ${subject.owner.tag} (${subject.owner.id})
Icon: ${subject.iconURL}
Created: ${subject.createdAt.toLocaleDateString("en-US")}
Users: <@${Array.from(subject.members.keys()).join(">, <@")}>`;
	}

	// Is channel?
	else if(bot.channels.get(snowflake)) {
		subject = bot.channels.get(snowflake);

		// Is it a guild's channel?
		if(["text", "voice", "category"].indexOf(subject.type) !== -1) {
			// Guild channel.
			return `<#${snowflake}> is a guild channel.
Name: ${subject.name}
Guild: ${subject.guild.name} (${subject.guild.id})
Created: ${subject.createdAt.toLocaleDateString("en-US")}`;
		}

		else {
			// Not a guild channel.
			if(subject.type === "dm") {
				// Single DM channel.
				return `<#${snowflake}> is a DM channel.
Name: ${subject.name}
Recipient: ${subject.recipient}`;
			}

			else if(subject.type === "group") {
				// Single DM channel.
				return `<#${snowflake}> is a group channel.
Name: ${subject.name}
Owner: ${subject.owner.tag} (${subject.owner.id})
Recipients: <@${Array.from(subject.recipients.keys()).join(">, <@")}>`;
			}
		}
	}

	// Is user?
	else if(bot.users.get(snowflake)) {
		subject = bot.users.get(snowflake);

		return `<@${snowflake}> is a user.
Tag: ${subject.tag}
Created: ${subject.createdAt.toLocaleDateString("en-US")}
Profile Picture: ${subject.displayAvatarURL}`;
	}

	// Is message?
	else {
		return `Could not find \`${snowflake}\` as a guild, channel or user.`;
	}
}