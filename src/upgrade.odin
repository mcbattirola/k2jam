package game

import "core:fmt"

UpgradeKind :: enum {
	trainee,
	typing_assist,
	data_entry_worker,
	junior_data_scientist,
	data_leak_purchase,
	internet_crawler,
	physical_office,
	employee_mouse_tracker,
	employee_eye_tracker,
	launch_social_media,
	market_push,
	optimize_doomscrolling,
	government_contract,
	deploy_surveillance_drones,
	deploy_military_drones,
	neural_implant_program,
	emotion_reading,
	dream_debugging,
	final_singularity,
}

UpgradeEnhancement :: union #no_nil {
	UpgradeEnhancementTPS,
	UpgradeEnhancementMoneyRatio,
	UpgradeEnhancementTypingAssist,
}

UpgradeEnhancementTPS :: struct {
	amount: f64,
}

UpgradeEnhancementMoneyRatio :: struct {
	amount: f64,
}

UpgradeEnhancementTypingAssist :: struct {
	char_per_second: f32,
}

Upgrade :: struct {
	kind:                UpgradeKind,
	one_time_buy:        bool,
	enhancement:         UpgradeEnhancement,
	cost:                i32,
	cost_increase_ratio: i32,
	bought:              i32,
}

upgrade_name :: proc(u: Upgrade) -> string {
	txt: string

	switch u.kind {
	case .trainee:
		txt = "Hire Trainee"
	case .data_entry_worker:
		txt = "Hire Professional Typer"
	case .junior_data_scientist:
		txt = "Hire Junior Data Scientist"
	case .typing_assist:
		txt = "Typing Assist"
	case .data_leak_purchase:
		txt = "Buy Data Leak"
	case .internet_crawler:
		txt = "Internet Crawler"
	case .physical_office:
		txt = "Physical Office"
	case .employee_mouse_tracker:
		txt = "Employee Mouse Tracker"
	case .employee_eye_tracker:
		txt = "Employee Eye Tracker"
	case .launch_social_media:
		txt = "Launch Social Media"
	case .market_push:
		txt = "Market Push"
	case .optimize_doomscrolling:
		txt = "Optimize Doomscrolling"
	case .government_contract:
		txt = "Government Contract"
	case .deploy_surveillance_drones:
		txt = "Deploy Surveillance Drones"
	case .deploy_military_drones:
		txt = "Deploy Military Drones"
	case .neural_implant_program:
		txt = "Neural Implant Program"
	case .emotion_reading:
		txt = "Emotion Reading"
	case .dream_debugging:
		txt = "Dream Debugging"
	case .final_singularity:
		txt = "Singularity"
	}

	purchased_txt: string
	if u.one_time_buy && u.bought > 0 {
		purchased_txt = "SOLD"
	}

	return fmt.aprintf("%s. %s", txt, purchased_txt)
}

upgrade_desc :: proc(u: Upgrade) -> string {
	if u.kind == .final_singularity {
		return "AGI achieved. You are no longer required."
	}

	txt: string
	switch s in u.enhancement {
	case UpgradeEnhancementTPS:
		txt = fmt.aprintf("+ %.1f TPS", s.amount)
	case UpgradeEnhancementMoneyRatio:
		txt = fmt.aprintf("+ %.2f$ per token", s.amount)
	case UpgradeEnhancementTypingAssist:
		txt = fmt.aprintf("+ %.2f automatic typing", s.char_per_second)
	}

	// additional text
	if u.kind == .physical_office {
		txt = fmt.aprintf("%s. Enables new upgrades.", txt)
	}
	if u.kind == .launch_social_media {
		txt = fmt.aprintf("%s. Enables growth upgrades.", txt)
	}
	if u.kind == .government_contract {
		txt = fmt.aprintf("%s. Enables drone upgrades.", txt)
	}
	if u.kind == .deploy_military_drones {
		txt = fmt.aprintf("%s. Enables neural implant program.", txt)
	}
	if u.kind == .neural_implant_program {
		txt = fmt.aprintf("%s. Enables neural data upgrades.", txt)
	}


	if u.one_time_buy {
		txt = fmt.aprintf("%s. One time buy.", txt)
	}

	return txt
}

