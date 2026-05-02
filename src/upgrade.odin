package game

import "core:fmt"

UpgradeKind :: enum {
	trainee,
	data_entry_worker,
	junior_data_scientist,
	data_leak_purchase,
	internet_crawler,
}

UpgradeEnhancement :: union #no_nil {
	UpgradeEnhancementTPS,
	UpgradeEnhancementMoneyRatio,
}

UpgradeEnhancementTPS :: struct {
	amount: f64,
}

UpgradeEnhancementMoneyRatio :: struct {
	amount: f64,
}

Upgrade :: struct {
	kind:                UpgradeKind,
	one_time_buy:        bool,
	enhancement:         UpgradeEnhancement,
	cost:                i32,
	cost_increase_ratio: i32,
	bought:              i32,
}

upgrade_name :: proc(kind: UpgradeKind) -> string {
	switch kind {
	case .trainee:
		return "Trainee"
	case .data_entry_worker:
		return "Data Entry Worker"
	case .junior_data_scientist:
		return "Junior Data Scientist"
	case .data_leak_purchase:
		return "Data Leak Purchase"
	case .internet_crawler:
		return "Internet Crawler"
	}

	return ""
}

upgrade_buy :: proc(u: ^Upgrade) {
	u.bought += 1

	switch s in u.enhancement {
	case UpgradeEnhancementTPS:
		game.tokens_per_second += s.amount
	case UpgradeEnhancementMoneyRatio:
		game.money_token_ratio += s.amount
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
	enhancement = UpgradeEnhancementTPS{amount = .5},
	one_time_buy = false,
	cost = 10,
	cost_increase_ratio = 1,
}

UPGRADE_DATA_ENTRY_WORKER := Upgrade {
	kind = .data_entry_worker,
	enhancement = UpgradeEnhancementTPS{amount = 1.5},
	one_time_buy = false,
	cost = 50,
	cost_increase_ratio = 5,
}

UPGRADE_JUNIOR_DATA_SCIENTIST := Upgrade {
	kind = .junior_data_scientist,
	enhancement = UpgradeEnhancementMoneyRatio{amount = .1},
	one_time_buy = false,
	cost = 250,
	cost_increase_ratio = 25,
}

UPGRADE_DATA_LEAK_PURCHASE := Upgrade {
	kind = .data_leak_purchase,
	enhancement = UpgradeEnhancementMoneyRatio{amount = 0.75},
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
	UPGRADE_JUNIOR_DATA_SCIENTIST,
	UPGRADE_INTERNET_CRAWLER,
	UPGRADE_DATA_LEAK_PURCHASE,
}
