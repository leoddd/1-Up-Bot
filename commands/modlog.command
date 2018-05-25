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
	return `Definitely really bans the given person. \
					\nUsage: \`${config.prefix}${command}\` [name]`;
}

// Command logic:
const verbs = ["hiding", "raiding", "spamming", "touching", "annoying", "swearing", "picking", "implementing", "robbing", "starting", "demoing", "punching", "eating", "lying", "showering", "bouncing", "leaving", "shoving", "smoking", "ridiculing", "skrinting", "pissing", "swimming", "fleeing", "killing", "snoring"];
const adjectives = ["new", "wild", "ferocious", "christian", "racist", "unplanned", "wrong", "long", "dead", "funny", "silly", "progressive", "red-pilled", "bad", "very nintendo", "similar to Luigi", "old", "close", "swanky", "funky", "fast and furious"];
const superlatives = ["worst", "best", "longest", "edgiest", "most spanish", "stinkiest", "most dry", "filthiest", "least offensive", "most terrible", "most gut-wrenching"];
const adverbs = ["respectfully", "loudly", "wildly", "quickly", "splendidly", "accidentally", "properly", "improperly", "odorously", "impossibly", "sweetly", "tenderly", "lovingly", "hatefully", "apathetically", "professionally"];
const objects = ["Madame Broode", "the bot", "a Wii remote", "FLUDD", "the game", "Luigi", "Mario", "Daisy", "Bowser", "child", "Peach", "Wario", "Waluigi", "Jr. Troopa", "global warming", "animal right", "meme", "the next Nintendo Direct", "Arthur"];
const locations = ["server", "castle", "fortress", "channel", "country", "steakhouse", "taco stand", "apartment", "support group", "concert", "bridge"];

exports.call = (args, info) => {
	// Create the intro (ex: "Banned Santa for 8.3 years for").
	var action = getRandomEntry(["Banned", "Warned", "Muted"]);
	var victim = args.join(" ");
	if(victim === "" || victim === " ") {
		victim = getRandomEntry(objects);
	}

	var duration = action === "Warned" ? "" : ` for ${info.core.randRange({"min": 0, "max": 100, "fixed": info.core.randRange({"min": 0, "max": 2, "fixed": 0})})} ${getRandomEntry(["years", "days", "hours", "minutes", "seconds", "centuries"])}`;

	var return_string = `${action} ${victim}${duration} for`;

	// Add reasons until we're done.
	var first_run = true;
	for (var num_of_reasons = info.core.randRange({"min": 0, "max": 1, "fixed": 0}); num_of_reasons >= 0; num_of_reasons--) {
		// String together reasons if this isn't the first run.
		if(first_run === false) {
			return_string = `${return_string}${getRandomEntry(["", ","])} ${getRandomEntry(["and", "as well as", "and then", "followed by", "which is made worse by them"])}`;
		}
		first_run = false;


		// Create an actual log reason.
		var details = getRandomEntry([

			()=>`joining and immediately ${getRandomEntry(verbs)} ${info.core.randRange({"min": 2, "max": 12, "fixed": 0})} users about ${getRandomEntry(objects)}`,
			()=>`posting the ${getRandomEntry(superlatives)} joke I've ever read and daring to call it ${getRandomEntry(adjectives)}`,
			()=>`posting one too many ${getRandomEntry(objects)}s`,
			()=>`posting an inappropriate image in the ${getRandomEntry(adjectives)} ${getRandomEntry(locations)}`,
			()=>`${getRandomEntry(adverbs)} raiding us with ${getRandomEntry(objects)} insults`,
			()=>`being disrespectful towards ${getRandomEntry(objects)} in my presence`,
			()=>`admitting to having smuggled ${info.core.randRange({"min": 2, "max": 299, "fixed": 0})} ${getRandomEntry(objects)}s into the ${getRandomEntry(locations)}`,
			()=>`trying to bypass a previous ban by ${getRandomEntry(verbs)} under a ${getRandomEntry(adjectives)} account`,
			()=>`going door to door ${getRandomEntry(verbs)} about ${getRandomEntry(objects)}`,
			()=>`tying a ${getRandomEntry(adjectives)} string of ${getRandomEntry(objects)}s to their feet and ${getRandomEntry(verbs)} them around ${getRandomEntry(adverbs)}`,
			()=>`starting a cult about ${getRandomEntry(objects)} ${getRandomEntry(adverbs)}`,
			()=>`${getRandomEntry(verbs)} the ${getRandomEntry(objects)} with only ${info.core.randRange({"min": 16, "max": 119, "fixed": 0})} stars`,
			()=>`${getRandomEntry(adverbs)} ${getRandomEntry(verbs)} too much ${getRandomEntry(objects)}`,
			()=>`${getRandomEntry(verbs)} an ATM disguised as ${getRandomEntry(objects)} to purchase ${getRandomEntry(objects)}`,
			()=>`not ${getRandomEntry(verbs)} all the ${getRandomEntry(objects)} in the ${getRandomEntry(locations)}`,
			()=>`${getRandomEntry(verbs)} their ${getRandomEntry(objects)} exam ${getRandomEntry(adverbs)}`,
			()=>`${getRandomEntry(verbs)} ${getRandomEntry(objects)} in the ${getRandomEntry(locations)} ${info.core.randRange({"min": 2, "max": 49, "fixed": 0})} times`,
			()=>`going online without their ${getRandomEntry(objects)}'s permission`,
			()=>`attempting to summon a ${getRandomEntry(adjectives)} ${getRandomEntry(objects)}`,
			()=>`trying to pirate the ${getRandomEntry(superlatives)} ${getRandomEntry(objects)} images`,
			()=>`trying to sync ${getRandomEntry(objects)} with ${getRandomEntry(adjectives)} ${getRandomEntry(objects)}s`,
			()=>`posting memes in a ${getRandomEntry(adjectives)} ${getRandomEntry(locations)}`,
			()=>`implementing ${getRandomEntry(adjectives)} features into ${getRandomEntry(objects)}`,
			()=>`${getRandomEntry(verbs)} the ${getRandomEntry(adjectives)} ${getRandomEntry(objects)} faction`,
			()=>`${getRandomEntry(verbs)} E. Gadd's \`Turbo-Charged ${toTitleCase(getRandomEntry(objects))} 3000\``,
			()=>`${getRandomEntry(verbs)} in a ${getRandomEntry(adjectives)} ${getRandomEntry(locations)}`,
			()=>`not listening to their ${getRandomEntry(objects)}`,

		])();

		return_string = `${return_string} ${details}`;

	}

	// Return the chimera.
	return `${return_string}.`;
}


// Returns a random entry from the given array.
function getRandomEntry(array) {
	return array[Math.floor(Math.random()*array.length)];
}

// Converts a string to Title Case.
function toTitleCase(str) {
	return str.replace(/\w\S*/g, function(txt){
		return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
	});
}