extends RefCounted
class_name GameBalance

const MIN_ALLY_CHANCE := 0.15
const MAX_ALLY_CHANCE := 0.85
const MAX_STREAK_DECAY := 0.38
const GLOBAL_ALLY_CHANCE_PENALTY := 0.06
const PRESSURE_PER_ROUND := 0.04
const ALLY_LOSS_BONUS := 0.15
const BLOCK_SPLASH_RATE := 0.30
const LOW_HP_FEAR_THRESHOLD := 0.30
const LOW_HP_FEAR_PENALTY := 0.10
const REROLL_REVERSE_CHANCE := 0.35
const DEBUFF_TURNS := 3
const JOKER_TAUNT_MULTIPLIER := 2.5

const HERO_MUM_HEAL := 1
const ALLY_MUM_HEAL := 2
const HERO_THANK_HEAL := 2
const ALLY_THANK_HEAL := 12
const HERO_ATM_LEAVE_HEAL := 4
const ALLY_DEAD_LEAVE_HEAL := 8
const HERO_ZZZZ_REST_HEAL := 12
const ALLY_JOKER_HEAL := 20
const HERO_IMSB_HEAL := 2
const HERO_MALO_HEAL := 8
const ALLY_MALO_HEAL := 8
const SHIT_HEAL_RATIO := 0.80
const MONK_EMPTY_PENALTY := -0.20
const SHIT_CHARM_BOOST := 0.10

const RARITY_DATA := {
	"N": {
		"label": "N",
		"stars": "★☆☆☆",
		"color": "#b0b8c0",
		"ally_mod": 1.00,
		"pick_weight": 4.0,
	},
	"R": {
		"label": "R",
		"stars": "★★☆☆",
		"color": "#4ade80",
		"ally_mod": 1.00,
		"pick_weight": 3.0,
	},
	"SR": {
		"label": "SR",
		"stars": "★★★☆",
		"color": "#818cf8",
		"ally_mod": 0.92,
		"pick_weight": 2.0,
	},
	"SSR": {
		"label": "SSR",
		"stars": "★★★★",
		"color": "#fbbf24",
		"ally_mod": 0.85,
		"pick_weight": 1.0,
	},
}

const DIRECT_ENEMY_DAMAGE := {
	"OJBK": 10,
	"ATM-er": 18,
	"Dior-s": 22,
	"GOGO": 8,
	"LOVE-R": 28,
	"WOC!": 15,
	"SHIT": 22,
	"ZZZZ": 10,
	"POOR": 12,
	"IMSB": 18,
	"FUCK": 30,
	"IMFW": 10,
}

const EMPTY_CAMP_PUNISH_DAMAGE := {
	"CTRL": 12,
	"THAN-K": 15,
	"MUM": 15,
	"SEXY": 12,
}

