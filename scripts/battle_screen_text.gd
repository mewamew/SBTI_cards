extends RefCounted


static func get_ally_status_parts(ally: Dictionary) -> Array[String]:
	var extra: Dictionary = ally.get("extra", {})
	var status_parts: Array[String] = []
	if bool(ally.get("locked", false)):
		status_parts.append("真爱锁定")
	if bool(extra.get("slotless", false)):
		status_parts.append("编外")
	if bool(ally.get("is_spy", false)):
		status_parts.append("间谍")
	var block_count := int(ally.get("blocks", 0))
	if block_count > 0:
		status_parts.append("挡伤 %d 次" % block_count)
	var sleeping_turns := int(ally.get("sleeping", 0))
	if sleeping_turns > 0:
		status_parts.append("休眠 %d 回合" % sleeping_turns)
	var mimic_code := str(extra.get("mimic_code", ""))
	if not mimic_code.is_empty():
		status_parts.append("模仿 %s" % mimic_code)
	return status_parts


static func build_ally_tooltip_text(ally: Dictionary) -> String:
	var character: Dictionary = ally.get("character", {})
	if character.is_empty():
		return ""
	var ally_skill: Dictionary = character.get("skills", {}).get("ally", {})
	var status_parts: Array[String] = get_ally_status_parts(ally)

	var text := ""
	text += "[center][font_size=24][color=#f5e9c8][b]%s · %s[/b][/color][/font_size][/center]\n" % [character.get("code", ""), character.get("name", "")]
	var quote := str(character.get("quote", ""))
	if not quote.is_empty():
		text += "[center][font_size=15][color=#d9c6a2][i]\"%s\"[/i][/color][/font_size][/center]\n\n" % quote
	if not status_parts.is_empty():
		text += "[font_size=15][color=#f0d7a6][b]当前状态[/b][/color]\n[font_size=15][color=#f4e7d0]%s[/color][/font_size]\n\n" % " / ".join(status_parts)
	text += "[font_size=16][color=#9fc7ff][b]队友技能：%s[/b][/color][/font_size]\n" % str(ally_skill.get("name", ""))
	text += "[font_size=15][color=#f3eadb]%s[/color][/font_size]" % str(ally_skill.get("description", ""))
	if bool(ally.get("is_spy", false)):
		text += "\n\n[font_size=15][color=#ffb28f][b]警告[/b][/color]\n[font_size=15][color=#ffd9c8]该伙伴当前处于间谍状态，会在潜伏结束后反噬。[/color][/font_size]"
	return text


static func build_hero_tooltip_text(character: Dictionary, hero_state_text: String = "") -> String:
	if character.is_empty():
		return ""
	var hero_skill: Dictionary = character.get("skills", {}).get("hero", {})
	var hero_skill_name := str(hero_skill.get("name", ""))
	var hero_skill_desc := str(hero_skill.get("description", ""))
	var text := ""
	text += "[center][font_size=24][color=#f5e9c8][b]%s · %s[/b][/color][/font_size][/center]\n" % [character.get("code", ""), character.get("name", "")]
	var quote := str(character.get("quote", ""))
	if not quote.is_empty():
		text += "[center][font_size=15][color=#d9c6a2][i]\"%s\"[/i][/color][/font_size][/center]\n\n" % quote
	if not hero_state_text.is_empty() and hero_state_text != hero_skill_desc:
		text += "[font_size=15][color=#f0d7a6][b]当前状态[/b][/color]\n[font_size=15][color=#f4e7d0]%s[/color][/font_size]\n\n" % hero_state_text
	if not hero_skill_name.is_empty():
		text += "[font_size=16][color=#ffd391][b]主角技能：%s[/b][/color][/font_size]\n" % hero_skill_name
	if not hero_skill_desc.is_empty():
		text += "[font_size=15][color=#f3eadb]%s[/color][/font_size]" % hero_skill_desc
	return text


