#!/usr/bin/env python3
"""Gera dist/StudioLite_DexExplorer.bundle.lua: um unico arquivo offline com tudo do repo.
Uso:  python3 tools/bundle.py
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORDER = [
    "src/dex/modules/Lib.lua", "src/dex/modules/Explorer.lua", "src/dex/modules/Properties.lua",
    "src/dex/modules/ScriptViewer.lua", "src/dex/modules/Console.lua", "src/dex/modules/ModelViewer.lua",
    "src/dex/modules/SaveInstance.lua", "src/dex/modules/SettingsWindow.lua",
    "src/dex/core.lua",
    "src/bridge/studiolite_viewer.lua", "src/bridge/code_editor.lua",
    "src/bridge/selection_sync.lua", "src/bridge/script_insert.lua", "src/bridge/init.lua",
]

out = ["-- Gerado por tools/bundle.py -- NAO edite; edite os arquivos em src/ e rode o bundle de novo.",
       "local __files = {}"]
for rel in ORDER:
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        body = f.read()
    out.append('__files["%s"] = function(...)\n%s\nend' % (rel, body))
out.append('''
local env = getgenv()
env.DexPP_StudioLiteMode = true
env.DexPP_Load = function(path)
	return assert(__files[path], "[DexPP] arquivo ausente no bundle: " .. path)
end
env.DexPP_Load("src/bridge/init.lua")()
env.DexPP_Load("src/dex/core.lua")()
''')
dest = os.path.join(ROOT, "dist", "StudioLite_DexExplorer.bundle.lua")
with open(dest, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out))
print("ok ->", dest)
