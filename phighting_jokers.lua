--- === === === === === === === ---
---       mmmmmmm phighting     ---
--- === === === === === === === ---

-- very very special thanks to the following mods since a lot of my knowledge on how
-- mods work is just from reading how other mods are written lol

-- - Sodanuki Joker Pack
-- - 0 ERROR
-- - Cryptid (slightly)

-- they are also credited in the github page mwehehe

-- also a huge thanks to the VanillaRemade wiki mhehehe

-- button logic
assert(SMODS.load_file("./stuff/jokerbutton.lua"))()

SMODS.Atlas {
    key = "modicon",
    path = "icon.png",
    px = 34,
    py = 34
}

-- some silly phigter colours
G.C.SUBSPACE = HEX("FF0368")
G.C.BANHAMMER = HEX("3A3A82")
G.C.THEBROKER = HEX("46AC74")
G.C.VALK = HEX("F7DB60")
G.C.DOM = HEX("84309E")
G.C.BOOMBOX = HEX("97BF4B")
G.C.GHOSDEERI = HEX("B4DAEF")
G.C.FIREBRAND = HEX("F09642")
G.C.SWORD = HEX("FF5959")
G.C.MEDKIT = HEX("2CBFA2")
G.C.DARKHEART = HEX("9BF74A")

local ref_loc_colour = loc_colour
function loc_colour(_c, _default)
    ref_loc_colour(_c, _default)
    G.ARGS.LOC_COLOURS.subspace = G.C.SUBSPACE
    G.ARGS.LOC_COLOURS.banhammer = G.C.BANHAMMER
    G.ARGS.LOC_COLOURS.thebroker = G.C.THEBROKER
    G.ARGS.LOC_COLOURS.valk = G.C.VALK
    G.ARGS.LOC_COLOURS.dom = G.C.DOM
    G.ARGS.LOC_COLOURS.boombox = G.C.BOOMBOX
    G.ARGS.LOC_COLOURS.ghosdeeri = G.C.GHOSDEERI
    G.ARGS.LOC_COLOURS.firebrand = G.C.FIREBRAND
    G.ARGS.LOC_COLOURS.sword = G.C.SWORD
    G.ARGS.LOC_COLOURS.medkit = G.C.MEDKIT
    G.ARGS.LOC_COLOURS.darkheart = G.C.DARKHEART
    return G.ARGS.LOC_COLOURS[_c] or _default or G.C.UI.TEXT_DARK
end

-- sfx
SMODS.Sound({
    key = 'subspace_boom',
    path = 'subspace_ult_boom.ogg'
})

-- valk & dom moment
local function flipside(key)
    if G.jokers then
        for _, v in ipairs(G.jokers.cards) do
            if v.config.center.key == key then
                return true
            end
        end
    end
    return false
end

-- roger
local function roger()
    if not G.jokers then return false end

    -- check if at least one of each exists
    local roger = next(SMODS.find_card('j_phighting_roger'))
    local rojer = next(SMODS.find_card('j_phighting_rojer'))
    local phestroger = next(SMODS.find_card('j_phighting_phestroger'))

    return roger and rojer and phestroger
end

-- function for ghosdeeri because i did NOT expect this to be so complex
local function get_card_chips(card)
    if card.debuff then return 0 end

    local chips = 0
    -- this should work for modded stuff too i think

    -- base chips (ace = 11, face = 10, etc.)
    chips = chips + card.base.nominal

    -- enhancements (bonus card +30, stone card +50)
    if card.ability and card.ability.bonus then
        chips = chips + card.ability.bonus
    end

    -- editions (foil +50)
    if card.edition and card.edition.chips then
        chips = chips + card.edition.chips
    end

    -- permanent bonuses (hiker and other similar jokers i mightve missed)
    if card.ability and card.ability.perma_bonus then
        chips = chips + card.ability.perma_bonus
    end

    return chips
end