static func get_ally_avatar_tone(ally: Dictionary) -> Color:
	if bool(ally.get("is_spy", false)):
		return Color("d96c62")
	if bool(ally.get("locked", false)):
		return Color("f0c977")
	if int(ally.get("sleeping", 0)) > 0:
		return Color("8d96a6")
	return Color("63b6e2")


static func get_reveal_display_fate(character: Dictionary, actual_fate: String) -> String:
	if actual_fate == "enemy" and str(character.get("code", "")) == "FAKE":
		return "ally"
	return actual_fate


static func get_reveal_result_log_text(character: Dictionary, actual_fate: String, display_fate: String) -> String:
	if actual_fate == "enemy" and display_fate == "ally" and str(character.get("code", "")) == "FAKE":
		return "%s 伪装成伙伴现身。" % character.get("code", "")
	return "%s 的命运揭晓为 %s。" % [character.get("code", ""), "伙伴" if display_fate == "ally" else "敌人"]


static func format_reveal_state_text(fate_text: String) -> String:
	if fate_text.find("伙伴") >= 0:
		return "✦ 伙伴"
	if fate_text.find("敌") >= 0:
		return "✦ 敌对"
	if fate_text.find("窥视") >= 0:
		return "👁"
	if fate_text.find("三思") >= 0:
		return "↺"
	if fate_text.find("判定中") >= 0:
		return "⋯"
	return "◌"


static func get_reveal_state_color(fate_text: String) -> Color:
	if fate_text.find("伙伴") >= 0:
		return Color("7cc7ff")
	if fate_text.find("敌") >= 0:
		return Color("ff8a72")
	if fate_text.find("窥视") >= 0 or fate_text.find("三思") >= 0:
		return Color("f0c977")
	if fate_text.find("判定中") >= 0:
		return Color("f7efcf")
	return Color("d8c9ae")


static func build_character_modal_text(character: Dictionary, focus_face: String = "") -> String:
	if character.is_empty():
		return ""
	var skills: Dictionary = character.get("skills", {})
	var ally_skill: Dictionary = skills.get("ally", {})
	var enemy_skill: Dictionary = skills.get("enemy", {})
	var text := ""
	text += "[center][font_size=21][color=#fff2cf]%s · %s[/color][/font_size]\n" % [character.get("code", ""), character.get("name", "")]
	text += "[color=#d7b56d]\"%s\"[/color][/center]\n\n" % str(character.get("quote", ""))
	if focus_face == "ally":
		text += "[color=#f0c977]本次会以伙伴身份入队。[/color]\n\n"
	elif focus_face == "enemy":
		text += "[color=#ff9b84]本次会以敌人身份结算。[/color]\n\n"
	text += "[color=#7fcdf2]伙伴面 · %s[/color]\n%s\n\n" % [ally_skill.get("name", ""), ally_skill.get("description", "")]
	text += "[color=#ff9b84]敌对面 · %s[/color]\n%s" % [enemy_skill.get("name", ""), enemy_skill.get("description", "")]
	return text


static func build_recruit_ally_summary_text(ally: Dictionary, section_title: String, accent_color: String, status_label: String) -> String:
	if ally.is_empty():
		return ""
	var character: Dictionary = ally.get("character", {})
	var ally_skill: Dictionary = character.get("skills", {}).get("ally", {})
	var status_parts: Array[String] = get_ally_status_parts(ally)
	var lines: Array[String] = []
	lines.append("[font_size=17][color=%s][b]%s[/b][/color][/font_size]" % [accent_color, section_title])
	lines.append("[font_size=20][color=#fff4d8][b]%s · %s[/b][/color][/font_size]" % [character.get("code", ""), character.get("name", "")])
	if not status_parts.is_empty():
		lines.append("[font_size=14][color=#f4e2ba][b]%s[/b]  %s[/color][/font_size]" % [status_label, " / ".join(status_parts)])
	var skill_name := str(ally_skill.get("name", ""))
	var skill_desc := str(ally_skill.get("description", ""))
	if not skill_name.is_empty():
		lines.append("[font_size=15][color=#9fd4ff][b]队友技能 · %s[/b][/color][/font_size]" % skill_name)
	if not skill_desc.is_empty():
		lines.append("[font_size=14][color=#f6ebcf]%s[/color][/font_size]" % skill_desc)
	if bool(ally.get("is_spy", false)):
		lines.append("[font_size=14][color=#ff9b84][b]警告[/b] 潜伏结束后会反噬。[/color][/font_size]")
	return "\n".join(lines)


