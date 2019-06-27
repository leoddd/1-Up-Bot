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
exports.level = "all";

// Help function:
exports.help = (config, command, message, core) => {
	return `Start a game of hangman! The word can either be \`random\`, specifically a \`noun\`, \`verb\`, \`adjective\` or \`adverb\`, or entirely \`custom\` (default). \
					\nIf you want to use a \`custom\` word, make sure that I am allowed to send you a DM to ask for the word in secret! \
					\nUsage: \`${config.prefix}${command}\`, \`${config.prefix}${command} verb\`, \`${config.prefix}${command} custom\``;
}


const rpos = require('random-part-of-speech');

const GUESS_LIMIT = 8;
const CUSTOM_TIMEOUT = 60;
const GUESS_TIMEOUT = 300;
const DRAWINGS = {
	"hangman": [
`   \_\_\_\_\_
  |/
  |
  |
  |
 \_|\_\_\_`,
`   \_\_\_\_\_
  |/
  |   :face:
  |
  |
 \_|\_\_\_`,
`   \_\_\_\_\_
  |/
  |    :face:
  |    |
  |
 \_|\_\_\_`,
`   \_\_\_\_\_
  |/
  |    :face:
  |   /|
  |
 \_|\_\_\_`,
`   \_\_\_\_\_
  |/
  |    :face:
  |   /|
  |     \\
 \_|\_\_\_`,
`   \_\_\_\_\_
  |/
  |    :face:
  |   /|
  |   / \\
 \_|\_\_\_`,
`   \_\_\_\_\_
  |/
  |    :face:
  |   /|:arm_right:
  |   / \\
 \_|\_\_\_`,
`   \_\_\_\_\_
  |/   |
  |    :face:
  |   /|:arm_right:
  |   / \\
 \_|\_\_\_`,
	],
};
const FACES = ["🤠", "😌", "😹", "😴", "👶", "😠", "😂", "😇", "😜", "🤒", "💩", "👽", "🤖", "👮", "🐙", "🐸", "🐴"];
const ARMS = ["🤘", "👉", "✌", "🤞", "🖖", "👌", "👍", "👊", "💅"];

const CHICKENOMETER = [
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/smiling-face-with-smiling-eyes_1f60a.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/smiling-face-with-open-mouth-and-smiling-eyes_1f604.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/smiling-face-with-open-mouth-and-cold-sweat_1f605.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/slightly-smiling-face_1f642.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/hushed-face_1f62f.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/confused-face_1f615.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/persevering-face_1f623.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/face-screaming-in-fear_1f631.png",
	"https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/skull-and-crossbones_2620.png",
];
const COLORS = [
	0xa0e98b,
	0xb3e47e,
	0xcbdf71,
	0xd8dd6b,
	0xdacd65,
	0xd5a359,
	0xd38c54,
	0xd0744e,
	0xcb4343,
];