-- BAN HAMMER I'VE REWRITTEN YOUR CODE 8 TIMES ALREADY WHY ARE YOU STILL MAKING GHOST CARDS
-- this function is from sodanuki's jokers pack if you see this message that means it works
-- and i wasted hours on nothing thbwjfghlkjfhdgkldg
local function ban_destroy_card(target_card)
    if target_card and not target_card.getting_sliced then
        target_card.getting_sliced = true

        SMODS.calculate_effect({}, target_card)
        target_card:start_dissolve({G.C.BANHAMMER}, nil, 1.6)
        play_sound('tarot1', 1, 0.8)
    end
end

-- function for talisman / cryptid compat!!!!! because omg cryptid is such a fun mod lol
local function to_num(val)
    if type(val) == 'table' then
        return val:to_number()
    end

    if type(val) == 'string' then
        return tonumber(val) or 0
    end

    return val or 0
end



SMODS.Atlas{
    key = 'phighting_atlas',    -- this is the key for the atlas texture below
    path = 'phighting_jokers.png', -- atlas' path in (yourMod)/assets/1x or (yourMod)/assets/2x
    px = 71,
    py = 95
}

-- JUDGEMENT!!!!! ban hammer mains eating well
SMODS.Joker{
    key = 'banhammer',
    loc_txt = {
        name = 'Judgement',
        text = {
            "Destroys played cards that {C:attention}don't score{}",
            "Gains {X:mult,C:white} X#1# {} Mult for each card destroyed",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult){}",
            "{E:2,C:banhammer}\"Your verdict is... {E:2,C:banhammer,s:1.25}GUILTY!{E:2,C:banhammer}\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 0, y = 1},
    rarity = 3,                 -- rarity, common > uncommon > rare > legendary
    cost = 10,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,      -- can it be eternal

    -- start at X1 Mult (which does nothing) and add 0.2 per kill
    config = { extra = { gain = 0.2, current_xmult = 1 } },

    loc_vars = function(self, info_queue, center)
        return { vars = { 
            center.ability.extra.gain,          -- #1#
            center.ability.extra.current_xmult  -- #2#
        }}
    end,

    calculate = function(self, card, context)

        -- apply the XMult during the hand calculation
        if context.joker_main then
            return {
                message = "X" .. card.ability.extra.current_xmult,
                Xmult_mod = card.ability.extra.current_xmult,
                card = card
            }
        end

        -- run this AFTER the hand calculation
        if context.after and not context.blueprint then
            
            -- identify who's gettin banned first
            -- don't destroy them yet, just make a list of them
            local cards_to_destroy = {}
            
            for i = 1, #G.play.cards do
                local played_card = G.play.cards[i]
                local is_scoring = false

                for _, scoring_card in ipairs(context.scoring_hand) do
                    if scoring_card == played_card then
                        is_scoring = true
                        break
                    end
                end

                if not is_scoring and not played_card.getting_sliced then
                    played_card.getting_sliced = true -- mark immediately so logic doesn't overlap
                    table.insert(cards_to_destroy, played_card)
                end
            end

            -- JUDGEMENTTTTT
            for _, target_card in ipairs(cards_to_destroy) do

                -- Add an event to the game's animation queue
                G.E_MANAGER:add_event(Event({
                    trigger = 'after', -- wait for previous events to finish
                    delay = 0.2,       -- 0.4 second pause between each destruction
                    func = function()

                        -- update stats
                        card.ability.extra.current_xmult = card.ability.extra.current_xmult + card.ability.extra.gain
                        card:juice_up(0.8, 0.5)
                        card_eval_status_text(card, 'extra', nil, nil, nil, {
                            message = "Banned!",
                            colour = G.C.BANHAMMER
                        })

                        -- shoe message
                        ban_destroy_card(target_card)

                        return true -- tells the game this event is done
                    end
                }))
            end
        end
    end
}

-- Atychipobia
-- subspace you little shit
SMODS.Joker{
    key = 'atychiphobia',
    loc_txt = {
        name = 'Atychiphobia',
        text = {
            "{E:1,s:1.25,C:subspace}\"MY INVENTION!!! IT WORKED!!!\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 1, y = 1},
    rarity = 4,                 -- rarity, common > uncommon > rare > legendary
    cost = 12,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = false,     -- can it be eternal

    config = { extra = {
        mult_per = 20,  -- +10 mult per converted hand
        active_mult = 0 -- stores the bonus for the current round
    }},

    -- no description lol good luck phiguring this out in-game nerds

    calculate = function(self, card, context)

        -- 'setting_blind' happens right when the round starts.
        -- block blueprint here because we don't want to set hands to 1 twice
        if context.setting_blind and not context.blueprint then

            -- get the number of hands the game just gave the player 
            local current_hands = G.GAME.current_round.hands_left

            if current_hands > 1 then

                -- calculate how many we are taking away
                local removed = current_hands - 1

                -- set hands to 1 and add the removed hands to discards
                G.GAME.current_round.hands_left = 1
                G.GAME.current_round.discards_left = G.GAME.current_round.discards_left + removed

                -- calculate the mult bonus for this specific round
                card.ability.extra.active_mult = removed * card.ability.extra.mult_per

                -- visual fanfare to show something happened
                G.E_MANAGER:add_event(Event({
                    func = function()
                        card:juice_up(0.8, 0.5)
                        play_sound('phighting_subspace_boom', 1, 1) -- subspace istg
                        return true
                    end
                }))

                return { message = "HAHAHAHAHAHAHAH!!!", colour = G.C.SUBSPACE }
            else
                -- if hands are already 1 (or 0 for some fuckin reason), no bonus this round
                card.ability.extra.active_mult = 0
            end
        end
        -- applies the stored bonus during the hand
        if context.joker_main and card.ability.extra.active_mult > 0 then
            return {
                message = "+" .. card.ability.extra.active_mult,
                mult_mod = card.ability.extra.active_mult,
                card = card
            }
        end
    end
}

-- VALK
SMODS.Joker{
    key = 'valk',
    loc_txt = { 
        name = 'See you on...',
        text = {
            "Gain {C:mult}+#1#{} Mult for each card held in hand",
            "{C:red}Lose {C:chips}#2#{} {C:red}Chips for each card played",
            "{C:inactive}(Scaled by Ante){}",
            "{C:inactive,s:0.8}Synergy: #3#{}", -- active/inactive display
            "{E:2,C:valk}\"Phighters, are you ready to rumble?!\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 0, y = 2},
    rarity = 3,                 -- rarity, common > uncommon > rare > legendary
    cost = 6,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    -- mmm love the complex code
    -- this is specifically for the desciption text
    loc_vars = function(self, info_queue, center)
        local checkflipside = flipside('j_phighting_dom')
        local current_ante = G.GAME.round_resets.ante

        local mult_add = 0
        local chip_loss = 0
        local set_text = ""

        if checkflipside then
            mult_add = (4 * current_ante) * 2
            chip_loss = 0
            set_text = "Active (x2, No Penalty)"
        else
            -- if no dom then this is played
            mult_add = 2 * current_ante
            chip_loss = 4 * current_ante
            set_text = "Inactive"
        end

        return { vars = {
            mult_add,
            chip_loss,
            set_text
        }}
    end,

    -- ok now we actually do the  calculations
    calculate = function(self, card, context)
        local checkflipside = flipside('j_phighting_dom')
        local current_ante = G.GAME.round_resets.ante

        local mult_add = 4 * (current_ante*2) or (2 * current_ante)
        local chip_loss = (checkflipside and 0) or (4 * current_ante)

        -- check every card
        if context.individual and not context.blueprint and not context.end_of_round then
            
            -- check cards held in hand
            if context.cardarea == G.hand then
                if mult_add > 0 then
                    return {
                        mult = mult_add,
                        colour = G.C.VALK,
                        card = card
                    }
                end
            end

            -- check cards played
            if context.cardarea == G.play then
                if chip_loss > 0 then
                    return {
                        chips = -chip_loss,
                        colour = G.C.VALK,
                        card = card
                    }
                end
            end
        end
    end
}

SMODS.Joker{
    key = 'dom',
    loc_txt = { 
        name = 'The Flipside!',
        text = {
            "Gain {C:chips}+#1#{} Chips for each card held in hand",
            "{C:red}Lose {C:mult}#2#{} {C:red}Mult for each card played",
            "{C:inactive}(Scaled by Ante){}",
            "{C:inactive,s:0.8}Synergy: #3#{}", -- active/inactive display
            "{E:2,C:dom}\"I'm quite excited for this next match.\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 1, y = 2},
    rarity = 3,                 -- rarity, common > uncommon > rare > legendary
    cost = 7,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    -- mmm love the complex code
    -- this is specifically for the desciption text
    loc_vars = function(self, info_queue, center)
        local checkflipside = flipside('j_phighting_valk')
        local current_ante = G.GAME.round_resets.ante

        local chip_add = 0
        local mult_loss = 0
        local set_text = ""

        if checkflipside then
            chip_add = (12 * current_ante) * 2
            mult_loss = 0
            set_text = "Active (x2, No Penalty)"
        else
            -- if no dom then this is played
            chip_add = 6 * current_ante
            mult_loss = 1 * current_ante
            set_text = "Inactive"
        end

        return { vars = {
            chip_add,
            mult_loss,
            set_text
        }}
    end,

    -- ok now we actually do the  calculations
    calculate = function(self, card, context)
        local checkflipside = flipside('j_phighting_valk')
        local current_ante = G.GAME.round_resets.ante

        local chip_add = (12 * current_ante) * 2 or (6 * current_ante)
        local mult_loss = (checkflipside and 0) or (1 * current_ante)

        -- check every card
        if context.individual and not context.blueprint and not context.end_of_round then

            -- check cards held in hand
            if context.cardarea == G.hand then
                if chip_add > 0 then
                    return {
                        chips = chip_add,
                        colour = G.C.DOM,
                        card = card
                    }
                end
            end

            -- check cards played
            if context.cardarea == G.play then
                if mult_loss > 0 then

                    local current_mult = G.GAME.current_round.current_hand.mult

                    -- safety for no negatives, i think.
                    local actual_loss = math.min(mult_loss, current_mult + 1)

                    if actual_loss > 0 then
                        return {
                            mult = -actual_loss,
                            colour = G.C.DOM,
                            card = card
                            
                        }
                    end
                end
            end
        end
    end
}

-- its brokercoin time
SMODS.Joker{
    key = 'brokercoin',
    loc_txt = { 
        name = 'Brokercoin',
        text = {
            "Gains {X:mult,C:white} X#1# {} Mult for every {C:money}$25{} you have",
            "Effect {C:attention}doubles{} for every {C:thebroker}Brokercoin{} present",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult){}",
            "{E:2,C:thebroker}\"Let's just say these coins go to support some special higher ups that I know.\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 2, y = 3},
    rarity = 3,                 -- rarity, common > uncommon > rare > legendary
    cost = 8,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    config = { extra = {
        base_x = 1.2,
        money_req = 25
    }},

    loc_vars = function(self, info_queue, center)

        local count = 0
        if G.jokers then
            for _, v in ipairs(G.jokers.cards) do
                -- check for this specific joker
                if v.config.center.key == 'j_phighting_brokercoin' then
                    count = count + 1
                end
            end
        end

        -- if looking in collection menu (where G.jokers doesn't exist)
        if count == 0 then count = 1 end

        -- 1.5 * (2 to the power of copies-1)
        local current_rate = center.ability.extra.base_x * (2 ^ (count - 1))

        -- stacks = money / 25
        local money = to_num(G.GAME.dollars) or 0
        if type(money) == 'table' then money = money:to_number() end

        -- use math.max(0, money) to ignore debt
        local stacks = math.floor(math.max(0, money) / center.ability.extra.money_req)

        -- total = 1 + (Rate * Stacks)
        local total_x = 1 + (current_rate * stacks)

        return { vars = { 
            current_rate,
            total_x
        }}
    end,

    calculate = function(self, card, context)
        if context.joker_main then

            local count = 0
            for _, v in ipairs(G.jokers.cards) do
                if v.config.center.key == 'j_phighting_brokercoin' then
                    count = count + 1
                end
            end
            if count == 0 then count = 1 end -- safety catch

            local current_rate = card.ability.extra.base_x * (2 ^ (count - 1))
            local money = to_num(G.GAME.dollars) or 0

            -- if money is a BigNum table (Cryptid/Talisman), convert it to a number
            if type(money) == 'table' then money = money:to_number() end

            local stacks = math.floor(math.max(0, money) / card.ability.extra.money_req)

            -- only trigger if we have enough money
            if stacks > 0 then
                local total_x = 1 + (current_rate * stacks)

                return {
                    message = "X" .. total_x,
                    Xmult_mod = total_x,
                    colour = G.C.THEBROKER,
                    card = card
                }
            end
        end
    end
}

-- DITF REFERENCE!??!??
SMODS.Joker{
    key = 'medkitphoto',
    loc_txt = { 
        name = 'Mysterious Photograph',
        text = {
            "{C:mult}+#1#{} Mult if played hand",
            "contains a {C:attention}Three of a Kind{}",
            "with {C:attention}NO shared suits{}",
            "{C:inactive}(Wild Cards automatically fail){}",
            "{E:2,C:sword}\"Medkit... Where'd you go?\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 3, y = 2},
    rarity = 2,                 -- rarity, common > uncommon > rare > legendary
    cost = 6,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    config = { extra = { mult_gain = 33 } },

    loc_vars = function(self, info_queue, center)
        return { vars = { center.ability.extra.mult_gain } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then

            -- organize cards by Rank
            local ranks = {}
            for _, playing_card in ipairs(context.scoring_hand) do
                local id = playing_card:get_id()
                -- skip stone cards (id 0), they have no rank :[
                if id > 0 then
                    if not ranks[id] then ranks[id] = {} end
                    table.insert(ranks[id], playing_card)
                end
            end

            -- check each Rank
            local condition_met = false

            for _, group in pairs(ranks) do
                -- only care if there are at least 3 of this rank
                if #group >= 3 then

                    local suits_found = {}
                    local distinct_count = 0
                    local has_wild = false

                    for _, c in ipairs(group) do
                        -- check for wild card explicitly
                        if c.config.center == G.P_CENTERS.m_wild then
                            has_wild = true
                            break -- stop checking this group
                        end

                        -- get the suit
                        local s = c.base.suit

                        -- if we haven't seen this suit in this group yet...
                        if not suits_found[s] then
                            suits_found[s] = true
                            distinct_count = distinct_count + 1
                        end
                    end

                    if not has_wild and distinct_count >= 3 then
                        condition_met = true
                        break
                    end
                end
            end

            if condition_met then
                return {
                    message = "+" .. card.ability.extra.mult_gain .. " Mult",
                    mult_mod = card.ability.extra.mult_gain,
                    colour = G.C.MEDKIT,
                    card = card
                }
            end
        end
    end
}

-- boom ball
-- boombox
-- boomboxball
-- ballbox
-- o⎵o
SMODS.Joker{
    key = 'boomball',
    atlas = 'phighting_atlas',
    loc_txt = { 
        name = 'Boomball',
        text = {
            "{C:attention}Use{} this joker to toggle between two modes",
            "Current: {C:attention}#1#{}",
            "{C:inactive}--------------------{}",
            "Halves {C:attention}#2#{}, adds #4# to {C:attention}#3#{}",
            "{E:2,C:boombox}\"Get em' team!\"{}"
        }
    },
    pos = {x = 2, y = 1}, -- this will get freaky (this is the default sprite)
    soul_pos = {x = 3, y = 1},
    rarity = 2,                 -- rarity, common > uncommon > rare > legendary
    cost = 8,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    config = { extra = { mode = 1 } },

    loc_vars = function(self, info_queue, center)
        local mode_name = "Bass Boost"
        local lefty, righty = "", ""
        local amount = "half of that amount"

        if center.ability.extra.mode == 1 then
            mode_name = "Bass Boost"
            lefty = "Chips"
            righty = "Mult"
            amount = "half of that amount"
        else
            mode_name = "Beat Drop"
            lefty = "Mult"
            righty = "Chips"
            amount = "1.5x the amount"
        end

        return { vars = { 
            mode_name,
            lefty,
            righty,
            amount
        }}
    end,

    -- this function runs when the card spawns, loads, or is told to redraw
    set_sprites = function(self, card, front)
        -- default position (Mode 1)
        local target_pos = {x = 2, y = 1}

        -- if we are in mode 2, use the 2nd sprite position
        if card.ability and card.ability.extra and card.ability.extra.mode == 2 then
            target_pos = {x = 2, y = 2}
        end

        -- apply the texture coordinates
        card.children.center:set_sprite_pos(target_pos)
    end,


    -- button logic
    phighting_button_label = "REMIX",
    phighting_button_colour = G.C.BOOMBOX,
    phighting_text_colour = G.C.WHITE,

    phighting_on_press = function(card)

        -- toggle between modes
        if card.ability.extra.mode == 1 then
            card.ability.extra.mode = 2
        else
            card.ability.extra.mode = 1
        end

        -- sprite update
        card:set_sprites(card.config.center)

        play_sound('tarot1', 1, 0.9)
        card:juice_up(0.3, 0.5)

        -- manually triggering the popup
        card_eval_status_text(card, 'extra', nil, nil, nil, {
            message = "Remixed!",
            colour = G.C.BOOMBOX
        })
    end,


    -- its calculating time
    calculate = function(self, card, context)
        if context.joker_main then

            -- MODE 1: CHIPS TO MULT
            if card.ability.extra.mode == 1 then

                local current_chips = to_num(G.GAME.current_round.current_hand.chips)
                local loss = math.floor(current_chips * 0.5)
                local gain = loss * 0.5

                -- return negative chips, positive mult
                if loss > 0 then
                    return {
                        message = "GOAL!",
                        chip_mod = -loss,
                        mult_mod = gain,
                        colour = G.C.MULT,
                        card = card
                    }
                end

            -- MODE 2: MULT TO CHIPS
            else
                local current_mult = to_num(mult)
                local loss = math.floor(current_mult * 0.5)
                local gain = loss * 1.5

                -- return negative mult, positive chips
                if loss > 0 then
                    return {
                        message = "GOAL!",
                        mult_mod = -loss,
                        chip_mod = gain,
                        colour = G.C.CHIPS,
                        card = card
                    }
                end
            end
        end
    end
}

-- its ghosdeeri time
SMODS.Joker{
    key = 'ghosdeeri',
    loc_txt = { 
        name = 'Ghosdeeri',
        text = {
            "Adds the total {C:chips}Chip value{}",
            "of all cards held in hand",
            "to {C:mult}Mult{} and {C:chips}Chips{}",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips & {C:mult}+#1#{C:inactive} Mult){}",
            "{E:2,C:ghosdeeri}\"I've had my eye on you for a while.\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 0, y = 3}, -- Adjust to your sheet
    soul_pos = {x = 1, y = 3},
    rarity = 4,                 -- rarity, common > uncommon > rare > legendary
    cost = 9,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    -- text calc to show the chip value in realtime
    loc_vars = function(self, info_queue, center)
        local total_val = 0

        if G.hand and G.hand.cards then
            for _, v in ipairs(G.hand.cards) do
                total_val = total_val + get_card_chips(v)
            end
        end

        return { vars = { total_val } }
    end,

    -- its scoring time
    calculate = function(self, card, context)
        if context.joker_main then

            local total_val = 0

            -- loop through held cards
            for _, v in ipairs(G.hand.cards) do
                total_val = total_val + get_card_chips(v)
            end

            if total_val > 0 then
                return {
                    message = "+" .. total_val,
                    chip_mod = total_val,
                    mult_mod = total_val,
                    colour = G.C.PURPLE,
                    card = card
                }
            end
        end
    end
}

-- one of the few nonlegendary sfoth sword cards mwhehehe
SMODS.Joker{
    key = 'lostpeace',
    loc_txt = { 
        name = 'The Breaking Point',
        text = {
            "{X:mult,C:white} X#1# {} Mult",
            "Gains {X:mult,C:white} +0.25 {} Mult when a Joker is {C:attention}Sold{}",
            "Loses {X:mult,C:white} -0.25 {} Mult when a Joker is {C:attention}Obtained{}",
            "{C:inactive,s:0.8}(Jokers gained from other Jokers do not count){}",
            "{E:2,C:darkheart}\"...In the end, Nobody truly understood what had{}",
            "{E:2,C:darkheart}driven him over the edge.\"{}"

        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 3, y = 3},
    rarity = 2,                 -- rarity, common > uncommon > rare > legendary
    cost = 9,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    config = { extra = { 
        current_x = 0.75,
        sell_gain = 0.25,
        buy_loss = 0.25,
        last_joker_count = 0 -- to track changes
    }},

    loc_vars = function(self, info_queue, center)
        return { vars = { center.ability.extra.current_x } }
    end,

    -- update every new joker update
    update = function(self, card, dt)
        if G.jokers then
            -- start the counter if it's the first time running
            if card.ability.extra.last_joker_count == 0 then
                card.ability.extra.last_joker_count = #G.jokers.cards
            end

            -- detect if a joker is added
            if #G.jokers.cards > card.ability.extra.last_joker_count then

                -- if its true then we found a new joker!!! now we have to find out
                -- if its in a market environment

                local penalty_zones = {
                    [G.STATES.SHOP] = true,          -- buying from / using smth in shop
                    [G.STATES.TAROT_PACK] = true,    -- opening / using arcana pack
                    [G.STATES.SPECTRAL_PACK] = true, -- spectrals
                    [G.STATES.STANDARD_PACK] = true, -- card pack (just to be safe lol)
                    [G.STATES.BUFFOON_PACK] = true,  -- buffoons
                    [G.STATES.PLANET_PACK] = true    -- planet pack (also just to be safe)
                }

                if penalty_zones[G.STATE] then
                    -- apply penalty
                    card.ability.extra.current_x = card.ability.extra.current_x - card.ability.extra.buy_loss

                    -- feedback
                    card_eval_status_text(card, 'extra', nil, nil, nil, {
                        message = "Let the flames follow!",
                        colour = G.C.FIREBRAND
                    })
                    card:juice_up(0.6, 0.4)
                end
            end

            -- always update the tracker so we don't trigger twice
            card.ability.extra.last_joker_count = #G.jokers.cards
        end
    end,

    -- scoring
    calculate = function(self, card, context)

        if context.joker_main then
            return {
                message = "X" .. card.ability.extra.current_x,
                Xmult_mod = card.ability.extra.current_x,
                colour = G.C.FIREBRAND,
                card = card
            }
        end

        -- mmmselling
        if context.selling_card and not context.blueprint then
            -- we exclude the card itself (though usually you can't sell and keep effect)
            if context.card ~= card and context.card.ability.set == 'Joker' then
                card.ability.extra.current_x = card.ability.extra.current_x + card.ability.extra.sell_gain

                return {
                    message = "Set it ablaze!",
                    colour = G.C.FIREBRAND,
                    card = card
                }
            end
        end
    end
}

-- Settoing
SMODS.Joker{
    key = 'settoing',
    loc_txt = { 
        name = 'Settoing',
        text = {
            "{C:mult}+#1#{} Mult for each",
            "remaining {C:blue}Hand{} and {C:red}Discard{}",
            "{E:2,C:black}\"Settoing\"{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 0, y = 4},
    rarity = 1,                 -- rarity, common > uncommon > rare > legendary
    cost = 3,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    config = { extra = { multiplier = 2 } },

    loc_vars = function(self, info_queue, center)
        -- check if there ARE hands/discards, this is for the collections menu
        local hands = (G.GAME.current_round and G.GAME.current_round.hands_left) or 0
        local discards = (G.GAME.current_round and G.GAME.current_round.discards_left) or 0

        -- simple maths
        local current_bonus = (hands + discards) * center.ability.extra.multiplier

        return { vars = { 
            center.ability.extra.multiplier, -- #1#
            current_bonus                    -- #2#
        }}
    end,

    calculate = function(self, card, context)
        if context.joker_main then

            local hands = G.GAME.current_round.hands_left
            local discards = G.GAME.current_round.discards_left

            local bonus = (hands + discards) * card.ability.extra.multiplier

            if bonus > 0 then
                return {
                    message = "+" .. bonus,
                    mult_mod = bonus,
                    card = card
                }
            end
        end
    end
}

-- the rodgers
-- roger
SMODS.Joker{
    key = 'roger',
    loc_txt = { 
        name = 'Roger',
        text = {
            "{C:mult}+#1#{} Mult",
            "{C:inactive}(Set Bonus: +10 Mult){}",
            "{C:inactive,s:0.8}Set Status: #2#{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 1, y = 4},
    rarity = 1,                 -- rarity, common > uncommon > rare > legendary
    cost = 3,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    loc_vars = function(self, info_queue, center)
        local active = roger()
        local mult_val = active and 15 or 5
        local status = active and "Active!" or "Inactive"
        return { vars = { mult_val, status } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local active = roger() -- this calls the roger function from like way above the lua file
            local mult_val = active and 15 or 5

            return {
                mult_mod = mult_val,
                message = "+" .. mult_val .. " Mult",
                card = card
            }
        end
    end
}

-- rojer
SMODS.Joker{
    key = 'rojer',
    loc_txt = { 
        name = 'Rojer',
        text = {
            "{C:mult}+#1#{} Chips",
            "{C:inactive}(Set Bonus: +40 Chips){}",
            "{C:inactive,s:0.8}Set Status: #2#{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 2, y = 4},
    rarity = 1,                 -- rarity, common > uncommon > rare > legendary
    cost = 3,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    loc_vars = function(self, info_queue, center)
        local active = roger()
        local chip_val = active and 60 or 20
        local status = active and "Active!" or "Inactive"
        return { vars = { chip_val, status } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local active = roger() -- this calls the roger function from like way above the lua file
            local chip_val = active and 60 or 20

            return {
                mult_mod = chip_val,
                message = "+" .. chip_val .. " Chips",
                card = card
            }
        end
    end
}

-- phestival roger
SMODS.Joker{
    key = 'phestroger',
    loc_txt = { 
        name = 'Phestival Roger',
        text = {
            "{X:mult,C:white} X#1# {} Mult & {X:chips,C:white} X#1# {} Chips",
            "{C:inactive}(Set Bonus: +X1.0 Mult & Chips){}",
            "{C:inactive,s:0.8}Set Status: #2#{}"
        }
    },
    atlas = 'phighting_atlas',
    pos = {x = 3, y = 4},
    rarity = 2,                 -- rarity, common > uncommon > rare > legendary
    cost = 3,                  -- cost
    unlocked = true,            -- where it is unlocked or not: if true, 
    discovered = true,          -- whether or not it starts discovered
    blueprint_compat = true,    -- can it be blueprinted/brainstormed/other
    eternal_compat = true,     -- can it be eternal

    loc_vars = function(self, info_queue, center)
        local active = roger()
        local rate = active and 2.5 or 1.5
        local status = active and "Active!" or "Inactive"
        return { vars = { rate, status } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local active = roger()
            local rate = active and 2.5 or 1.5

            return {
                message = "X" .. rate,
                xmult = rate,
                xchips = rate,
                colour = G.C.PURPLE,
                card = card
            }
        end
    end
}