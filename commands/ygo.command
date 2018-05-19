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
	return `Get information pertaining to a given Yu-Gi-Oh! card. \
					\nUsage: \`${config.prefix}${command} [Yu-Gi-Oh! card name]\``;
}

// Command logic:
/////
// This command uses YGOHub's card database API, found here: https://ygohub.docs.apiary.io
/////

const YGO_ALL_CARDS = "https://www.ygohub.com/api/all_cards";
const YGO_SINGLE_CARD = "https://www.ygohub.com/api/card_info?name=";

/////

const fuzzy = require('fuzzy');
const getJSON = require('get-json');
const queryString = require('querystring');

const LOADING = "loading";
const READY = "ready";

const EVENT_NAME = "ygo_ready";

exports.call = (args, info) => {
	const core = info.core;

	// If we haven't even started loading the card name database, load it up.
	if(!info.temp.ygocards) {
		info.temp.ygocards = {
			"card_names": false,
			"state": LOADING,
		};

		var ygomem = info.temp.ygocards;

		// Request the card name database.
		getJSON(YGO_ALL_CARDS, (err, data) => {

			if(err) {
				failedToConnect(info, err, YGO_ALL_CARDS);
				info.core.removeAllListeners(EVENT_NAME);
				return;
			}

			if(data.status !== "success") {
				failedToConnect(info, `The database returned the status \`${data.status}\`.`, YGO_ALL_CARDS);
				info.core.removeAllListeners(EVENT_NAME);
				return;
			}

			ygomem.card_names = data.cards;
			ygomem.state = READY;

			core.log(`Successfully loaded the Yu-Gi-Oh card name database.`, "log");
			core.emit(EVENT_NAME);

		});

		core.log(`Started loading the Yu-Gi-Oh card name database from "${YGO_ALL_CARDS}".`, "log");
	}


	// If the ygo database is currently loading, requeue this command for when it's finished.
	var ygomem = info.temp.ygocards;

	if(ygomem.state === LOADING) {
		core.once(EVENT_NAME, () => {
			core.callCommand(info.command, args, info.message);
		});
		return;
	}

	// If the ygo database is ready, search the actual API.
	else if(ygomem.state === READY) {

		// If there are no arguments, either return nothing if it was a hook or complain.
		if(args.length === 0) {
			if(info.hook) {
				return;
			} else {
				return "Give me a card name.";
			}
		}

		// Fuzzy search a card in the database.
		var search_string = args.join(" ");
		var results = fuzzy.filter(search_string, ygomem.card_names).map(el => { return el.string; });
		
		// If no results, complain.
		if(results.length === 0) {
			return `Couldn't find any cards called \`${search_string}\`.`;
		}


		// If more than one result, prepare the "amounts found" string.
		var amount_string = undefined;
		if(results.length >= 2) {
			// Check if the best result is the literal hit. For prep vs pre-prep.
			if(results[0].toLowerCase() !== search_string.toLowerCase().trim()) {
				amount_string = `Found ${results.length - 1} more results for \`${search_string}\`. If this is not the right card, be more specific.`;
			}
		}


		// Get the single card's info.
		const single_url = `${YGO_SINGLE_CARD}${queryString.escape(results[0])}`;

		getJSON(single_url, (err, data) => {

			if(err) {
				failedToConnect(info, err, single_url);
				return;
			}

			if(data.status !== "success") {
				failedToConnect(info, `The database returned the status \`${data.status}\`.`, single_url);
				return;
			}

			var card = data.card;


			var card_color = undefined;
			var card_main_icon = undefined;
			var card_subtitle = "";

			// Get color and icons.
			// Monsters have attributes and different types.
			if(card.is_monster) {
				// Icon is attribute.
				card_main_icon = card.attribute;

				/////
				// Color.

				// God card exceptions.
				if(["Obelisk the Tormentor", "Slifer the Sky Dragon", "The Winged Dragon of Ra", "The Winged Dragon of Ra - Immortal Phoenix", "The Winged Dragon of Ra - Sphere Mode"]
						.indexOf(card.name) !== -1) {
					if(card.name === "Obelisk the Tormentor") {
						card_color = 0x6666FF;
					}	else if(card.name === "Slifer the Sky Dragon") {
						card_color = 0xFF0000;
					}	else if(card.name.indexOf("The Winged Dragon of Ra") !== -1) {
						card_color = 0xFFFF33;
					}
				}

				// Generic colors.
				else if(card.is_xyz) {
					card_color = 0x131313;
				}
				else if(card.is_synchro) {
					card_color = 0xCCCCCC;
				}
				else if(card.is_fusion) {
					card_color = 0xA086B7;
				}
				else if(card.is_link) {
					card_color = 0x074D84;
				}
				else if(card.monster_types.indexOf("Ritual") !== -1) {
					card_color = 0x9DB5CC;
				}
				else if(card.monster_types.indexOf("Normal") !== -1) {
					card_color = 0xFDE68A;
				}
				else { // Effect monsters.
					card_color = 0xFF8B53;
				}

			// Spells and traps are simple.
			} else {
				if(card.is_spell) {
					card_main_icon = "SPELL";
					card_color = 0x1D9E74;

				} else if(card.is_trap) {
					card_main_icon = "TRAP";
					card_color = 0xBC5A84;
				}
			}




			/////
			// Card type or level.

			// If non-link, show stars.
			if(card.is_monster) {

				if(!card.is_link) {
					card_subtitle = card.stars;

					if(card.is_xyz) {
						card_subtitle = `Rank ${card_subtitle}`;
					}
					else {
						card_subtitle = `Level ${card_subtitle}`;
					}

				// If link card, show rating.
				} else {
					card_subtitle = `Link Rating ${card.link_number}`;
				}

			}
			else {
				card_subtitle = `${card.property} ${card.type} Card`;
			}


			var card_icon = {
				"SPELL": "https://vignette.wikia.nocookie.net/yugioh/images/e/e2/SPELL.png",
				"TRAP": "https://vignette.wikia.nocookie.net/yugioh/images/c/cf/TRAP.png",

				"DARK": "https://vignette.wikia.nocookie.net/yugioh/images/5/55/DARK.png",
				"DIVINE": "https://vignette.wikia.nocookie.net/yugioh/images/6/6c/DIVINE.png",
				"EARTH": "https://vignette.wikia.nocookie.net/yugioh/images/3/31/EARTH.png",
				"FIRE": "https://vignette.wikia.nocookie.net/yugioh/images/6/6d/FIRE.png",
				"LIGHT": "https://vignette.wikia.nocookie.net/yugioh/images/f/f5/LIGHT.png",
				"WATER": "https://vignette.wikia.nocookie.net/yugioh/images/f/f0/WATER.png",
				"WIND": "https://vignette.wikia.nocookie.net/yugioh/images/c/c3/WIND.png",
			}[card_main_icon];

			// Build card basic meta.
			var card_embed = core.makeEmbed()
				// Meta data.
				.setColor(card_color)

				.setURL(`https://yugioh.wikia.com/wiki/${card.number}`)
				.setAuthor(card.name, card_icon, `https://yugioh.wikia.com/wiki/${card.number}`)

				.setDescription(`[${card_subtitle}]\n\u200B`)

				.setThumbnail(card.thumbnail_path)

				.setFooter("Data provided by YGOHub.com")
				;

			/////
			// Content fields.

			// Pendulum specific fields.
			if(card.is_monster && card.is_pendulum) {
				card_embed
					.addField("Left Scale", card.pendulum_left, true)
					.addField("Right Scale", card.pendulum_right, true)
					.addField("Pendulum Effect", `${card.pendulum_text}\n\u200B`, true)
					;
			}

			// Effect field.
			var effect_header = `Effect`;
			if(card.is_monster) {
				card.monster_types.unshift(card.species);
				effect_header = `[${card.monster_types.join(" / ")}]`
			}

			var card_text = card.text;
			// Add materials to text if monster has them.
			if(card.has_materials) {
				card_text = `${card.materials}\n\n${card_text}`;
			}

			// Italicize normal monster's text.
			if(card.is_monster && card.monster_types.indexOf("Normal") !== -1) {
				card_text = `*${card_text}*`;
			}

			card_embed
				.addField(effect_header, `${card_text}\n\u200B`)
				;


			// Stats.
			if(card.is_monster) {
				var right_title = "Defense";
				var right_value = undefined;
				// Links have no def, but rather show rating.
				if(card.is_link) {
					right_title = "Link";
					right_value = card.link_number;
				}
				else {
					right_value = card.defense;
				}


				card_embed
					.addField("Attack", card.attack, true)
					.addField(right_title, `${right_value}\n\u200B`, true)
					;
			}

			// Send the embed and the rest of the listings.
			info.message.channel.send({embed: card_embed})
			.then(() => {
				if(amount_string) {
					info.message.channel.send(amount_string);
				}
			});

		});

	}

}





// If we failed to connect to the card database, remove all dependencies on it and complain.
function failedToConnect(info, err, url) {
	info.core.log(`Could not reach Yu-Gi-Oh card database. Error: ${err}.`, "error");
	info.message.channel.send(`Could not reach Yu-Gi-Oh card database at ${url}, sorry. Error: \`\`\`${err}\`\`\`.`);
}