// Command logic:
exports.call = async (args, info) => {


	var send = string => {return info.message.channel.send(string)};
	var guess_prefix = info.config.prefix === "?" ? "!g " : "?g ";
	var state_request = info.config.prefix === "?" ? "!state" : "?state";
	var quit_request = info.config.prefix === "?" ? "!quit" : "?quit";

	// Check if there is already a game going on.
	var current_temp;
	var current_id;
	var is_DM;
	var place_name;
	if(info.message.guild) {
		current_temp = info.temp.channels[info.message.channel.id];
		current_id = info.message.guild.id;
		place_name = info.message.guild.name;
		is_DM = false;
	} else {
		if(!info.temp.users[info.message.author.id]) {
			info.temp.users[info.message.author.id] = {};
		}
		current_temp = info.temp.users[info.message.author.id];
		current_id = info.message.author.id;
		place_name = info.message.author.tag;
		is_DM = true;
	}


	if(current_temp.hangman === true) {
		send(`There is already a game underway in this channel, please wait for it to finish or use \`${state_request}\` to see where it's at!`);
		return;
	}
	current_temp.hangman = true;


	var amount = 1;

	var word = await info.core.commandSwitch(args, {

		random: () => {
			return rpos.getAny(amount);
		},

		noun: () => {
			return rpos.getNouns(amount);
		},

		verb:  () => {
			return rpos.getVerbs(amount);
		},

		adjective: () => {
			return rpos.getAdjectives(amount);
		},

		adverb: () => {
			return rpos.getAdverbs(amount);
		},

		custom: () => {
			if(is_DM) {
				send("Setting the word for a DM game doesn't make a lot of sense, does it?");
				return false;
			}


			return new Promise(async (resolveCustom, rejectCustom) => {

				// Function that will fail the search for a custom phrase.
				var failPhrase = () => {
					info.message.author.send(`Custom game of hangman in <#${info.message.channel.id}> (${place_name}) has been cancelled, as you didn't give me a phrase to start it with.`);
					info.core.clearAwait(info.message.author.id, dm_await_ID, true);
					resolveCustom(false);
				}

				// Reject the promise after the timeout is out.
				var phrase_timeout_id = setTimeout(failPhrase, CUSTOM_TIMEOUT * 1000);


				// DM the author, asking them to hand over a phrase.
				var phrase_prefix = info.config.prefix === "?" ? "!phrase " : "?phrase ";
				info.message.author.send(
`Respond to this with \`${phrase_prefix}your phrase here\` to start a game of hangman in <#${info.message.channel.id}> (${place_name}) using that phrase.
The game will be cancelled in ${CUSTOM_TIMEOUT} seconds if you haven't given me a phrase by then.`
				);

				// Set an await for the author's DMs.
				var dm_await_ID = info.core.setAwait(info.message.author.id, (response_info, clearThis) => {

					var phrase = response_info.message.content;
					if(phrase.indexOf(phrase_prefix) === 0) {

						// Cut out prefix and check if there are any alphanumeric characters to guess.
						phrase = phrase.split(phrase_prefix).join('');
						if(!/[a-z0-9]/i.test(phrase)) {
							info.message.author.send("You forgot to give me an actual phrase with at least one guessable character!");
							return;
						}
						// If the phrase is valid, start the game!
						else {
							resolveCustom([phrase]);
							clearTimeout(phrase_timeout_id);
						}
					}

				}, true);

			});
		},

		default: function () {
			if(is_DM) {
				return this.random();
			} else {
				return this.custom();
			}
		},

	});

	if(word === false) {
		send("Couldn't start the game of hangman for lack of a phrase. Try again?");
		delete current_temp.hangman;
		return;
	}
	word = word.join(" ");



	// If a word was found or given successfully, start the hangman game.
	var bad_guesses = 0;
	var guessed_letters = [];
	var guessed_words = [];
	var participants = [];

	var face = getRandomEntry(FACES);
	var arm_right = getRandomEntry(ARMS);

	// Timeout after x seconds of no guesses. Reset every new guess or state request.
	var guess_timeout_id;
	var resetTimeout = () => {
		if(guess_timeout_id) {
			clearTimeout(guess_timeout_id);
		}
		guess_timeout_id = setTimeout(() => {
			send("The game of hangman has been cancelled due to a lack of recent guesses.");
			endHangman();
		}, GUESS_TIMEOUT * 1000);
	}


	// Prints out the current state of the hangman game.
	// If completed is `true`, all letters will be shown.
	var printState = completed => {

		// Reset the timeout whenever the state is printed.
		resetTimeout();

		// Generate current letter state (the underscores, you know).
		var letter_state = "";
		for(var needed_letter of word) {
			// If it's a space, put in some spacing.
			if(needed_letter === " ") {
				letter_state += "\u00A0\u00A0\u00A0 ";
			}
			// If it isn't guessable or has been guessed, print it.
			else if(!isAlphaNumeric(needed_letter) || guessed_letters.indexOf(needed_letter.toLowerCase()) !== -1 || completed === true) {
				letter_state += `${needed_letter} `;
			}
			// If it hasn't been guessed, hide it.
			else {
				letter_state += "\_ ";
			}
		}
		letter_state = letter_state.trim();

		// Grab current state of "drawing".
		var drawing_state = "";
		if(bad_guesses > 0) {
			drawing_state = DRAWINGS["hangman"][bad_guesses - 1]
			.replace(":face:", face)
			.replace(":arm_right:", arm_right)
			;
		}

		var card_embed = info.core.makeEmbed()
			// Meta data.
			.setColor(completed === true ? 0xc3dff0 : COLORS[bad_guesses])
			.setAuthor(letter_state, completed === true ? "https://emojipedia-us.s3.amazonaws.com/thumbs/120/twitter/141/party-popper_1f389.png" : CHICKENOMETER[bad_guesses])
			;

		if(bad_guesses > 0) {
			card_embed
			.setDescription(`\`\`\`\n${drawing_state}\`\`\``)
			;
		}

		card_embed
		.addField("Guessed Letters", guessed_letters.length > 0 ? guessed_letters.join(', ') : "\u200b", true)
		.addField("Guessed Phrases", guessed_words.length > 0 ? guessed_words.join(', ') : "\u200b", true)
		;

		send({embed: card_embed});
	}

	// End of game handlers.
	var loseHangman = () => {
		printState();
		send(
`Let's hear a big round of applause for today's loser${participants.length > 1 ? "s" : ""}, who could not figure out the simple phrase "${word}"!
Better luck next time, <@${participants.join(">, <@")}>!`
		);
		endHangman();
	}

	var winHangman = () => {
		printState(true);

		participants.splice(participants.indexOf(player_id), 1);

		send(
`Congratulations <@${player_id}>, you got it${participants.length > 0 ? " first" : ""}!${participants.length > 0 ? `\nShoutouts also to <@${participants.join(">, <@")}> for attempting to help!` : ""}`
		);
		endHangman();
	}

	var endHangman = () => {
		info.core.clearAwait(current_id, await_ID, is_DM);
		clearTimeout(guess_timeout_id);
		delete current_temp.hangman;
	}

	// Guessing handlers.
	var guessLetter = guessed_letter => {
		// Check if letter is legally guessable.
		if(!isAlphaNumeric(guessed_letter)) {
			send(`"${guessed_letter}" isn't something you would need to guess.`);
			return;
		}

		guessed_letter = guessed_letter.toLowerCase();

		// Check if already guessed.
		if(guessed_letters.indexOf(guessed_letter) !== -1) {
			send(`"${guessed_letter}" was already guessed.`);
			return;
		}

		// Letter hasn't been guessed before.
		guessed_letters.push(guessed_letter);
		if(word.indexOf(guessed_letter) !== -1) {			
			// Check if all letters have been guessed now.
			var solved = true;
			for(var needed_letter of word) {
				// Ignore spaces and punctuation.
				if(!isAlphaNumeric(needed_letter)) {
					continue;
				}
				// Check if the letter is in the guessed array.
				if(guessed_letters.indexOf(needed_letter.toLowerCase()) === -1) {
					solved = false;
					break;
				}
			}

			// If it's solved (all letters in the word are found in the guessed array), win.
			if(solved) {
				winHangman();
				return;
			}

		}

		// If it wasn't found even once, it's a bad guess.
		else {
			guessedWrong();
		}

		// If the game hasn't ended, print the state.
		if(current_temp.hangman) {
			printState();
		}
	}

	var guessWord = guessed_word => {
		// Check if already guessed.
		if(guessed_words.indexOf(guessed_word) !== -1) {
			send(`"${guessed_word}" was already guessed.`);
			return;
		}

		// Word hasn't been guessed before.
		guessed_words.push(guessed_word);
		if(guessed_word === word.trim().toLowerCase()) {
			winHangman();
			return;
		}
		else {
			guessedWrong();
		}

		// If the word wasn't found and the game isn't lost, print the state.
		if(current_temp.hangman) {
			printState();
		}
	}

	var guessedWrong = () => {
		bad_guesses += 1;
		if(bad_guesses >= GUESS_LIMIT) {
			loseHangman();
		}
	}

	var isAlphaNumeric = string => {
		return /^[a-z0-9]+$/i.test(string);
	}

	var player_id;

	// Process actual user input.
	var await_ID = info.core.setAwait(current_id, (guess_info) => {

		var guess = guess_info.message.content.toLowerCase().trim();
		player_id = guess_info.message.author.id;

		// Only care in the right channel.
		if(guess_info.message.channel.id === info.message.channel.id) {

			// Figure out if the message is a guess.
			if(guess.indexOf(guess_prefix) === 0) {

				// If it was a guess, ignore the author.
				if(player_id === info.message.author.id && !is_DM) {
					send(`You can't play in your own game, <@${guess_info.message.author.id}>.`);
					return;
				}

				guess = guess.split(guess_prefix).join('');
				if(guess.length === 0) {
					return;
				}
				else if(guess.length === 1) {
					guessLetter(guess);
				}
				else {
					guessWord(guess);
				}

				// No matter the kind, add the participant to the list of players.
				if(participants.indexOf(player_id) === -1) {
					participants.push(player_id);
				}
			}

			// If not, maybe it's a state request.
			else if(guess === state_request) {
				printState();
			}

			// If not, maybe the author is trying to quit it.
			else if(guess === quit_request && guess_info.message.author.id === info.message.author.id) {
				send("The current game of hangman has been cancelled. Sorry folks.");
				endHangman();
			}

		}

	}, is_DM);


	// Fire the introduction message.
	if(!is_DM) {
		info.message.author.send(`Started a game of hangman in <#${info.message.channel.id}> (${place_name}). The phrase is "${word}".`);
	}
	printState();
	send(
`To guess a letter or word, use \`${guess_prefix.trim()}\` (the \`g\` stands for guess!). For example: \`${guess_prefix.trim()} a\` or \`${guess_prefix.trim()} minecraft\`.
To see the current state at any point, use \`${state_request}\`.
To quit the current game, use \`${quit_request}\` if you're the one who hosted the game.`
);

}


// Returns a random entry from the given array.
function getRandomEntry(array) {
	return array[Math.floor(Math.random()*array.length)];
}