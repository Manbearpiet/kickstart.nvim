return {
    "github/copilot.vim",
    event = "InsertEnter", -- laadt in Insert
    cmd = {"Copilot", "CopilotSetup", "CopilotStatus", "CopilotEnable", "CopilotDisable"}, -- laadt op cmd
    config = function()
        -- voorkom conflict met nvim-cmp Tab
        vim.g.copilot_no_tab_map = true
        vim.g.copilot_assume_mapped = true

        -- optioneel: per filetype aan/uit
        -- vim.g.copilot_filetypes = { ["*"] = true, markdown = true, gitcommit = true }

        -- handige keybinds (macOS-vriendelijk)
        vim.keymap.set("i", "<C-j>", 'copilot#Accept("<CR>")', {
            expr = true,
            silent = true,
            replace_keycodes = false,
            desc = "Copilot Accept"
        })
        vim.keymap.set("i", "<M-]>", "copilot#Next()", {
            expr = true,
            silent = true,
            desc = "Copilot Next"
        })
        vim.keymap.set("i", "<M-[>", "copilot#Previous()", {
            expr = true,
            silent = true,
            desc = "Copilot Prev"
        })
        vim.keymap.set("i", "<C-\\>", "copilot#Dismiss()", {
            expr = true,
            silent = true,
            desc = "Copilot Dismiss"
        })
    end
}
