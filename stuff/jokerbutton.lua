-- from the vanillaremade wiki 

-- this is generic button for all jokers mmmmmmm
local function create_universal_button(card, label, btn_colour, text_colour)
    return UIBox {
        definition = {
            n = G.UIT.ROOT,
            config = { colour = G.C.CLEAR },
            nodes = {
                {
                    n = G.UIT.C,
                    config = {
                        align = 'cm',
                        padding = 0.16,
                        r = 0.09,
                        hover = true,
                        shadow = true,
                        colour = btn_colour or G.C.MULT, -- default to Mult Red
                        button = 'phighting_btn_click', -- one function for EVERY button
                        ref_table = card,
                    },
                    nodes = {
                        {
                            n = G.UIT.T,
                            config = {
                                text = label or "USE",
                                colour = text_colour or G.C.UI.TEXT_LIGHT,
                                scale = 0.375,
                                shadow = true
                            }
                        }
                    }
                }
            }
        },
        config = {
            align = 'cm',
            major = card,
            parent = card,
            offset = { x = 0.0, y = 1.65 }
        }
    }
end

-- handles any joker being clicked
G.FUNCS.phighting_btn_click = function(e)
    local card = e.config.ref_table

    -- look up the definition / config of this specific Joker
    local joker_def = G.P_CENTERS[card.config.center.key]

    -- check if it has a custom click function defined
    if joker_def and joker_def.phighting_on_press then
        -- if it does, run that function!
        joker_def.phighting_on_press(card)
    end
end

SMODS.DrawStep {
    key = 'phighting_universal_button',
    order = -30,
    func = function(card, layer)
        if card.children.phighting_universal_button then
            card.children.phighting_universal_button:draw()
        end
    end
}
SMODS.draw_ignore_keys.phighting_universal_button = true

-- highlight override
local r_highlight = Card.highlight
function Card.highlight(self, is_highlighted)
    local ret = r_highlight(self, is_highlighted)

    -- only check Jokers
    if self.area == G.jokers then
        -- retrieve this Joker's definition
        local center_data = G.P_CENTERS[self.config.center.key]

        -- DOES THIS JOKER WANT A BUTTON??!???
        -- check if 'phighting_button_label' exists in its definition
        if center_data and center_data.phighting_button_label then

            if is_highlighted then
                if not self.children.phighting_universal_button then
                    self.children.phighting_universal_button = create_universal_button(
                        self,
                        center_data.phighting_button_label,
                        center_data.phighting_button_colour, -- Background
                        center_data.phighting_label_colour   -- Text
                    )
                end
            else
                if self.children.phighting_universal_button then
                    self.children.phighting_universal_button:remove()
                    self.children.phighting_universal_button = nil
                end
            end
        end
    end

    return ret
end