static func build_recruit_candidate_text(new_ally: Dictionary) -> String:
	if new_ally.is_empty():
		return ""
	var character: Dictionary = new_ally.get("character", {})
	var ally_skill: Dictionary = character.get("skills", {}).get("ally", {})
	var status_parts: Array[String] = get_ally_status_parts(new_ally)
	var header_parts: Array[String] = [
		"[font_size=16][color=#f0c977][b]新入队伙伴[/b][/color][/font_size]",
		"[font_size=22][color=#fff4d8][b]%s · %s[/b][/color][/font_size]" % [character.get("code", ""), character.get("name", "")],
	]
	if not status_parts.is_empty():
		header_parts.append("[font_size=14][color=#f4e2ba][b]入队状态[/b] %s[/color][/font_size]" % " / ".join(status_parts))

	var lines: Array[String] = ["  [color=#a7804b]·[/color]  ".join(header_parts)]
	var skill_name := str(ally_skill.get("name", ""))
	var skill_desc := str(ally_skill.get("description", ""))
	if not skill_name.is_empty() or not skill_desc.is_empty():
		lines.append("[font_size=15][color=#9fd4ff][b]队友技能 · %s[/b][/color][/font_size]  [font_size=14][color=#f6ebcf]%s[/color][/font_size]" % [skill_name, skill_desc])
	if bool(new_ally.get("is_spy", false)):
		lines.append("[font_size=14][color=#ff9b84][b]警告[/b] 潜伏结束后会反噬。[/color][/font_size]")
	return "\n".join(lines)


static func build_replace_modal_card_text(ally: Dictionary, section_title: String, accent_color: String, status_label: String) -> String:
	if ally.is_empty():
		return ""
	var character: Dictionary = ally.get("character", {})
	var ally_skill: Dictionary = character.get("skills", {}).get("ally", {})
	var status_parts: Array[String] = get_ally_status_parts(ally)
	var lines: Array[String] = [
		"[font_size=14][color=%s][b]%s[/b][/color][/font_size]" % [accent_color, section_title],
		"[font_size=22][color=#fff4d8][b]%s · %s[/b][/color][/font_size]" % [character.get("code", ""), character.get("name", "")],
	]
	if status_parts.is_empty():
		lines.append("[font_size=14][color=#ccb289]%s：无特殊状态[/color][/font_size]" % status_label)
	else:
		lines.append("[font_size=14][color=#f4e2ba]%s：%s[/color][/font_size]" % [status_label, " / ".join(status_parts)])

	var skill_name := str(ally_skill.get("name", ""))
	var skill_desc := str(ally_skill.get("description", ""))
	if not skill_name.is_empty():
		lines.append("[font_size=15][color=#9fd4ff][b]队友技能 · %s[/b][/color][/font_size]" % skill_name)
	if not skill_desc.is_empty():
		lines.append("[font_size=14][color=#f6ebcf]%s[/color][/font_size]" % skill_desc)
	if bool(ally.get("is_spy", false)):
		lines.append("[font_size=14][color=#ffb28f]潜伏结束后会反噬。[/color][/font_size]")
	return "\n".join(lines)


