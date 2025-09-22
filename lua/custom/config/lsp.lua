vim.lsp.config['powershell_es'] = {
  cmd = {
    'pwsh',
    '-NoLogo',
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-Command',
    "& '/Users/christianpiet/.config/nvim/PowerShellEditorServices/PowerShellEditorServices/Start-EditorServices.ps1'",
    "-BundledModulesPath '/Users/christianpiet/.config/nvim/PowerShellEditorServices'",
    '-Stdio',
    "-HostName 'nvim'",
    "-HostProfileId '0'",
    "-HostVersion '1.0.0'",
    "-LogLevel 'None'",
    '-FeatureFlags @()',
  },
  filetypes = { 'ps1', 'psm1', 'psd1' },
  settings = {
    powershell = {
      codeFormatting = {
        autoCorrectAliases = true,
        preset = 'OTBS',
        openBraceOnSameLine = true,
        newLineAfterOpenBrace = true,
        newLineAfterCloseBrace = false,
        pipelineIndentationStyle = 'IncreaseIndentationForFirstPipeline',
        whitespaceBeforeOpenBrace = true,
        whitespaceBeforeOpenParen = true,
        whitespaceAroundOperator = true,
        whitespaceAfterSeparator = true,
        whitespaceBetweenParameters = true,
        whitespaceInsideBrace = true,
        addWhitespaceAroundPipe = true,
        trimWhitespaceAroundPipe = true,
        ignoreOneLineBlock = true,
        alignPropertyValuePairs = true,
        useConstantStrings = true,
        useCorrectCasing = true,
      },
      scriptAnalysis = {
        enable = true,
        settingsPath = '/Users/christianpiet/Documents/ScriptAnalyzerSettings.psd1',
      },
      enableProfileLoading = true,
    },
  },
}

vim.lsp.enable 'powershell_es'

-- brew install lua-language-server
vim.lsp.config['luals'] = {
  -- Command and arguments to start the server.
  -- Filetypes to automatically attach to.
  filetypes = { 'lua' },
  cmd = { '/opt/homebrew/bin/lua-language-server', '--stdio' },
  -- Sets the "workspace" to the directory where any of these files is found.
  -- Files that share a root directory will reuse the LSP server connection.
  -- Nested lists indicate equal priority, see |vim.lsp.Config|.
  root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
  -- Specific settings to send to the server. The schema is server-defined.
  -- Example: https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME, vim.fn.stdpath 'config' .. '/lua' },
      },
    },
  },
}
vim.lsp.enable 'luals'

-- https://github.com/hrsh7th/vscode-langservers-extracted
vim.lsp.config['jsonls'] = {
  filetypes = { 'json', 'jsonc' },
  cmd = { '/opt/homebrew/bin/vscode-json-language-server', '--stdio' },
}
vim.lsp.enable 'jsonls'

-- https://github.com/LuaLS/lua-language-server /  https://luals.github.io/#install
vim.lsp.config['yamlls'] = {
  filetypes = { 'yaml', 'yml' },
  cmd = { '/opt/homebrew/bin/yaml-language-server', '--stdio' },
  settings = {
    yaml = {
      validate = true,
      schemaStore = {
        enable = false,
        url = '',
      },
      schemas = {
        ['https://json.schemastore.org/azure-pipelines.json'] = '.azure/*.{yml,yaml}',
        ['https://json.schemastore.org/github-workflow.json'] = '.github/workflows/*.{yml, yaml}',
        ['https://json.schemastore.org/github-action.json'] = '.github/actions/**/*.{yml, yaml}',
      },
    },
  },
}
vim.lsp.enable 'yamlls'

vim.api.nvim_create_user_command('LspLog', function()
  vim.cmd.vsplit(vim.fn.fnameescape(vim.lsp.get_log_path()))
end, {})