const CHARACTER_OVERRIDES := {
	"CTRL": {
		"hp": 58,
		"rarity": "R",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "随机移除你阵营中一个伙伴；若无伙伴则造成12HP"
			}
		}
	},
	"ATM-er": {
		"hp": 60,
		"rarity": "R",
		"ally_blocks": 2,
		"skills": {
			"hero": {
				"description": "每当伙伴离队时回复4HP"
			},
			"enemy": {
				"description": "扣18HP，且下一张牌强制成为敌人"
			}
		}
	},
	"Dior-s": {
		"hp": 62,
		"rarity": "R",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "扣22HP，但翻完后奖励你一次窥视机会"
			}
		}
	},
	"BOSS": {
		"hp": 50,
		"rarity": "R",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "随机封锁你一个伙伴槽位3回合"
			}
		}
	},
	"THAN-K": {
		"hp": 65,
		"rarity": "R",
		"ally_blocks": 1,
		"skills": {
			"hero": {
				"description": "每翻到一张伙伴回复2HP"
			},
			"ally": {
				"description": "入队时回复12HP"
			},
			"enemy": {
				"description": "不造成伤害，但你阵营中最新入队的伙伴被移除；若无伙伴则造成15HP"
			}
		}
	},
	"OH-NO": {
		"hp": 52,
		"rarity": "N",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "接下来3张牌的伙伴概率各-15%"
			}
		}
	},
	"GOGO": {
		"hp": 60,
		"rarity": "R",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "先造成8HP，并强制你下回合连翻两张牌"
			}
		}
	},
	"SEXY": {
		"hp": 48,
		"rarity": "SR",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "随机移除你阵营中一个伙伴；若无伙伴则造成12HP"
			}
		}
	},
	"LOVE-R": {
		"hp": 58,
		"rarity": "SR",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "扣28HP"
			}
		}
	},
	"MUM": {
		"hp": 55,
		"rarity": "R",
		"ally_blocks": 1,
		"skills": {
			"hero": {
				"description": "每回合开始时自动回复1HP"
			},
			"ally": {
				"description": "在阵营中时每回合为你回复2HP"
			},
			"enemy": {
				"description": "不直接伤害你，但随机消耗你一个伙伴；若无伙伴则造成15HP"
			}
		}
	},
	"FAKE": {
		"hp": 55,
		"rarity": "N",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "伪装成伙伴入队占据槽位；在之后的2次翻牌结算后暴露，造成15点基础伤害并离队"
			}
		},
	},
	"OJBK": {
		"hp": 68,
		"rarity": "N",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "造成10HP伤害后离开"
			}
		}
	},
	"MALO": {
		"hp": 72,
		"rarity": "N",
		"ally_blocks": 1,
		"skills": {
			"hero": {
				"description": "每回合翻牌前等概率触发：回复8HP / 扣10HP / 无事发生"
			},
			"ally": {
				"description": "入队时等概率触发：回复8HP / 扣5HP / 窥视一张牌"
			}
		}
	},
	"JOKE-R": {
		"hp": 70,
		"rarity": "SR",
		"ally_blocks": 1,
		"skills": {
			"ally": {
				"description": "若你当前HP低于30%，入队时回复20HP"
			},
			"enemy": {
				"description": "下一个遇到的敌人伤害提升至×2.5"
			}
		}
	},
	"WOC!": {
		"hp": 60,
		"rarity": "R",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "先扣15HP后，有35%概率反转为伙伴入队"
			}
		}
	},
	"THIN-K": {
		"hp": 42,
		"rarity": "N",
		"ally_blocks": 1,
	},
	"SHIT": {
		"hp": 68,
		"rarity": "N",
		"ally_blocks": 1,
		"skills": {
			"hero": {
				"description": "受到敌人伤害时，记录该伤害的30%，用于抵消下一次敌人伤害"
			},
			"ally": {
				"description": "若上一张翻到的是敌人，入队时回复该敌人造成伤害的80%"
			},
			"enemy": {
				"description": "扣22HP，但之后伙伴概率+10%（持续1张牌）"
			}
		}
	},
	"ZZZZ": {
		"hp": 55,
		"rarity": "N",
		"ally_blocks": 2,
		"skills": {
			"hero": {
				"description": "可跳过翻牌改为回复12HP（每局限3次）"
			},
			"enemy": {
				"description": "跳过下一回合，并先承受10HP"
			}
		}
	},
	"POOR": {
		"hp": 80,
		"rarity": "SSR",
		"ally_blocks": 2,
		"skills": {
			"hero": {
				"description": "固定仅有2个伙伴槽位，但每个伙伴可抵挡2次敌人才离队"
			},
			"enemy": {
				"description": "随机封印你一个伙伴槽位3回合，并造成12HP"
			}
		}
	},
	"MONK": {
		"hp": 75,
		"rarity": "SSR",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "移除你身上所有持续性正面效果；若无则伙伴概率-20%持续3张牌，并使HP上限-8"
			}
		}
	},
	"IMSB": {
		"hp": 68,
		"rarity": "N",
		"ally_blocks": 2,
		"skills": {
			"hero": {
				"description": "翻到敌人时额外扣5HP，翻到伙伴时额外回复2HP"
			},
			"ally": {
				"description": "入队后替你抵挡所有敌人攻击，每次抵挡时你扣5HP，抵挡2次后离队"
			},
			"enemy": {
				"description": "扣18HP，并让你下一个翻到的伙伴无法入队"
			}
		}
	},
	"SOLO": {
		"hp": 62,
		"rarity": "N",
		"ally_blocks": 1,
	},
	"FUCK": {
		"hp": 58,
		"rarity": "SR",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "扣30HP，且无法用伙伴抵挡，只能硬扛"
			}
		}
	},
	"DEAD": {
		"hp": 45,
		"rarity": "SR",
		"ally_blocks": 0,
		"skills": {
			"ally": {
				"description": "无法用于抵挡敌人，被替换或移除时回复8HP"
			},
			"enemy": {
				"description": "不造成直接伤害，但HP上限永久-15"
			}
		}
	},
	"IMFW": {
		"hp": 62,
		"rarity": "N",
		"ally_blocks": 1,
		"skills": {
			"enemy": {
				"description": "先扣10HP，且之后你每次受伤额外+5HP（持续2次）"
			}
		}
	},
}


