package game

import "core:fmt"

UpgradeKind :: enum {
	trainee,
	typing_assist,
	data_entry_worker,
	junior_data_scientist,
	data_leak_purchase,
	internet_crawler,
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
		txt = "Trainee"
	case .typing_assist:
		txt = "Typing Assist"
	case .data_entry_worker:
		txt = "Data Entry Worker"
	case .junior_data_scientist:
		txt = "Junior Data Scientist"
	case .data_leak_purchase:
		txt = "Buy Data Leak"
	case .internet_crawler:
		txt = "Internet Crawler"
	}

	purchased_txt: string
	if u.one_time_buy && u.bought > 0 {
		purchased_txt = "SOLD"
	}

	return fmt.aprintf("%s. %s", txt, purchased_txt)
}

upgrade_desc :: proc(u: Upgrade) -> string {
	txt: string
	switch s in u.enhancement {
	case UpgradeEnhancementTPS:
		txt = fmt.aprintf("+ %.1f TPS", s.amount)
	case UpgradeEnhancementMoneyRatio:
		txt = fmt.aprintf("+ %.2f$ per token", s.amount)
	case UpgradeEnhancementTypingAssist:
		txt = fmt.aprintf("+ %.2f automatic typing", s.char_per_second)
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

	fmt.printfln(
		"bought: %d. cost inc ratio: %d, new cost: %d",
		u.bought,
		u.cost_increase_ratio,
		u.cost + (u.bought * u.cost_increase_ratio),
	)

	u.cost += u.bought * u.cost_increase_ratio

	// TODO: enable new upgrades here
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
	enhancement = UpgradeEnhancementTPS{amount = 25.0},
	one_time_buy = false,
	cost = 500,
	cost_increase_ratio = 50,
}

INIT_ENABLED_UPGRADES := []Upgrade {
	UPGRADE_TRAINEE,
	UPGRADE_DATA_ENTRY_WORKER,
	UPGRADE_TYPING_ASSIST,
	UPGRADE_JUNIOR_DATA_SCIENTIST,
	UPGRADE_INTERNET_CRAWLER,
	UPGRADE_DATA_LEAK_PURCHASE,
}