static func build_replace_candidate_brief_text(ally: Dictionary) -> String:
	if ally.is_empty():
		return ""
	var parts: Array[String] = []
	var status_parts: Array[String] = get_ally_status_parts(ally)
	var status_preview: Array[String] = []
	for index in range(mini(status_parts.size(), 2)):
		status_preview.append(status_parts[index])
	if not status_preview.is_empty():
		parts.append(" / ".join(status_preview))
	var character: Dictionary = ally.get("character", {})
	var skill_name := str(character.get("skills", {}).get("ally", {}).get("name", ""))
	if not skill_name.is_empty():
		parts.append(skill_name)
	return " · ".join(parts)


static func sanitize_log_text(message: String) -> String:
	return message.replace("[", "【").replace("]", "】")


static func get_log_style(message: String) -> Dictionary:
	var style: Dictionary = {
		"tag": "战况",
		"tag_color": "#6f7f99",
		"body_color": "#3b475a",
	}
	if message.contains("窥视") or message.contains("三思") or message.contains("命运") or message.contains("牌池") or message.contains("揭示"):
		style["tag"] = "情报"
		style["tag_color"] = "#4f89d8"
		style["body_color"] = "#41556f"
	elif message.contains("回复") or message.contains("治疗") or message.contains("存活") or message.contains("补觉") or message.contains("回光") or message.contains("回馈"):
		style["tag"] = "恢复"
		style["tag_color"] = "#4ba76c"
		style["body_color"] = "#395248"
	elif message.contains("造成") or message.contains("扣") or message.contains("伤害") or message.contains("离队") or message.contains("暴露") or message.contains("减员") or message.contains("上限永久"):
		style["tag"] = "伤害"
		style["tag_color"] = "#d56d63"
		style["body_color"] = "#5b4646"
	elif message.contains("加入了你的阵营") or message.contains("入队") or message.contains("转为伙伴") or message.contains("加入了阵营"):
		style["tag"] = "入队"
		style["tag_color"] = "#4b90ca"
		style["body_color"] = "#3c536d"
	elif message.contains("触发") or message.contains("发动") or message.contains("效果") or message.contains("技能"):
		style["tag"] = "技能"
		style["tag_color"] = "#c59a4b"
		style["body_color"] = "#5c5345"
	elif message.contains("跳过") or message.contains("锁定") or message.contains("封锁") or message.contains("强制") or message.contains("休眠") or message.contains("免疫"):
		style["tag"] = "状态"
		style["tag_color"] = "#7c88a0"
		style["body_color"] = "#485263"
	return style


static func format_log_message(message: String) -> String:
	var style: Dictionary = get_log_style(message)
	var escaped := sanitize_log_text(message)
	return "[font_size=17][color=%s][b]● %s[/b][/color] [color=%s]%s[/color][/font_size]\n" % [
		style["tag_color"],
		style["tag"],
		style["body_color"],
		escaped,
	]


static func get_skill_feedback_palette(source_kind: String) -> Dictionary:
	match source_kind:
		"hero":
			return {
				"bg": Color(0.42, 0.23, 0.06, 0.0),
				"border": Color("ffcf86"),
				"accent": Color("ffe4b4"),
				"shadow": Color(1.0, 0.58, 0.18, 0.28),
			}
		"ally":
			return {
				"bg": Color(0.10, 0.20, 0.38, 0.0),
				"border": Color("8cc8ff"),
				"accent": Color("d6ebff"),
				"shadow": Color(0.18, 0.48, 0.92, 0.24),
			}
		_:
			return {
				"bg": Color(0.34, 0.08, 0.08, 0.0),
				"border": Color("ff9d86"),
				"accent": Color("ffd3c5"),
				"shadow": Color(0.96, 0.28, 0.20, 0.26),
			}


static func get_skill_feedback_title(source_kind: String) -> String:
	match source_kind:
		"hero":
			return "主角技能触发"
		"ally":
			return "队友技能触发"
		_:
			return "敌人技能触发"
