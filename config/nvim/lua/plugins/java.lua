-- Lombok + jdtls cmd: LazyVim’s java extra only adds lombok from Mason’s jdtls; with mason=false
-- for jdtls we resolve lombok from LOMBOK_JAR (nix), Mason, or ~/.m2.

local function resolve_lombok_jar()
  local env = vim.env.LOMBOK_JAR
  if env and env ~= "" and vim.fn.filereadable(env) == 1 then
    return env
  end
  local mason = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
  if vim.fn.filereadable(mason) == 1 then
    return mason
  end
  local jars = vim.fn.glob(vim.fn.expand("~/.m2/repository/org/projectlombok/lombok/*/lombok-*.jar"), false, true)
  if type(jars) == "table" and #jars > 0 then
    table.sort(jars)
    return jars[#jars]
  end
  return nil
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local jdtls_bin = vim.fn.exepath("jdtls")
      if jdtls_bin == "" then
        vim.notify("jdtls not on PATH — open the project with direnv/nix so jdt-language-server is available.", vim.log.levels.WARN)
        return opts
      end

      local lombok_jar = resolve_lombok_jar()
      opts.cmd = { jdtls_bin }
      if lombok_jar then
        table.insert(opts.cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
      end

      return opts
    end,
  },
}
