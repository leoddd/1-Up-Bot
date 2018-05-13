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
exports.help = (config, command, message) => {
	return `Get the Nookipedia page for the given Animal Crossing villager. \
					\nUsage: \`${config.prefix}${command} [villager name]\``;
}

// Command logic:
// List of all nookipedia villager pages.
// From https://nookipedia.com/wiki/List_of_villagers
const villagers = ["Ace", "Admiral", "Agent S", "Agnes", "Aisle", "Al", "Alfonso", "Alice", "Alli", "Amelia", "Anabelle", "Analogue", "Anchovy", "Angus", "Anicotti", "Ankha", "Annalisa", "Annalise", "Antonio", "Apollo", "Apple", "Astrid", "Aurora", "Ava", "Avery", "Axel", "Aziz", "Baabara", "Bam", "Bangle", "Barold", "Bea", "Beardo", "Beau", "Becky", "Bella", "Belle", "Benedict", "Benjamin", "Bertha", "Bessie", "Bettina", "Betty", "Bianca", "Biff", "Big Top", "Bill", "Billy", "Biskit", "Bitty", "Blaire", "Blanche", "Bluebear", "Bob", "Bonbon", "Bones", "Boomer", "Boone", "Boots", "Boris", "Boyd", "Bow", "Bree", "Broccolo", "Broffina", "Bruce", "Bubbles", "Buck", "Bud", "Bunnie", "Butch", "Buzz", "Cally †", "Camofrog", "Canberra", "Candi", "Carmen", "Carmen", "Caroline †", "Carrie", "Carrot", "Cashmere", "Cece", "Celia", "Cesar", "Chadder", "Chai", "Champ", "Champagne", "Charlise", "Chelsea", "Cheri", "Cherry", "Chester", "Chevre", "Chico", "Chief", "Chops", "Chow", "Chrissy", "Chuck", "Clara", "Claude", "Claudia", "Clay", "Cleo", "Clyde", "Coach", "Cobb", "Coco", "Cole", "Colton", "Cookie", "Cousteau", "Cranston", "Croque", "Cube", "Cupcake", "Curlos", "Curly", "Curt", "Cyrano", "Daisy", "Deena", "Deirdre", "Del", "Deli", "Derwin", "Diana", "Diva", "Dizzy", "Dobie", "Doc", "Dora", "Dotty", "Dozer", "Drago", "Drake", "Drift", "Ed", "Egbert", "Elina", "Elise", "Ellie", "Elmer", "Eloise", "Elvis", "Emerald", "Epona", "Erik", "Étoile", "Eugene", "Eunice", "Faith", "Fang", "Fauna", "Felicity", "Felyne", "Filbert", "Filly", "Flash", "Flip", "Flo", "Flora", "Flossie", "Flurry", "Francine", "Frank", "Freckles", "Freya", "Friga", "Frita", "Frobert", "Fruity", "Fuchsia", "Gabi", "Gala", "Ganon", "Gaston", "Gayle", "Gen", "Genji", "Gigi", "Gladys", "Gloria", "Goldie", "Gonzo", "Goose", "Graham", "Greta", "Grizzly", "Groucho", "Gruff", "Gwen", "Hambo", "Hamlet", "Hamphrey", "Hank", "Hans", "Harry", "Hazel", "Hector", "Henry", "Hippeux", "Holden", "Hopkins", "Hopper", "Hornsby", "Huck", "Huggy", "Hugh", "Iggly", "Iggy", "Ike", "Inkwell", "Jacques", "Jacob †", "Jambette", "Jane", "Jay", "Jeremiah", "Jitters", "Joe", "Joey", "Jubei", "Julia", "Julian", "June", "Kabuki", "Katt", "Keaton", "Ken", "Ketchup", "Kevin", "Kid Cat", "Kidd", "Kiki", "Kit", "Kitt", "Kitty", "Klaus", "Knox", "Kody", "Koharu", "Kyle", "Leigh", "Leonardo", "Leopold", "Lily", "Limberg", "Lionel", "Liz", "Lobo", "Lolly", "Lopez", "Louie", "Lucha", "Lucky", "Lucy", "Lulu", "Lulu", "Lyman", "Mac", "Madam Rosa", "Maddie", "Maelle", "Maggie", "Mallary", "Maple", "Marcel", "Marcie", "Marcy", "Margie", "Marina", "Marshal", "Marty", "Masa", "Mathilda", "Medli", "Megumi", "Melba", "Meow", "Merengue", "Merry", "Midge", "Mint", "Mira", "Miranda", "Mitzi", "Moe", "Molly", "Monique", "Monty", "Moose", "Mott", "Muffy", "Murphy", "Nan", "Nana", "Naomi", "Nate", "Nibbles", "Nindori", "Nobuo", "Norma", "Nosegay", "O'Hare", "Octavian", "Olaf", "Olive", "Olivia", "Opal", "Otis", "Oxford", "Ozzie", "Pancetti", "Pango", "Paolo", "Papi", "Pashmina", "Pate", "Patricia", "Patty", "Paula", "Peaches", "Peanut", "Pecan", "Peck", "Peewee", "Peggy", "Pekoe", "Penelope", "Penny", "Petunia", "Petunia", "Phil", "Phoebe", "Pierce", "Pierre", "Pietro", "Pigleg", "Pinky", "Piper", "Pippy", "Pironkon", "Plucky", "Poko", "Pompom", "Poncho", "Poppy", "Portia", "Prince", "Puck", "Puddles", "Pudge", "Punchy", "Purrl", "Queenie", "Quetzal", "Quillson", "Raddle", "Rasher", "Renée", "Rex", "Rhoda", "Rhonda", "Ribbot", "Ricky", "Rilla", "Rio", "Rizzo", "Roald", "Robin", "Rocco", "Rocket", "Rod", "Rodeo", "Rodney", "Rolf", "Rollo", "Rooney", "Rory", "Roscoe", "Rosie", "Rowan", "Ruby", "Rudy", "Sally †", "Samson", "Sandy", "Savannah", "Scoot", "Shari", "Sheldon", "Shep", "Shinabiru", "Shoukichi", "Simon", "Skye", "Sly", "Snake", "Snooty", "Soleil", "Sparro", "Spike", "Spork †", "Sprinkle", "Sprocket", "Static", "Stella", "Sterling", "Stinky", "Stitches", "Stu", "Sue E.", "Sunny", "Sven", "Sydney", "Sylvana", "Sylvia", "T-Bone", "Tabby", "Tad", "Tammi", "Tammy", "Tangy", "Tank", "Tarou", "Tasha", "Teddy", "Tex", "Tia", "Tiara", "Tiffany", "Timbra", "Tipper", "Tom", "Toby", "Truffles", "Tucker", "Tutu", "Twiggy", "Twirp", "Tybalt", "Ursala", "Valise", "Velma", "Verdun", "Vesta", "Vic", "Viché", "Victoria", "Violet", "Vivian", "Vladimir", "W. Link", "Wade", "Walker", "Walt", "Wart Jr.", "Weber", "Wendy", "Whitney", "Willow", "Winnie", "Wolfgang", "Woolio", "Yodel", "Yuka", "Zell", "Zoe", "Zucker"];
const NOOKI_BASE_URL = "https://nookipedia.com/wiki/";

// Fuzzy text search, to search for villagers.
const fuzzy = require('fuzzy');

exports.call = (args, info) => {

	// Search for the supplied villager in the 
	var search_string = args.join(" ");
	var results = fuzzy.filter(search_string, villagers).map(el => { return el.string; });

	// If no results, complain.
	if(results.length === 0) {
		return `Couldn't find any villager named \`${search_string}\`.`;
	}

	// If more than one result, prepare the "amounts found" string.
	var amount_string = undefined;
	if(results.length >= 2) {
		// Check if the best result is the literal hit. For prep vs pre-prep.
		if(results[0].toLowerCase() !== search_string.toLowerCase().trim()) {
			amount_string = `Found ${results.length - 1} more results for \`${search_string}\`. If this is not the right card, be more specific.`;
		}
	}

	// Build URL.
	var result = `${NOOKI_BASE_URL}${results[0].replace(" ", "_")}`;

	return result;

}