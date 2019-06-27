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
	return `Example help function. \
					\nUsage: \`${config.prefix}${command}\``;
}

// Command logic:
exports.call = (args, info) => {

	if(!info.message.guild) {
		return "Can't list emotes outside of a server!";
	}

	// Array of objects to be filled out later.
	var emote_list = {
		"regular": [],
		"animated": [],
	};

	var emotes = info.message.guild.emojis;
	emotes.forEach((emote, emoteID) => {

		emote_list[emote.animated ? "animated" : "regular"].push({
			"name": emote.name,
			"code": `<${emote.animated ? "a" : ""}:${emote.name}:${emote.id}>`,
		});

	});

	// Count amount of emotes.
	var amounts = {"total": 0};
	Object.keys(emote_list).forEach(emote_type => {
		amounts[emote_type] = emote_list[emote_type].length;
		amounts.total += amounts[emote_type];
	});

	// Prepare arrays for display.
	Object.keys(emote_list).forEach(emote_type => {
		var current_list = emote_list[emote_type];

		// Alphabetically sort.
		current_list.sort((one, two) => {
			if(one.name.toLowerCase() < two.name.toLowerCase()) return -1;
			return 1;
		});

		// Deinterlace for two column behavior.
		emote_list[emote_type] = deinterlaceArray(current_list);
	});

	// Create footer string of emote totals.
	var footer_string = `${amounts.total} emotes (`;
	var first_type = true;
	Object.keys(emote_list).forEach(emote_type => {
		footer_string = `${footer_string}${first_type ? "" : ", "}${amounts[emote_type]} ${emote_type}`;
		first_type = false;
	});
	footer_string = `${footer_string})`;


	// Create embed.
	var emote_embed = info.core.makeEmbed()
		// General info.
		.setFooter(footer_string)
		.setAuthor(`${info.message.guild.name} Emotes`, info.message.guild.iconURL)
		.setColor(0x24f232)
		;

	// Emote info.
	Object.keys(emote_list).forEach(emote_type => {
		if(amounts[emote_type] === 0) {
			return;
		}

		var type_field = emote_type;
		type_field = type_field[0].toUpperCase() + type_field.slice(1)

		var left_list = listEmotes(emote_list[emote_type][0]);
		var right_list = listEmotes(emote_list[emote_type][1]);

		var left_chunk = "";
		var right_chunk = "";

		while(true) {
			var left_index = nthIndex(left_list, "\n", 10);
			var right_index = nthIndex(right_list, "\n", 10);
			left_chunk = left_list.slice(0, left_index !== -1 ? left_index : undefined);
			right_chunk = right_list.slice(0, right_index !== -1 ? right_index : undefined);
			left_list = left_list.slice(left_index);
			right_list = right_list.slice(right_index);
			emote_embed
				.addField(type_field, left_chunk, true)
				.addField("\u200b", right_chunk, true)
				.addField("\u200b", "\u200b")
				;

			type_field = "\u200b";

			if(left_index === -1) {
				break;
			}
		}
	});


	// bush holograms send tweet
	info.message.channel.send({embed: emote_embed})
}


// Returns a string that lists all emotes in the array of objects.
function listEmotes(array) {
	result = "";

	var first_emote = true;
	array.forEach(emote => {
		result = `${result}${first_emote ? "" : "\n"}${emote.code} \`:${emote.name}:\``;

		first_emote = false;
	});

	if(result === "") {
		result = "\u200b";
	}

	return result;
}


// Find the nth occurence of the pattern in the string.
function nthIndex(string, pattern, n){
    var L= string.length, i= -1;
    while(n-- && i++<L){
        i= string.indexOf(pattern, i);
        if (i < 0) break;
    }
    return i;
}


// Split array in two with alternating entries.
function deinterlaceArray(array) {
	var result = [[], []];

	array.forEach((entry, index) => {
		result[index % 2].push(entry);
	});

	return result;
}


/* This was dumb I needed the exact opposite.
// Interlace two arrays.
function interlaceArrays(arrays) {
   var length = Math.max.apply(Math, arrays.map(function(array) {
     return array.length;
   }));

   var result = [];

   for (var itemIndex = 0; itemIndex < length; itemIndex++) {
      for (var arrayIndex = 0; arrayIndex < arrays.length; arrayIndex++) {
         if (arrays[arrayIndex].length - 1 < itemIndex) {
            continue;
         }
         result.push(arrays[arrayIndex][itemIndex]);
      }
   }

   return result;
};
*/