upgrade_buy :: proc(u: ^Upgrade) {
	if u.bought > 0 && u.one_time_buy {return}

	if game.money < f64(u.cost) {return}
	game.money -= f64(u.cost)

	u.bought += 1

	switch s in u.enhancement {
	case UpgradeEnhancementTPS:
		game.tokens_per_second += s.amount
	case UpgradeEnhancementMoneyRatio:
		game.money_token_ratio += s.amount
	case UpgradeEnhancementTypingAssist:
		game.auto_type_per_second += s.char_per_second
	}

	u.cost += u.bought * u.cost_increase_ratio

	// enable new events
	if u.bought == 1 {
		if u.kind == .physical_office {
			upgrade_enable_once(UPGRADE_EMPLOYEE_MOUSE_TRACKER)
			upgrade_enable_once(UPGRADE_EMPLOYEE_EYE_TRACKER)
			upgrade_enable_once(UPGRADE_LAUNCH_SOCIAL_MEDIA)
		}

		if u.kind == .launch_social_media {
			append(
				&game.upgrades_available,
				UPGRADE_MARKET_PUSH,
				UPGRADE_OPTIMIZE_DOOMSCROLLING,
				UPGRADE_GOVERNMENT_CONTRACT,
			)
		}

		if u.kind == .government_contract {
			append(
				&game.upgrades_available,
				UPGRADE_DEPLOY_SURVEILLANCE_DRONES,
				UPGRADE_DEPLOY_MILITARY_DRONES,
			)
		}

		if u.kind == .deploy_military_drones {
			append(&game.upgrades_available, UPGRADE_NEURAL_IMPLANT_PROGRAM)
		}

		if u.kind == .neural_implant_program {
			append(
				&game.upgrades_available,
				UPGRADE_EMOTION_READING,
				UPGRADE_DREAM_DEBUGGING,
				UPGRADE_FINAL_SINGULARITY,
			)
		}
	}
}

upgrade_enable_once :: proc(upgrade: Upgrade) {
	for &available in game.upgrades_available {
		if available.kind == upgrade.kind {
			return
		}
	}

	append(&game.upgrades_available, upgrade)
}

UPGRADE_TRAINEE := Upgrade {
	kind = .trainee,
	enhancement = UpgradeEnhancementTPS{amount = .3},
	one_time_buy = false,
	cost = 10,
	cost_increase_ratio = 3,
}

UPGRADE_DATA_ENTRY_WORKER := Upgrade {
	kind = .data_entry_worker,
	enhancement = UpgradeEnhancementTPS{amount = 1.5},
	one_time_buy = false,
	cost = 50,
	cost_increase_ratio = 8,
}

UPGRADE_JUNIOR_DATA_SCIENTIST := Upgrade {
	kind = .junior_data_scientist,
	enhancement = UpgradeEnhancementMoneyRatio{amount = .25},
	one_time_buy = false,
	cost = 200,
	cost_increase_ratio = 25,
}

UPGRADE_TYPING_ASSIST := Upgrade {
	kind = .typing_assist,
	enhancement = UpgradeEnhancementTypingAssist{char_per_second = 8},
	one_time_buy = false,
	cost = 1000,
	cost_increase_ratio = 500,
}


UPGRADE_DATA_LEAK_PURCHASE := Upgrade {
	kind = .data_leak_purchase,
	enhancement = UpgradeEnhancementMoneyRatio{amount = 1.25},
	one_time_buy = true,
	cost = 2000,
}

UPGRADE_INTERNET_CRAWLER := Upgrade {
	kind = .internet_crawler,
	enhancement = UpgradeEnhancementTPS{amount = 15.0},
	one_time_buy = false,
	cost = 500,
	cost_increase_ratio = 50,
}

