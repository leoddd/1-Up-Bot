//////////////////////////////
// leod's Discord bot. Made for charlotte's server, then expanded for 1-Up World. https://discord.gg/mario
/////
// TODO TODO TODO Hangman games timing out lead to repeated "it's cancelled" messages.
//
// CONFIG
// ----------
// To get the bot up and running, you will have to create a text file named "token.dat" in the "config" directory and fill it with nothing but your bots' API token.
// All of this bot's settings are found in config.json. All options under GUILD CONFIG can be overridden per-guild using the config command. Short explanations:
// GUILD CONFIG:
//  prefix: The prefix needed to activate the bots' command. If it's set to "m!", then a message has to start with "m!" to activate the bot.
//  ignore_bots: If this is true, the bot will never respond to other bots. If false, it will (but not itself).
//
//  use_hierarchy: If this is true, then only staff members can use critical commands that may affect the bot. Uses the setting below to determine who is.
//  staff_perms: The permission level a user needs to be considered "staff" by the bot. Calculate: https://finitereality.github.io/permissions-calculator
//
//  mention_markov: If true, mentioning the bot's name or @ing it will make it respond with a markov chain.
//  random_markov: If true, the bot will, at random, use the 'markov' command using peoples' messages, without a prefix.
//  markov_min_messages: How many messages need to be between each random markov command, if enabled.
//  markov_chance:  The chance, in percent, of triggering a markov response.
//  markov_chance_increase: How much the chance should rise with each passing message. This makes it so the bot never gets too comfortable.
//  markov_max_length: Maximum amount of letters a random markov response can return.
//  markov_default_max_words: Maximum amount of words a random markov response can return.
//  markov_output_pings: Whether the bot will store pings in memory. Can get annoying!
//
//  faction_max_messages: How many messages will count towards the point gaining algorithm until the cooldown is up.
//  faction_cooldown: How long, in minutes, to wait before reseting the messages sent by a user to 0 in the faction algorithm.
//  faction_points_per_message: How many points every message adds to a faction. This should usually be a very low number, like 0.001.
//
//  allow_hooks: Whether the bot is allowed to listen to specific strings that aren't its prefix in messages.
//
//  use_global_censors: Whether to use the global list of censored words to filter out markov data.
//
// GLOBAL CONFIG:
//  markov_data_limit: How many lines the markov data files are supposed to contain. This is not an absolute limit, but will be worked around.
//
//  max_hooks_per_message: The maximum amount of times any hook will iterate over a given message, to prevent infinite loops in case of severe error.
//
//  global_censored_words: A list of words that the markov machine will not feed itself, so as to avoid the bot repeating bad words.
//
//  save_interval: How often to write memory to disc, in minutes. As a failsafe the bot always saves on quit.
//  guild_data_timeout_hours: How many hours it takes until a guild's data is deleted once the bot leaves it. Don't set too low or an outage will delete data!
//
//  command_dir: The directory that contains all of the bots' command files. See below for explanation.
//  parser_dir: The directory that contains all of the bots' parser files. See below for explanation.
//  global_dir: The directory that contains all global data, like the persistent bot memory file.
//  guilds_dir: The directory that contains only guild specific data, like the markov data files.
//  memory_file: Where to store the bots' memories. Inside "global_dir".
//  markov_file: Where to store all markov data collected from guilds. Inside "guilds_dir/flake".
//  base_markov_data: The full, relative path to the markov base file.
//  token_string: The full, relative path to the file that contains your bots' login token.
//
//  owner_id: Discord ID of the bot's owner (probably you!).
//
/////
//
// PARSERS
// ----------
// How this bot responds to any messages is determined by its parser files, all stored in the parser_dir specified in config.json.
// Each of these parser files has to be in the form of a node.js module, exporting a 'parse' function.
// This function's signature looks as follows:
//  function parse(info)
//   info: An object with information about the current bot state. Keys:
//    memory: The global memory object the bot posesses. Kept between reboots.
//    temp: The temporary memory object the bot posesses. Deleted upon reboot.
//    message: Discord.js's Message object. Represents the message that triggered this command, if it is a command.
//    bot: Discord.js Client object. Represents the bot.
//    config: The config object.
//    core: A subset of bot_core to expose some functions to commands. Is eventEmitter, look at its definition in init() for functions.
//          Pay special attention to the command* helper functions.
//
// Everything the bot does in response to a Discord message is determined through these, including detecting and running commands or logging.
// You can use the included 'template.parser' file in the config directory as a template for your parsers.
//
/////
//
// COMMANDS
// ----------
// This bot's commands work on a per-file basis, all stored in the directory specified in config.json.
// Each of these command files has to be in the form of a node.js module, exporting a 'call' function.
// This function's signature looks as follows:
//  function call(args, info)
//   args: Arguments passed in by the user, like "m!markov arguments are these words"
//   info: An object with information about the current bot state. Keys:
//     memory: The global memory object the bot posesses. Can be manipulated by returning a "memory" dict in the response.
//     message: Discord.js's Message object. Represents the message that triggered this command, if it is a command.
//     command: The name of the command being called, if it is a command.
//     hook: If set, the command was called through a message hook instead of an explicit command.
//     bot: This file.
//     config: The config object.
//     core: A subset of bot_core to expose some functions to commands. Is eventEmitter, look at its definition in init() for functions.
//           Pay special attention to the command* helper functions.
//
// The function has to either return a plain string that will be sent to the channel or return a response object, structured as explained below.
// You can use the included 'template.command' file in the config directory as a template for your commands.
//
/////
//
// RESPONSES
// ----------
// Response object for command files:
//	{
//		"log": "String to print to the console.",
//		
//		"msg": "Visible message returned to the user.",
//		"msgOptions": {A MessageOptions object as defined here: https://discord.js.org/#/docs/main/stable/typedef/MessageOptions},
//		"private": true/false whether to respond in the channel or a DM,
//
//		"signals": [Array of signal strings to trigger specific bot events. These are different from core functions in that they are guaranteed to run at the end of the current command output.],
//	}
//
/////
//
// Commands can return "signals". A signal is simply a string that the core will react to as it receives the response.
// Existing signals:
//  reload: Refreshes the command list.
//  reset: Resets the whole bot, running clean up and init all over.
//  quit: Quits and disconnects the bot entirely.
//
/////

