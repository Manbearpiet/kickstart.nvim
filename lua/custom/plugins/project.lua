return {
  'ahmedkhalf/project.nvim',
  init = function()
    -- Veilige defaults
    require('project_nvim').setup {
      manual_mode = false,
      detection_methods = { 'lsp', 'pattern' },
      patterns = { '.git', 'package.json', 'pyproject.toml', 'go.mod', 'Cargo.toml', 'Makefile', 'CMakeLists.txt' },
      exclude_dirs = { '~/.local/*', '/tmp/*' },
      show_hidden = true,
      silent_chdir = true,
      scope_chdir = 'tab',
    }

    -- Guard: voorkom set_pwd(nil)
    local ok_proj, P = pcall(require, 'project_nvim.project')
    if ok_proj and type(P.set_pwd) == 'function' then
      local orig = P.set_pwd
      P.set_pwd = function(dir, source)
        if type(dir) ~= 'string' or dir == '' then
          return false
        end
        return orig(dir, source)
      end
    end

    -- FzfProjects command
    local history = require 'project_nvim.utils.history'
    local project = require 'project_nvim.project'
    vim.api.nvim_create_user_command('FzfProjects', function()
      local projects = history.get_recent_projects()
      require('fzf-lua').fzf_exec(projects, {
        prompt = 'Projects> ',
        actions = {
          ['default'] = function(selected)
            if selected and #selected > 0 then
              local project_path = selected[1]
              if type(project_path) == 'string' and project_path ~= '' and vim.fn.isdirectory(project_path) == 1 then
                if project.set_pwd(project_path, 'fzf-lua') then
                  require('fzf-lua').files()
                end
              end
            end
          end,
        },
      })
    end, {})
  end,
  keys = { {
    '<leader>sp',
    '<cmd>FzfProjects<CR>',
    desc = '[S]earch [P]rojects',
  } },
}