UPGRADE_PHYSICAL_OFFICE := Upgrade {
	kind = .physical_office,
	enhancement = UpgradeEnhancementMoneyRatio{amount = 1.75},
	one_time_buy = true,
	cost = 5000,
}

INIT_ENABLED_UPGRADES := []Upgrade {
	UPGRADE_TRAINEE,
	UPGRADE_DATA_ENTRY_WORKER,
	UPGRADE_JUNIOR_DATA_SCIENTIST,
	UPGRADE_INTERNET_CRAWLER,
	UPGRADE_TYPING_ASSIST,
	UPGRADE_DATA_LEAK_PURCHASE,
	UPGRADE_PHYSICAL_OFFICE,
}


UPGRADE_EMPLOYEE_MOUSE_TRACKER := Upgrade {
	kind = .employee_mouse_tracker,
	enhancement = UpgradeEnhancementTPS{amount = 25},
	one_time_buy = false,
	cost = 500,
	cost_increase_ratio = 200,
}

UPGRADE_EMPLOYEE_EYE_TRACKER := Upgrade {
	kind = .employee_eye_tracker,
	enhancement = UpgradeEnhancementTPS{amount = 50},
	one_time_buy = false,
	cost = 1000,
	cost_increase_ratio = 500,
}

UPGRADE_LAUNCH_SOCIAL_MEDIA := Upgrade {
	kind = .launch_social_media,
	enhancement = UpgradeEnhancementMoneyRatio{amount = 1.5},
	one_time_buy = true,
	cost = 15000,
}

UPGRADE_MARKET_PUSH := Upgrade {
	kind = .market_push,
	enhancement = UpgradeEnhancementTPS{amount = 40.0},
	one_time_buy = false,
	cost = 5000,
	cost_increase_ratio = 1500,
}

UPGRADE_OPTIMIZE_DOOMSCROLLING := Upgrade {
	kind = .optimize_doomscrolling,
	enhancement = UpgradeEnhancementTPS{amount = 100.0},
	one_time_buy = false,
	cost = 25_000,
	cost_increase_ratio = 2500,
}

UPGRADE_GOVERNMENT_CONTRACT := Upgrade {
	kind = .government_contract,
	enhancement = UpgradeEnhancementMoneyRatio{amount = 3.0},
	one_time_buy = true,
	cost = 100_000,
}

UPGRADE_DEPLOY_SURVEILLANCE_DRONES := Upgrade {
	kind = .deploy_surveillance_drones,
	enhancement = UpgradeEnhancementTPS{amount = 250.0},
	one_time_buy = false,
	cost = 800_000,
	cost_increase_ratio = 10_000,
}


UPGRADE_DEPLOY_MILITARY_DRONES := Upgrade {
	kind = .deploy_military_drones,
	enhancement = UpgradeEnhancementTPS{amount = 750.0},
	one_time_buy = false,
	cost = 4_000_000,
	cost_increase_ratio = 40_000,
}

UPGRADE_NEURAL_IMPLANT_PROGRAM := Upgrade {
	kind = .neural_implant_program,
	enhancement = UpgradeEnhancementMoneyRatio{amount = 5.0},
	one_time_buy = true,
	cost = 500_000,
}

UPGRADE_EMOTION_READING := Upgrade {
	kind = .emotion_reading,
	enhancement = UpgradeEnhancementTPS{amount = 1500.0},
	one_time_buy = false,
	cost = 1_500_000,
	cost_increase_ratio = 12000,
}

UPGRADE_DREAM_DEBUGGING := Upgrade {
	kind = .dream_debugging,
	enhancement = UpgradeEnhancementTPS{amount = 3000.0},
	one_time_buy = false,
	cost = 2_500_000,
	cost_increase_ratio = 25_000,
}

UPGRADE_FINAL_SINGULARITY := Upgrade {
	kind = .final_singularity,
	enhancement = UpgradeEnhancementTPS{amount = 100000.0}, // symbolic, not important
	one_time_buy = true,
	cost = 100_000_000,
}
