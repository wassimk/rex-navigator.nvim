--
-- health.lua
--

local M = {}

function M.check()
  vim.health.start('rex-navigator')

  if vim.env.REX_SESSION and vim.env.REX_SESSION ~= '' then
    vim.health.ok('Running inside Rex (REX_SESSION is set)')
  else
    vim.health.warn('Not running inside Rex, so <C-h/j/k/l> only moves between splits')
  end

  local command = require('rex-navigator').focus_command('left')[1]
  if vim.fn.executable(command) == 1 then
    vim.health.ok('rex executable found: ' .. vim.fn.exepath(command))
  else
    vim.health.error('rex executable not found', {
      'Rex puts its bin directory on PATH and in REX_BIN_DIR for programs it starts',
      'Check that your shell startup files keep it on PATH',
    })
  end
end

return M
