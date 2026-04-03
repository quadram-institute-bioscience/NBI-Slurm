-- Lua filter: map JOSS frontmatter (authors/affiliations) to pandoc author inlines
function Meta(m)
  -- Build a lookup: affiliation index -> name
  local aff_map = {}
  if m.affiliations then
    for _, aff in ipairs(m.affiliations) do
      local idx = tonumber(pandoc.utils.stringify(aff.index))
      if idx then
        aff_map[idx] = pandoc.utils.stringify(aff.name)
      end
    end
  end

  -- Build author MetaInlines from JOSS authors list
  if m.authors then
    local author_list = {}
    for _, au in ipairs(m.authors) do
      local name  = pandoc.utils.stringify(au.name)
      local orcid = au.orcid and pandoc.utils.stringify(au.orcid) or nil

      -- Resolve affiliation indices into ordered list
      local aff_names = {}
      if au.affiliation then
        local raw = pandoc.utils.stringify(au.affiliation)
        for idx_s in raw:gmatch("[^,%s]+") do
          local idx = tonumber(idx_s)
          if idx and aff_map[idx] then
            table.insert(aff_names, aff_map[idx])
          end
        end
      end

      -- Build inline sequence: name, then each affiliation on its own line
      local inlines = { pandoc.Str(name) }
      for _, aff in ipairs(aff_names) do
        table.insert(inlines, pandoc.LineBreak())
        table.insert(inlines, pandoc.Str(aff))
      end
      if orcid then
        table.insert(inlines, pandoc.LineBreak())
        table.insert(inlines, pandoc.Str("ORCID: " .. orcid))
      end

      table.insert(author_list, pandoc.MetaInlines(inlines))
    end
    m.author = pandoc.MetaList(author_list)

    -- Set footer-left to bare names only (no affiliations/ORCID)
    local bare_names = {}
    for _, au in ipairs(m.authors) do
      table.insert(bare_names, pandoc.utils.stringify(au.name))
    end
    m["footer-left"] = pandoc.MetaInlines({ pandoc.Str(table.concat(bare_names, ", ")) })
  end

  return m
end
