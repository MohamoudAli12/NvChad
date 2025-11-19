local M = {}
local map = vim.keymap.set

-- export on_attach & capabilities
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")

  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", "<leader>rn", require "nvchad.lsp.renamer", opts "NvRenamer")
end

-- disable semanticTokens
M.on_init = function(client, _)
  if vim.fn.has "nvim-0.11" ~= 1 then
    if client.supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  else
    if client:supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

M.defaults = function()
  dofile(vim.g.base46_cache .. "lsp")
  require("nvchad.lsp").diagnostic_config()

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      M.on_attach(_, args.buf)
    end,
  })

  local lua_lsp_settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
        },
      },
    },
  }

  -- Support 0.10 temporarily

  if vim.lsp.config then
    vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
    vim.lsp.config("lua_ls", { settings = lua_lsp_settings })
    vim.lsp.enable "lua_ls"
  else
    require("lspconfig").lua_ls.setup {
      capabilities = M.capabilities,
      on_init = M.on_init,
      settings = lua_lsp_settings,
    }
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == 'ruff' then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
      client.server_capabilities.codeActionProvider = false

    end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      typeCheckingMode = "off",
      disableOrganizeImports = true,
    },
  },
})

local servers = { "lua_ls", "clangd", "rust-analyzer","ruff", "basedpyright" }
vim.lsp.enable(servers)
return M
