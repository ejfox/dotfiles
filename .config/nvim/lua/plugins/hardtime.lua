return {
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    enabled = true,  -- TRAINING CAMP - KHABIB MODE
    opts = {
      restriction_mode = "block",  -- Zero tolerance brother
      max_count = 1,  -- ONE TIME ONLY. You know this.
      disabled_keys = {
        ["<Up>"] = { "n", "x", "i" },  -- No arrow keys. This is not amateur hour.
        ["<Down>"] = { "n", "x", "i" },
        ["<Left>"] = { "n", "x", "i" },
        ["<Right>"] = { "n", "x", "i" },
      },
      hint = true,
      allow_different_key = true,

      -- Coach Khabib's Training Hints
      hints = {
        -- Horizontal movement
        ["h+"] = {
          message = function()
            return "Brother, you know this. Use 'b' or 'F{char}'. Why you press same key?"
          end,
          length = 1,
        },
        ["hhh+"] = {
          message = function()
            return "This is number one bullshit. You have to give up 'h' key. Use proper motion."
          end,
          length = 3,
        },
        ["l+"] = {
          message = function()
            return "Let's talk now. Press 'w' for word, 'f{char}' to find, 's{chars}' for flash. Be professional."
          end,
          length = 1,
        },
        ["lll+"] = {
          message = function()
            return "Why you spam 'l'? You must be tired. Use 'e' for end of word, '$' for end of line."
          end,
          length = 3,
        },

        -- Vertical movement
        ["j+"] = {
          message = function()
            return "Brother, use '}' for paragraph, ']f' for function, ']d' for diagnostic, '/' for search. This is Dagestani way."
          end,
          length = 1,
        },
        ["jjj+"] = {
          message = function()
            return "You need more training. Use 'G' to go bottom, '{number}G' to jump line. You have to change level."
          end,
          length = 3,
        },
        ["k+"] = {
          message = function()
            return "Alhamdulillah. Now use '{' for paragraph, '[f' for function, '[d' for diagnostic. Be smart, not strong."
          end,
          length = 1,
        },
        ["kkk+"] = {
          message = function()
            return "Why you do this brother? Use 'gg' to go top, '{number}G' for line number. This is precision, not power."
          end,
          length = 3,
        },

        -- Really bad habits
        ["[jk][jk][jk][jk]+"] = {
          message = function(keys)
            local count = #keys
            return string.format("You pressed %d times. This is very bad. Send location of target line, use ':%dG'. You know this.", count, count)
          end,
          length = 4,
        },
        ["[hl][hl][hl][hl]+"] = {
          message = function()
            return "Brother, I give you advice: 'w' 'b' 'f' 't' - these are your friends. 'h' 'l' spam is for beginners."
          end,
          length = 4,
        },
      },
    },
  },
}
