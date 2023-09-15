local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[COLLUSIONIST.name] = "Collusionist"
L["info_popup_" .. COLLUSIONIST.name] = [[You are the Collusionist, now go collude for some weapons!]]
L["body_found_" .. COLLUSIONIST.abbr] = "They were a collusionist :("
L["search_role_" .. COLLUSIONIST.abbr] = "This person was a collusionist"
L["target_" .. COLLUSIONIST.name] = "Collusionist"
L["ttt2_desc_" .. COLLUSIONIST.name] = [[The collusionist is a jester role that will be converted to whoevers team they recieve a bought item from!]]

-- OTHER ROLE LANGUAGE STRINGS
L["label_collusionist_donor_health"] = "Donor Health"
L["help_collusionist_donor_health"] = "The health that someone that drops an item for the collusionist will respawn with."
L["label_collusionist_respawn_health"] = "Respawn Health"
L["help_collusionist_respawn_health"] = "The amount of health the collusionist should respawn with."
L["label_collusionist_kill_policing_roles"] = "Kill Police?"
L["label_col_appear_as_innocent_to_evils"] = "Appear As Innocent To Evils"
L["help_col_appear_as_innocent_to_evils"] = "Makes it so that if a jester would ordinarily be revealed, that it instead goes back to an unknown role."
L["label_col_appear_as_jester"] = "Appear As Jester"
L["help_col_appear_as_jester"] = "Makes it so that if someone would know someone is the collusionist, that they instead appear as a jester."

L["label_collusionist_entity_damage"] = "Can the collusionist damage entities? (Def. 1)"
L["label_collusionist_environmental_damage"] = "Can explode, burn, crush, fall, drown? (Def. 1)"
L["label_collusionist_respawn"] = "Collusionist respawn on death (Def. 1)"
L["label_collusionist_respawn_delay"] = "Collusionist respawn delay (Def. 3)"
L["help_collusionist_respawn_delay"] = "The time it takes for the collusionist to be revived.\nSet to \"0\" to prevent respawning."
L["label_collusionist_reveal_mode"] = "ttt2_collusionist_reveal_mode (Def: 0)"

L["label_collusionist_patch_radar"] = "Fix: Patch Radar"
L["help_collusionist_patch_radar"] = "Allows patching the radar so that returning ROLE_NONE doesn't cause a visual discrepency.\nYou will need this for \"Appear As Innocent To Evils\".\nApplies after mapchange."