static func decorate_character(character: Dictionary) -> Dictionary:
	var result: Dictionary = character.duplicate(true)
	var code := str(result.get("code", ""))
	var balance: Dictionary = CHARACTER_OVERRIDES.get(code, {})

	for key in balance.keys():
		if key == "skills":
			continue
		result[key] = balance[key]

	if balance.has("skills"):
		if not result.has("skills"):
			result["skills"] = {}
		for face_variant in balance["skills"].keys():
			var face := str(face_variant)
			if not result["skills"].has(face):
				result["skills"][face] = {}
			var face_override: Dictionary = balance["skills"][face]
			for field_variant in face_override.keys():
				var field := str(field_variant)
				result["skills"][face][field] = face_override[field]

	if not result.has("rarity"):
		result["rarity"] = "N"
	if not result.has("ally_blocks"):
		result["ally_blocks"] = 1

	return result


static func get_rarity(character: Dictionary) -> String:
	return str(character.get("rarity", "N"))


static func get_rarity_color(character: Dictionary) -> Color:
	var rarity := get_rarity(character)
	return Color(RARITY_DATA.get(rarity, RARITY_DATA["N"]).get("color", "#b0b8c0"))


static func get_rarity_stars(character: Dictionary) -> String:
	var rarity := get_rarity(character)
	return str(RARITY_DATA.get(rarity, RARITY_DATA["N"]).get("stars", "★☆☆☆"))


static func get_rarity_ally_modifier(character: Dictionary) -> float:
	var rarity := get_rarity(character)
	return float(RARITY_DATA.get(rarity, RARITY_DATA["N"]).get("ally_mod", 1.0))


static func get_rarity_pick_weight(character: Dictionary) -> float:
	var rarity := get_rarity(character)
	return float(RARITY_DATA.get(rarity, RARITY_DATA["N"]).get("pick_weight", 1.0))


static func get_pressure_multiplier(round_number: int) -> float:
	return 1.0 + PRESSURE_PER_ROUND * float(maxi(round_number, 0))


static func get_ally_loss_multiplier(loss_stacks: int) -> float:
	return 1.0 + ALLY_LOSS_BONUS * float(maxi(loss_stacks, 0))


static func scale_enemy_damage(base_damage: int, round_number: int, loss_stacks: int) -> int:
	if base_damage <= 0:
		return 0
	var scaled := float(base_damage) * get_pressure_multiplier(round_number) * get_ally_loss_multiplier(loss_stacks)
	return maxi(1, int(round(scaled)))


static func get_block_splash(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return maxi(1, int(ceil(float(base_damage) * BLOCK_SPLASH_RATE)))


static func get_direct_enemy_damage(code: String) -> int:
	return int(DIRECT_ENEMY_DAMAGE.get(code, 0))


static func get_empty_camp_damage(code: String) -> int:
	return int(EMPTY_CAMP_PUNISH_DAMAGE.get(code, 0))


static func get_base_ally_blocks(character: Dictionary, hero_code: String) -> int:
	var blocks := int(character.get("ally_blocks", 1))
	if hero_code == "POOR":
		blocks = maxi(blocks, 2)
	return blocks
