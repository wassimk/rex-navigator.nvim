-- Loads rex/rex-navigator.lua against a fake `rex` global that records what it
-- binds and calls, so the Rex side can be tested without Rex

local function fake_rex(foreground)
  local fake = { bindings = {}, calls = {} }

  fake.bind = function(key, fn)
    fake.bindings[key] = fn
  end

  fake.call = function(method, args)
    table.insert(fake.calls, { method = method, args = args })
  end

  fake.block = {
    call = function(creator, method)
      assert(creator == 'com.superlogical.terminal' and method == 'process')
      if foreground == 'error' then
        error('not a terminal')
      end
      return { foreground = foreground }
    end,
  }

  return fake
end

local function load_rex_side(foreground, opts)
  _G.rex = fake_rex(foreground)
  local navigator = dofile('rex/rex-navigator.lua')
  navigator.setup(opts)
  return _G.rex
end

describe('rex side', function()
  after_each(function()
    _G.rex = nil
  end)

  it('binds the physical h/j/k/l keys with ctrl', function()
    local fake = load_rex_side({ name = 'zsh' })

    for _, key in ipairs({ 'ctrl+[KeyH]', 'ctrl+[KeyJ]', 'ctrl+[KeyK]', 'ctrl+[KeyL]' }) do
      assert.is_function(fake.bindings[key])
    end
  end)

  it('focuses the pane in that direction outside of Vim', function()
    local fake = load_rex_side({ name = 'zsh', argv0 = '-zsh' })

    local handled = fake.bindings['ctrl+[KeyH]']({ session_id = 'session:test' })

    assert.is_true(handled)
    assert.are.same({
      method = 'session.focus_direction',
      args = { session_id = 'session:test', direction = 'left', wrap = false },
    }, fake.calls[1])
  end)

  it('lets the key through to Neovim', function()
    local fake = load_rex_side({ name = 'nvim', argv0 = 'nvim' })

    local handled = fake.bindings['ctrl+[KeyL]']({ session_id = 'session:test' })

    assert.is_false(handled)
    assert.are.same({}, fake.calls)
  end)

  it('recognizes Vim started by a full path', function()
    local fake = load_rex_side({ name = 'something', argv0 = '/usr/bin/vim' })

    assert.is_false(fake.bindings['ctrl+[KeyJ]']({ session_id = 'session:test' }))
  end)

  it('treats a block without a process as not Vim', function()
    local fake = load_rex_side('error')

    assert.is_true(fake.bindings['ctrl+[KeyK]']({ session_id = 'session:test' }))
  end)

  it('accepts custom keys, programs, and wrap', function()
    local fake = load_rex_side({ name = 'hx' }, {
      keys = { left = 'alt+h' },
      programs = { '^hx$' },
      wrap = true,
    })

    assert.is_function(fake.bindings['alt+h'])
    assert.is_function(fake.bindings['ctrl+[KeyJ]'])
    assert.is_false(fake.bindings['alt+h']({ session_id = 'session:test' }))
  end)

  it('passes wrap through to Rex', function()
    local fake = load_rex_side({ name = 'zsh' }, { wrap = true })

    fake.bindings['ctrl+[KeyH]']({ session_id = 'session:test' })

    assert.is_true(fake.calls[1].args.wrap)
  end)
end)