(function() {

	/////////////
	// Generic imports.
	const Discord = require('discord.js');
	const fs = require('fs-extra');
	const cleanup = require('node-cleanup');
	const randRange = require('random-floating');
	const events = require('events');
	const toHumanTime = require('human-readable-time');
	const longTimeout = require('long-timeout');
	const censorString = require('censoring');
	const Notifier = require('node-notifier');


	/////////////
	// Setup data.
	const config = JSON.parse(fs.readFileSync('./config/config.json', 'utf8'));

	var blocking_input = true;
	var memory_loaded = false;

	var bot = undefined;
	var save_interval = undefined;
	var last_log_type = undefined;
	var core = undefined;

	const basePath = `${__dirname}/`;

	// Initial memory.
	var commands = {};
	var parsers = {};

	var memory = {
		"users": {},
		"channels": {},
		"guilds": {},

		"activity": {
			"string": "",
			"type": "PLAYING",
		},

		"timeouts": {},
	};
	var temp = {};

	/////////////
	// Private functions.

	// Initializes the entire bot.
	function init() {
		log("Booting...", "boot");

		// Create bot client.
		bot = new Discord.Client();
		hookUpBot();

		// Initialize temp memory.
		temp = {
			"users": {},
			"channels": {},
			"guilds": {},

			"timeouts": {},
		};

		// Create directories if they do not exist.
		if(!fs.existsSync(config.command_dir)) fs.mkdirSync(config.command_dir);
		if(!fs.existsSync(config.guilds_dir)) fs.mkdirSync(config.guilds_dir);
		if(!fs.existsSync(config.global_dir)) fs.mkdirSync(config.global_dir);

		// Load up all commands and parsers.
		reloadParsers();
		reloadCommands();

		// Load memory from disc.
		loadMemorySync();


		// Set up new secure core to pass to functions.
		core = new events.EventEmitter();
		core.basePath = basePath;

		core.log = log;
		core.notify = notify;
		core.callCommand = callCommand;
		core.callFuncAsCommand = callFuncAsCommand;
		core.hasCommand = hasCommand;
		core.listCommands = listCommands;
		core.getCommandLevel = getCommandLevel;
		core.getCommandDefaultLevel = getCommandDefaultLevel;
		core.getHelpString = getHelpString;

		core.resetFactionMessages = resetFactionMessages;
		core.clearFaction = clearFaction;
		core.makeEmbed = makeEmbed;
		core.makeGuildDir = makeGuildDir;
		core.deleteGuildDataUnlessPresent = deleteGuildDataUnlessPresent;

		core.isByBotAdmin = isByBotAdmin;
		core.isByStaffMember = isByStaffMember;
		core.isPublic = isPublic;
		core.hasCommandPermission = hasCommandPermission;
		core.hasLevel = hasLevel;

		core.getCurrentName = getCurrentName;
		core.getNewID = getNewID;
		core.randRange = randRange;
		core.makeArrayOfWords = makeArrayOfWords;

		core.msToInterval = msToInterval;
		core.setPersistentTimeout = setPersistentTimeout;
		core.clearPersistentTimeout = clearPersistentTimeout;
		core.setHook = setHook;
		core.clearHook = clearHook;
		core.setAwait = setAwait;
		core.clearAwait = clearAwait;

		core.commandSwitch = commandSwitch;
		core.commandBundle = commandBundle;


		// Save memory to disc at an interval.
		save_interval = setInterval(commitMemory, config.save_interval * 60000);

		// Log in!
		try {
			const token = fs.readFileSync(config.token_string, 'utf8');
			bot.login(token);
		} catch(err) {
			log(`Could not find a valid token at '${config.token_string}'.
				\nMake sure to create a text file with that name, at that location, that contains just your Discord API token.
				\nIf you don't know how to find your Discord API token, head on over to https://discordapp.com/developers/applications/me and create a new bot there.`,
				"error");
		}
	}

	// Cleans up the bot and logs out.
	function exit() {
		log("Cleaning up...", "shutdown");

		// Do not take any input any more, so as to not interfere with shutting down.
		blocking_input = true;

		// Clear the save interval.
		clearInterval(save_interval);

		// Kill old event handler.
		core = undefined;

		// Save memory to disc.
		commitMemorySync();

		// Destroy bot client and log out!
		bot.destroy();

		log("Done cleaning up.", "shutdown");
	}

	// Latches our necessary behavior functions onto the bot's events.
	function hookUpBot() {
		bot.on("ready", () => {

			// Set the terminal title.
			setTerminalTitle(bot.user.tag);

			// Create data directory for every guild the bot is a part of.
			bot.guilds.array().forEach(guild => {
				makeGuildDir(guild);
				initializeGuildMemory(guild);
			});
			// Create channel memory for every channel the bot is a part of.
			bot.channels.array().forEach(channel => {
				initializeChannelMemory(channel);
			});

			// Load up hooks.
			reviveAllHooks();

			// Set status to online.
			bot.user.setStatus("online");

			// Restore "playing" state from memory.
			bot.user.setActivity(memory.activity.string, {type: memory.activity.type});

			// Clear all queued deletion timers if the bot is in that server now.
			verifyQueuedDeletions();

			// Load all persistent timeouts. Needs to be on ready, because it may want to send messages immediately.
			reviveAllPersistentTimeouts();

			// Start allowing input now that the bot is fully ready.
			blocking_input = false;

			log(`Bot has started. Tag: ${bot.user.tag} - Guilds: ${bot.guilds.size}`, "boot");
			if(bot.guilds.size === 0) {

				bot.generateInvite(["ADD_REACTIONS", "SEND_MESSAGES", "EMBED_LINKS", "ATTACH_FILES", "USE_EXTERNAL_EMOJIS", "CHANGE_NICKNAME", "MANAGE_ROLES"])
				.then(link => {
					log(`To invite the bot into your first server, visit this link: ${link}`, "first time");
				});

			}
		});


		// When a guild is joined.
		bot.on("guildCreate", guild => {
			// Create guild_data directory.
			makeGuildDir(guild);
			initializeGuildMemory(guild);

			// If there's a guild memory deletion queued up, cancel it.
			clearDeletion(guild.id);

			log(`Joined guild ${guild.name} (id: ${guild.id}) with ${guild.memberCount} users.`, "guild action")
		});

		// When a guild is left, or during an outage, queue a timer to delete its data.
		bot.on("guildDelete", guild => {

			// When leaving a guild, set a persistent timer to delete it and its channels' data.
			memory.guilds[guild.id].queued_deletion = setPersistentTimeout({
				"name": "deleteGuildDataUnlessPresent",
				"args": guild.id,
				"type": "core",
			}, config.guild_data_timeout_hours * 3600000);

			log(`Removed from guild ${guild.name} (id: ${guild.id}). Data will be deleted in ${config.guild_data_timeout_hours} hours, unless the guild is rejoined.`, "guild action");
		});


		bot.on("channelCreate", channel => {
			if(channel.guild) {
				// Create channel memory.
				initializeChannelMemory(channel);

				log(`Entered channel "${channel.name}" (id: ${channel.id}).`, "guild action");
			}
		});

		bot.on("channelDelete", channel => {
			if(channel.guild) {
				updateGuildChannelList(channel.guild.id);
			}

			const guild_subtext = channel.hasOwnProperty("guild") ? ` in guild ${channel.guild.name} (id: ${channel.guild.id})` : "";

			log(`Removed from channel ${channel.name} (id: ${channel.id})${guild_subtext}.`, "guild action");
		});


		/////////////
		// Command handler.

		bot.on("message", async message => {

			// If input is turned off, let's not confuse ourselves.
			if(blocking_input) {
				return;
			}

			// Ignore self.
			if(message.author.id === bot.user.id) {
				return;
			}

			// Create local config to use for the command that is affected by guild config overrides.
			var guild_config = getGuildConfig(message.guild);

			// Ignore other bots if set to do so in the config.
			if(message.author.bot && guild_config.ignore_bots) {
				return;
			}

			// If the message went through, attempt to create temp memory for this guild.
			var guild_id = undefined;

			if(message.guild) {
				guild_id = message.guild.id;
				if(message.guild !== null && !temp.guilds.hasOwnProperty(guild_id)) {
					temp.guilds[guild_id] = {};
				}
			}

			// Apply censors to the message content, so we don't have the bot going around telling slurs.
			message.content = applyCensors(message.content, message.guild);

			// Don't act on the message if the bot is muted in the channel.
			if(isChannelMuted(message.channel) !== true) {

				Object.keys(parsers).forEach(parser_name => {
					parsers[parser_name].parse({"memory": memory, "temp": temp, "message": message, "bot": bot, "config": guild_config, "core": core});
				});

			}

		});

	}


	// Calls a command of the given name with the given arguments (array), operating using the given message object.
	function callCommand(command, args, message, is_hook = false, silent = false, check_aliases = true) {

		// If muted in channel, don't.
		if(isChannelMuted(message.channel)) {
			return false;
		}

		var guild_config = getGuildConfig(message.guild);

		// If the command does not exist, return false.
		if(!hasCommand(command) && (!check_aliases || !hasAlias(message.guild, command))) {
			message.channel.send(`I don't know of any \`${command}\` command. Use \`${guild_config.prefix}help\` to see a list of commands.`);
			return false;
		}

		// If it's an alias, run the associated command.
		if(!hasCommand(command)) {
			var guild_mem = memory.guilds[message.guild.id];
			return callCommand(guild_mem.command_aliases[command].command, guild_mem.command_aliases[command].args, message, false, false, false);
		}

		// If it's a command, check for permissions and then run it.
		else if(hasCommandPermission(command, message)) {
			var args_string = args.join(" ");

			try {
				var response = commands[command].call(args, {"memory": memory, "temp": temp, "message": message, "bot": bot, "config": guild_config, "core": core, "command": command, "hook": is_hook});
				handleCommandResponse(response, message, silent);
			} catch(err) {
				handleCommandResponse({
					"msg": `Command \`${command} ${args_string}\` failed. Oops!`,
					"log": `Command \`${command} ${args.join(" ")}\` threw an error:\n\n${err.stack}`
				}, message, silent);
				notify(`[${timestamp(new Date())}] Command \`${command} ${args.join(" ")}\` threw an error. Check terminal at timestamp for details.`, true, true, "error");
			}

			return true;
		}

		// If permission is not given, complain.
		else {
			message.channel.send(`You are not authorized to run \`${command}\`. It's \`${getCommandLevel(command, message)}\` only.`);
			return false;
		}

	}

	// Runs a function and handles its return value like any command.
	function callFuncAsCommand(fnc, args, message, silent = false) {
		// If muted in channel, don't.
		if(isChannelMuted(message.channel)) {
			return false;
		}

		// Passes the same arguments as it would to a command.
		var guild_config = getGuildConfig(message.guild);
		var response = fnc(args, {"memory": memory, "temp": temp, "message": message, "bot": bot, "config": guild_config, "core": core});
		handleCommandResponse(response, message, silent);
		return true;
	}

	// Makes the bot react to the response object passed in.
	function handleCommandResponse(response, message, silent = false) {

		// If the response was not an object, post the return instead.
		if(response instanceof Object !== true) {
			response = {"msg": response};
		}

		// Print log.
		if(response.log) {
			log(response.log, "log");
		}

		// Post message.
		if(silent !== true && (response.msg || response.msgOptions)) {
			response.msg = response.msg || "";
			response.msgOptions = response.msgOptions || undefined;

			// DM
			if(message.channel.type != "text" || response.private === true) {
				message.author.send(response.msg, response.msgOptions);
			}

			// Public
			else {
				message.channel.send(response.msg, response.msgOptions);
			}

		}

		// Parse core signals.
		if(response.signals) {
			if(!response.signals instanceof Array) {
				response.signals = [response.signals];
			}

			response.signals.forEach( signal => {
				handleSignal(signal);
			});
		}

	}



	// Get all available message parsers by reading each from its own .command file.
	function reloadCommands() {
		var com_files = fs.readdirSync(config.command_dir);

		// Hack to always reload the reload command first.
		if(com_files.indexOf("reload.command") !== -1) {
			reloadCommand("reload.command");
			com_files.splice(com_files.indexOf("reload.command"), 1);
		}

		// Reload the rest of the commands.
		com_files.forEach(reloadCommand);
	}

	// Reloads the command at the given path.
	function reloadCommand(path) {
		const command_name = path.replace(/\..+$/, '').toLowerCase();

		// Delete module from cache (if it existed), then re-require it.
		delete require.cache[require.resolve(`${config.command_dir}${path}`)];
		const command_file = require(`${config.command_dir}${path}`);

		// See if we can actually call this module.
		if('call' in command_file && typeof command_file.call === 'function') {
			commands[command_name] = command_file;
			log(`Added command ${command_name}.`, "commands");
		} else {
			log(`Could not add command ${command_name}, no exported 'call' function.`, "commands");
		}
	}

		// Get all available commands by reading each from its own .parser file.
	function reloadParsers() {
		var par_files = fs.readdirSync(config.parser_dir);

		par_files.forEach(reloadParser);
	}

	// Reloads the command at the given path.
	function reloadParser(path) {
		const parser_name = path.replace(/\..+$/, '').toLowerCase();

		// Delete module from cache (if it existed), then re-require it.
		delete require.cache[require.resolve(`${config.parser_dir}${path}`)];
		const parser_file = require(`${config.parser_dir}${path}`);

		// See if we can actually use this parser.
		if('parse' in parser_file && typeof parser_file.parse === 'function') {
			parsers[parser_name] = parser_file;
			log(`Added parser ${parser_name}.`, "parsers");
		} else {
			log(`Could not add parter ${parser_name}, no exported 'parse' function.`, "parsers");
		}
	}


	// Returns the help string associated with a given command file.
	// If the command isn't found or has no help string, returns undefined.
	function getHelpString(command, message) {
		var cur_command = commands[command];

		// If the help property exists and is a string, return it.
		if(cur_command && cur_command.hasOwnProperty("help") && typeof(cur_command.help) === 'function') {
			return cur_command.help(getGuildConfig(message.guild), command, message, core);
		}

		// Else, return nothing.
		else {
			return;
		}
	}



	// Handles core signals returned by functions.
	function handleSignal(signal) {
		switch(signal) {
			case "reset":
				blocking_input = true;
				require("child_process").spawn(process.argv.shift(), process.argv, {
					cwd: process.cwd(),
					detached : true,
					stdio: "inherit",
				});
				process.exit();
				break;

			case "reload_commands":
				reloadCommands();
				break;

			case "reload_parsers":
				reloadParsers();
				break;

			case "quit":
				blocking_input = true;
				setTimeout(process.exit, 1500);
				break;

		}
	}


	// Loads memory from disc into the global 'memory' object. No async version as this only happens on boot.
	function loadMemorySync() {
		memory_loaded = true;

		try {
			// Check if memory file exists.
			fs.accessSync(`${config.global_dir}${config.memory_file}`, fs.constants.R_OK | fs.constants.W_OK);

			// If a memory file exists, read it.
			Object.assign(memory, JSON.parse(fs.readFileSync(`${config.global_dir}${config.memory_file}`, 'utf8')));
		}

		catch(err) {
			// If no memory file exists yet, create one.
			log(`Memory file \`${config.global_dir}${config.memory_file}\` could not be found or accessed (error: ${err}). Will create fresh.`, "memory")
			commitMemorySync();
		}
	}

	// Saves 'memory' object to disc asynchronously.
	function commitMemory() {
		if(memory_loaded === false) {
			log(`Didn't commit memory because no memory has been loaded yet, danger of overwriting exists.`);
			return;
		}

		fs.writeFile(`${config.global_dir}${config.memory_file}`, JSON.stringify(memory), (err) => {
			if(err) {
				log(`Memory could not be saved. Error: ${err}`, "memory");
			} else {
				log(`Saved memory to "${config.global_dir}${config.memory_file}".`, "memory");
			}
		});
	}

	// Saves 'memory' object to disc, blocking. Used during cleanup on program exit.
	function commitMemorySync() {
		if(memory_loaded === false) {
			log(`Didn't commit memory because no memory has been loaded yet, danger of overwriting exists.`);
			return;
		}

		fs.writeFileSync(`${config.global_dir}${config.memory_file}`, JSON.stringify(memory));
		log(`Saved memory to "${config.global_dir}${config.memory_file}".`, "memory");
	}




	// Creates a data directory for the given guild ID.
	function makeGuildDir(guild) {
		var data_path = `${config.guilds_dir}${guild.id}/`;
		if(!fs.existsSync(data_path)) fs.mkdirSync(data_path);
	}

	// Deletes all data related to the given guild.
	function deleteGuildData(guild_id) {
		// Delete guild_data directory.
		const data_path = `${config.guilds_dir}${guild_id}/`;
		if(fs.existsSync(data_path)) fs.removeSync(data_path);

		// Delete guild memories.
		if(memory.guilds.hasOwnProperty(guild_id)) {

			// Before killing memory, also delete channel memories.
			memory.guilds[guild_id].channel_ids.forEach(channel_id => {
				if(memory.channels.hasOwnProperty(channel_id)) {
					delete memory.channels[channel_id];
				}
			});

			delete memory.guilds[guild_id];
		}
		if(temp.guilds.hasOwnProperty(guild_id)) {
			delete temp.guilds[guild_id];
		}

		log(`Deleted guild data for guild ID ${guild_id}.`, "guild data");
	}

	// Wrapper for the above that first checks if the bot is currently inside that guild.
	// If so, do not forget after all.
	function deleteGuildDataUnlessPresent(guild_id) {
		if(bot.guilds.get(guild_id) === undefined) {
			deleteGuildData(guild_id);
		}
	}

	// Loops through all guilds the bot is in and deletes their deletion timeouts, if any are present.
	function verifyQueuedDeletions() {
		// Loop through all guilds the bot is in.
		bot.guilds.forEach((guild, guild_id) => {
			clearDeletion(guild_id);
		});
	}

	// Clears the deletion of the given guild id's data, if one is queued.
	function clearDeletion(guild_id) {
		// Check if the guild has registered memory, including a deletion timer.
		if(memory.guilds.hasOwnProperty(guild_id) && memory.guilds[guild_id].hasOwnProperty("queued_deletion")) {
			clearPersistentTimeout(memory.guilds[guild_id].queued_deletion);
			delete memory.guilds[guild_id].queued_deletion;
		}
	}


	// Update the array of channel IDs that the guild has saved.
	function updateGuildChannelList(guild_id) {
		var guild_mem = memory.guilds[guild_id];
		if(guild_mem) {
			var guild_cache = bot.guilds.get(guild_id);
			if(guild_cache) {
				memory.guilds[guild_id].channel_ids = guild_cache.channels.keyArray();
			}
		}
	}


	// Initializes the given guilds' memory if needed.
	function initializeGuildMemory(guild) {
		if(!memory.guilds.hasOwnProperty(guild.id)) {
			memory.guilds[guild.id] = {};
		}
		if(!temp.guilds.hasOwnProperty(guild.id)) {
			temp.guilds[guild.id] = {};
		}

		// Update the guild's channel ID list.
		updateGuildChannelList(guild.id);
	}

	// Initializes the given channels' memory if needed.
	function initializeChannelMemory(channel) {
		if(!memory.channels.hasOwnProperty(channel.id)) {
			memory.channels[channel.id] = {};
		}
		if(!temp.channels.hasOwnProperty(channel.id)) {
			temp.channels[channel.id] = {};
		}

		// Update channel list the guild has.
		if(channel.guild) {
			updateGuildChannelList(channel.guild.id)
		}
	}

	// Returns the default config object.
	function getDefaultConfig() {
		return config;
	}

	// Creates a new object that contains the guilds' config overrides.
	function getGuildConfig(guild) {
		// If we are not in a guild or if the guild has no overrides, return the global config.
		if(!guild) {
			return config;
		}
		if(!memory.guilds[guild.id].hasOwnProperty("config_override")) {
			return config;
		}

		// If overrides exist, apply them to our new dummy object.
		var guild_config = Object.assign({}, config);
		Object.assign(guild_config, memory.guilds[guild.id].config_override);

		return guild_config;
	}

	// Whether the given channel object is currently muted to the bot.
	function isChannelMuted(channel) {
		if(channel.type === "dm") {
			return false;
		}
		return memory.channels[channel.id].muted_in;
	}

	// Get currently visible name of the given user object.
	function getCurrentName(user, guild) {
		var member = guild.members.get(user.id)
		if(!member) {
			return user.username;
		}
		
		return member.nickname ? member.nickname : user.username;
	}


	// Log the given string to the console, prepending timestamp as well as inserting separators.
	// If the type parameter is different from the last time log was called (unless undefined), a separator is inserted.
	// If notify is true, the log will also be put out as a notification bubble.
	function log(string, type, notify = false) {
		if(last_log_type !== type && type !== undefined) {
			// Print separator if this is a new type of log.
			const COLUMNS = process.stdout.columns;
			const header = type.toUpperCase();
			const halfSeparator = "-".repeat( ((process.stdout.columns) - (2 + header.length)) / 2 );

			console.log(`\n${halfSeparator} ${header} ${halfSeparator}`);

			// Remember type of log.
			last_log_type = type;
		}

		// Log the actual string.
		var string_to_log = `[${timestamp(new Date())}] ${string}`;
		console.log(string_to_log);

		// If notify is true, display a notification toast.
		if(notify === true) {
			notify(string_to_log);
		}
	}

	// Display the given string as an OS notification bubble/toast.
	// If wait is true, the notification will stick until dismissed by hand.
	// Type is the type of notification. Possible: info, warn, error.
	// If sound is true, a sound will play on OSX and Windows. If it is a path to a sound file, that will play.
	function notify(string, wait = false, sound = true, type = "info") {
		Notifier.notify({
			"title": bot.user.tag,
			"subtitle": "Discord Bot",
			"message": string,
			"wait": wait,
			"timeout": wait ? 127800 : 0,
			"sound": sound,
			"type": type,
		}, function(err, response) {});
	}

	// Returns the given date object in human time.
	function timestamp(date) {
		return toHumanTime(date, '%DD%.%MM%.%YY% %hh%:%mm%:%ss%');
	}


	// Sets a persistent timeout that will be called even if the bot is restarted in the meantime.
	// The func_descriptor object can look as follows:
	// {
	//  "name": Name of the core function or command. For example, if you want to call log(), then "log".
	//  "args": JSON-valid arguments for the function or command. This means no function references etc.
	//  "type": 'core' or 'command', depending on whether you want to call a function or a command.
	//
	//  "message": If available, the message that triggered this function. This MUST be given if type is 'command'.
	//             Note that this will simply be stored as a channel + message ID pair to the JSON.
	// }
	function setPersistentTimeout(func_descriptor, in_ms) {
		// Generate a unique timer key for this timeout.
		var time_key = getNewID(memory.timeouts);

		// If message exists, sanitize it for JSON.
		if(func_descriptor.hasOwnProperty("message")) {
			func_descriptor.message = {
				"channel": func_descriptor.message.channel.id,
				"message": func_descriptor.message.id,
			};
		}

		memory.timeouts[time_key] = {"func_descriptor": func_descriptor, "time": new Date().getTime() + in_ms};

		// After storing the persistent timeout, revive it immediately to execute on it in this session.
		revivePersistentTimeout(time_key);

		return time_key;
	}

	// Deletes the given timeout.
	function clearPersistentTimeout(time_key) {
		// Clear this session's revived temp timeout.
		if(temp.timeouts.hasOwnProperty(time_key)) {
			longTimeout.clearTimeout(temp.timeouts[time_key]);
			delete temp.timeouts[time_key];
		}

		// Clear persistent memory of the timeout.
		if(memory.timeouts.hasOwnProperty(time_key)) {
			delete memory.timeouts[time_key];
		}
	}

	// "Revives" the timeout with the given ID.
	function revivePersistentTimeout(time_key) {
		if(!memory.timeouts.hasOwnProperty(time_key)) {
			return;
		}

		var func_descriptor = memory.timeouts[time_key].func_descriptor;

		func_descriptor.type = func_descriptor.type || "command";

		// Use the data differently depending on the type.
		var func_to_call = () => {
			// Different callback depending on `func_descriptor.type`.
			var possible_types = {
				// If type is core, call it as a function on core.
				core: () => {
					if(core.hasOwnProperty(func_descriptor.name) && typeof(core[func_descriptor.name]) === "function") {
						core[func_descriptor.name](func_descriptor.args);
					} else {
						log(`Core function "${func_descriptor.name}" does not exist, timeout ${time_key} failed.`, "timers")
					}
				},


				// If type is undefined or "command", call it as a bot command. func_descriptor.message NEEDS to exist here, as the bot will use it to decide where to post.
				command: () => {
					if(!bot.channels.get(func_descriptor.message.channel)) {
						return;
					}

					if(commands.hasOwnProperty(func_descriptor.name)) {

						// If the descriptor has a message attached, convert it back from the ID pair to a message object.
						var channel = bot.channels.get(func_descriptor.message.channel);

						if(!channel) {
							log(`Could not find the channel for timeout ${time_key}. Timeout failed.`, "timers");
							return;
						}

						channel.fetchMessage(func_descriptor.message.message)
							.then(message => {
								callCommand(func_descriptor.name, func_descriptor.args, message, true);
							})
							.catch(err => {
								log(`Could not fetch message ${func_descriptor.message.message} in channel ${func_descriptor.message.channel}, timeout ${time_key} failed. Error: "${err}".`, "timers")
							});
					} else {
						log(`Command "${func_descriptor.name}" does not exist, timeout ${time_key} failed.`, "timers")
					}
				},

			};

			// If the type given exists, execute on it.
			if(possible_types.hasOwnProperty(func_descriptor.type)) {
				possible_types[func_descriptor.type]();
			}

			// If we passed a garbage type, log the error and clear the timeout anyway.
			else {
				log(`"${func_descriptor.type}" is not a valid type for a persistent timeout's \`func_descriptor.type\`.`, "timers");
			}


			// After calling the function as requested, clear the timeout forever.
			clearPersistentTimeout(time_key);
		};


		// Calculate when the timeout function should be called.
		const time_until = memory.timeouts[time_key].time - new Date().getTime();

		// If the time for the timeout already passed, catch up immediately.
		if(time_until <= 0) {
			func_to_call();
		}

		// If time for timeout hasn't happened yet, set the timeout properly!
		else {
			temp.timeouts[time_key] = longTimeout.setTimeout(func_to_call, time_until);
		}

	}

	// Loads all set persistent timeouts into memory on load.
	function reviveAllPersistentTimeouts() {
		Object.keys(memory.timeouts).forEach(time_key => {
			revivePersistentTimeout(time_key);
		});
	}



	// Sets a hook that will match a given regex to all incoming messages and call commands in response.
	// The func_descriptor object can look as follows:
	// {
	//  "command": Name of the command. For example, to call the "say" command, it's "say".
	//  "args": JSON-valid arguments for the command. This means no function references etc.
	//  "regex_string": The string passed into the regex constructor.
	//  "regex_options": The options passed into the regex constructor.
	//
	//  "guild": The ID of the guild this hook shall be active in. Not a full guild object!
	// }
	function setHook(hook) {
		// Create hooks memory if needed.
		var guild_id = hook.guild;
		var guild_mem = memory.guilds[guild_id];
		delete hook.guild;
		if(!guild_mem.hasOwnProperty("hooks")) {
			guild_mem.hooks = {};
		}

		// Check if hook by that regex already exists.
		if(guild_mem.hooks.hasOwnProperty(hook.regex_string)) {
			return false;
		}

		// Save hook and activate it.
		guild_mem.hooks[hook.regex_string] = hook;

		reviveHook(guild_id, hook.regex_string);

		return true;
	}

	// Permanently removes the given hook in the given guild.
	function clearHook(guild_id, regex_string) {
		// Remove permanent memory.
		var perm_hooks = memory.guilds[guild_id].hooks;
		if(perm_hooks && perm_hooks[regex_string]) {
			delete perm_hooks[regex_string];
		}

		// Remove temporary memory.
		var temp_hooks = temp.guilds[guild_id].hooks;
		if(temp_hooks && temp_hooks[regex_string]) {
			delete temp_hooks[regex_string];
		}

	}

	// "Revives" the hook with the given ID.
	function reviveHook(guild_id, regex_string) {
		var hook = memory.guilds[guild_id].hooks[regex_string];

		// Create our regex object to match against.
		var regex_options = hook.regex_options;


		var regex_obj = new RegExp(hook.regex_string, regex_options);

		var guild_temp = temp.guilds[guild_id];
		if(!guild_temp.hasOwnProperty("hooks")) {
			guild_temp.hooks = {};
		}

		guild_temp.hooks[regex_string] = {
			"regex": regex_obj,
			"command": hook.command,
			"args": hook.args,
		};
	}

	// Loads all set hooks into each guild memory on load.
	function reviveAllHooks() {
		bot.guilds.keyArray().forEach(guild_id => {
			var guild_mem = memory.guilds[guild_id];

			// If this guild has no hooks, return.
			if(!guild_mem.hasOwnProperty("hooks")) {
				return;
			}

			// Run through every hook and revive it.
			Object.keys(guild_mem.hooks).forEach(key => {
				reviveHook(guild_id, key);
			});
		});

	}



	// Sets an await that will run every message from the given guild past a given callback function until it is cleared.
	// If is_DM is true, it will await DM messages instead of guild messages.
	// Returns an ID for use with clearAwait().
	// The callback function's signature looks as follows:
	// function (awaitedInfo, clearThisAwait)
	//  awaitedInfo: All of the info relevant to the message being checked. This is equal to the info object passed into a parser, not a command.
	//  clearThisAwait: Shorthand for clearAwait(ID). Calling this inside of the callback will cause the set await to be cleared.
	function setAwait(id, callback, is_DM = false) {
		if(typeof callback !== 'function') {
			log(`Callback passed into setAwait is not a function. Callback: ${callback}`, "error");
			return null;
		}

		// Create await memory if there isn't any.
		var awaits;
		if(is_DM !== true) {
			var guild_temp = temp.guilds[id];
			if(!guild_temp.hasOwnProperty("awaits")) {
				guild_temp.awaits = {};
			}
			awaits = guild_temp.awaits;
		}
		else {
			var user_temp = temp.users[id];
			if(!user_temp) {
				temp.users[id] = {};
				user_temp = temp.users[id];
			}
			if(!user_temp.hasOwnProperty("awaits")) {
				user_temp.awaits = {};
			}
			awaits = user_temp.awaits;
		}

		// Store the new await.
		var await_ID = getNewID(awaits);

		awaits[await_ID] = callback;

		return await_ID;
	}

	// Permanently removes the given await by its ID in the given guild.
	function clearAwait(id, await_ID, is_DM = false) {

		var awaits;
		if(is_DM !== true) {
			awaits = temp.guilds[id].awaits;
		}
		else {
			awaits = temp.users[id];
			if(!awaits.hasOwnProperty("awaits")) {
				return;
			}
			awaits = temp.users[id].awaits;
		}


		if(awaits && awaits[await_ID]) {
			delete awaits[await_ID];

			// If that was the last await, clear the memory entirely.
			if(Object.keys(awaits).length === 0) {
				if(!is_DM) {
					delete temp.guilds[id].awaits;
				} else {
					delete temp.users[id].awaits;
				}
			}
		}

	}




	// Returns a random key that doesn't exist in the passed object yet.
	// size is the length of the key.
	function getNewID(obj, size) {

		size = size || 7;

		var id = "";
		var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789&-_+#§$!?][}{)(";

		// Repeat until ID is a new property to the object.
		while(id === "" || obj.hasOwnProperty(id)) {
			for (var i = 0; i < size; i++) {
				id += chars.charAt(Math.floor(Math.random() * chars.length));
			}
		}

		return id;
	}


	// Resets the amount of messages sent for the faction algorithm for the given user.
	// The passed `ids` dict needs a "guild" and a "user" key that point towards the respective guild and user snowflake ID.
	function resetFactionMessages(ids) {
		var guild_mem = memory.guilds[ids.guild];
		if(guild_mem === undefined || !guild_mem.hasOwnProperty("faction_messages_sent") || !guild_mem.faction_messages_sent.hasOwnProperty(ids.user)) {
			return;
		}

		delete guild_mem.faction_messages_sent[ids.user];
		return true;
	}


	// Deletes all the data for a given faction.
	function clearFaction(guild, name) {
		var guild_mem = memory.guilds[guild.id];

		if(guild_mem.hasOwnProperty("factions") && guild_mem.factions.hasOwnProperty(name)) {
			delete guild_mem.factions[name];
			if(Object.keys(guild_mem.factions).length === 0) {
				delete guild_mem.factions;
			}
		}
	}



	// Splits a string into a stripped array of words.
	// Slices off `sliced` characters at the front.
	function makeArrayOfWords(str, sliced = 0) {
		return str.slice(sliced).trim().split(/ +/g);
	}

	// Returns the time difference between two unix timestamps as a human readable string.
	function msToInterval(currentTimestamp, remoteTimestamp) {

		const timeFrames = [
			/*	
				Each entry helps the loop below figure out what to display exactly.
				name: Name of the current detail level, will be displayed in the timeString.
				min: How big the difference has to be at least for this entry to grip. difference is in seconds.
				eatDetails: If this is false, this level of granularity will not take a detail slot.
				            For example, we pretty much always want days to display along weeks for a precise date.
			*/
			{
				"name": "year",
				"min": 31536000,
				"eatDetails": true
			},
			{
				"name": "month",
				"min": 2592000,
				"eatDetails": true
			},
			{
				"name": "week",
				"min": 604800,
				"eatDetails": false
			},
			{
				"name": "day",
				"min": 86400,
				"eatDetails": true
			},
			{
				"name": "hour",
				"min": 3600,
				"eatDetails": true
			},
			{
				"name": "minute",
				"min": 60,
				"eatDetails": true
			},
			{
				"name": "second",
				"min": 1,
				"eatDetails": true
			},
		];

		// Returns the "x time ago" string from the given unix timestamps.
		var diff = currentTimestamp - remoteTimestamp;
		var absDiff = Math.abs(Math.round(diff / 1000)); // Only interested in seconds.

		if (absDiff < 1) {
			return "Just now";
		}

		var detailsLeft = 3; // How many timeFrames we want to keep going down before finishing the string.
		var exhaustDetails = false; // If true, only detailsLeft amount of further details will be processed.

		// Prepare the timeString pieces.
		var timePieces = [];
		for (var i = 0; i < timeFrames.length; i++) {
			if (exhaustDetails || absDiff >= timeFrames[i].min) {
				var numberOfFrames = Math.floor(absDiff / timeFrames[i].min);

				detailsLeft -= 1;
				if (detailsLeft < 0) { // If this timeFrame would exceed the defined maximum, stop.
					break;
				}

				if (!timeFrames[i].eatDetails) {
				// After we checked if this should stop, increase the counter if this entry does not use a slot,
				// so that the next one will be bundled with it. (eg. "months, weeks" is bad, "weeks, days" is good.)
					detailsLeft += 1;
				}

				if (numberOfFrames <= 0) {
					continue;
				}

				exhaustDetails = true;

				var plural = numberOfFrames != 1 ? "s" : "";

				timePieces.push(numberOfFrames + " " + timeFrames[i].name + plural);
				absDiff -= numberOfFrames * timeFrames[i].min;
			}
		}
		// Assemble the timeString.
		var timeString = "";
		for (i = 0; i < timePieces.length; i++) {
			var separator;

			if (i == 0) {
				separator = "";
			} else if (i == timePieces.length - 1) {
				separator = " and ";
			} else {
				separator = ", ";
			}

			timeString += separator + timePieces[i];
		}



		// Add pre- or postfix.
		if(diff < 0) {
			timeString = timeString + " from now";
		} else {
			timeString = timeString + " ago";
		}

		return timeString;

	}


	// Allows passing of a command's arguments as well as a dictionary of functions.
	// Then it will call the appropriate function from the dictionary by using the first argument, passing the rest.
	// If there's no callback for the argument or just no argument given, it'll attempt calling the "default" key.
	function commandSwitch(args, dictionary) {
		var com_switch = "default";

		if(args.length !== 0) {
			com_switch = args.shift();
		}

		if(dictionary.hasOwnProperty(com_switch)) {
			return dictionary[com_switch](args);
		} else if(dictionary.hasOwnProperty("default")) {
			return dictionary["default"](args);
		} else {
			return undefined;
		}

	}

	// Similar to commandSwitch, but will instead call all functions in the dictionary that are ANY argument.
	// All functions are called parameter-less.
	// Returns a dictionary of return values (where each return value uses the arg used as key).
	function commandBundle(args, dictionary) {
		if(args.length === 0) {
			args = ["default"];
		}

		var results = {};

		args.forEach(argument => {

			if(dictionary.hasOwnProperty(argument)) {
				results[argument] = dictionary[argument]();
			}

		});

		return results;
	}


	// Applies censors to the given string and returns it. If a guild is given, it will use the guild's custom censors as well.
	function applyCensors(string_to_censor, guild) {
		var censor = new censorString();
		censor.enableFilter('words');
		censor.setReplacementString('');
		censor.addFilterWords(getGuildCensors(guild));

		return censor.filterString(string_to_censor);
	}


	// Returns an array of all global as well as guild-specific censored words.
	function getGuildCensors(guild) {
		// If we are not in a guild, return the global config.
		if(!guild) {
			return config.global_censored_words;
		}

		// If the guild exists, start with a fresh array.
		var guild_mem = memory.guilds[guild.id];
		var guild_config = getGuildConfig(guild);
		var word_array = [];

		// If the guild has its own censors, add them.
		if(guild_mem.hasOwnProperty("custom_censored_words")) {
			word_array = word_array.concat(guild_mem.custom_censored_words);
		}

		// If the guild uses global censors, add them.
		if(guild_config.use_global_censors === true) {
			word_array = word_array.concat(config.global_censored_words);
		}

		return word_array;
	}


	// Checks if the message was sent by the bot owner, used for commands that affect many guilds, such as quitting.
	function isByBotAdmin(message) {
		// Check if it's the owner's ID.
		return message.author.id === config.owner_id ? true : false;
	}

	// Checks if the message was sent by a staff member on the server.
	function isByStaffMember(message) {
		// Check if the author fulfills the guild-specific staff requirement.
		var guild_config = getGuildConfig(message.guild);
		return !guild_config.use_hierarchy || message.member.permissions.has(guild_config.staff_perms);
	}

	// Returns whether the message given is in a public channel accessible by everyone.
	function isPublic(message) {
		// If the message isn't in a guild, it's not public.
		if(!message.guild || !message.channel) {
			return;
		}

		// Check if the @everyone role is denied read permissions in this channel.
		var perms = message.channel.permissionOverwrites.get(message.guild.defaultRole.id);
		if(perms && (perms.deny & Discord.Permissions.FLAGS.READ_MESSAGES) !== 0) {
			return false;
		}
		else {
			return true;
		}
	}

	// Returns a RichEmbed object.
	function makeEmbed() {
		return new Discord.RichEmbed();
	}

	// Returns whether a command of the given name exists.
	function hasCommand(command) {
		return commands.hasOwnProperty(command);
	}

	// Returns whether the given guild has an alias under the given name.
	function hasAlias(guild, alias_name) {
		var guild_mem = memory.guilds[guild.id];
		if(guild_mem.command_aliases && guild_mem.command_aliases.hasOwnProperty(alias_name)) {
			return true;
		}
		return false;
	}

	// Returns an array of command names.
	function listCommands() {
		return Object.keys(commands);
	}

	// Gets the DEFAULT authority level for a given command.
	function getCommandDefaultLevel(command) {
		return commands[command].level;
	}

	// Gets the authority level for a given command.
	function getCommandLevel(command, message) {
		if(hasCommand(command)) {

			var com_level = commands[command].level;
			if(!com_level) {
				return "all";
			}

			// Read in guild overrides, if they exist.
			if(message.guild) {
				var guild_mem = memory.guilds[message.guild.id];
				if(guild_mem && guild_mem.hasOwnProperty("command_levels") && guild_mem.command_levels.hasOwnProperty(command)) {
					com_level = guild_mem.command_levels[command];
				}
			}

			return com_level;

		}
	}

	// Returns whether or not the given guild member is allowed to use the given command.
	function hasCommandPermission(command, message) {
		var com_level = getCommandLevel(command, message);

		return hasLevel(com_level, message);
	}

	// Returns whether the given message fulfills the given level of authority.
	function hasLevel(level, message) {
		switch(level) {
			case "all":
				return true;

			case "staff":
				return isByStaffMember(message);

			case "admin":
				return isByBotAdmin(message);

			default:
				return true;
		}
	}


	// Sets the terminal's title to the given string.
	function setTerminalTitle(title) {
	  process.stdout.write( String.fromCharCode(27) + "]0;" + title + String.fromCharCode(7) );
	}

	/////////////
	// Handle memory saving on bot exit.
	cleanup(exit);


	/////////////
	// Boot!
	init();

})();