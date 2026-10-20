# Dex++ x Studio Lite

Explorer do Dex++ dentro do Studio Lite, com Code Editor próprio (mobile) que salva no script igual ao Studio Lite.
Você executa **só o `main.lua`**; ele baixa o resto do GitHub.

## Executar

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/main.lua"))()
```

Sem editar o `main.lua`, dá para apontar para outro repo/branch antes de executar:

```lua
getgenv().DexPP_Config = {Repo = "usuario/repo", Branch = "main"}
```

`Branch` aceita um commit hash (o `raw.githubusercontent.com` guarda cache por alguns minutos; o hash evita versão velha).

## Estrutura

```
main.lua                          único arquivo que você executa (define DexPP_Load)
src/
  bridge/                         ponte Studio Lite <-> Dex
    init.lua                      espera o Dex iniciar, monta o ctx e carrega as partes abaixo
    studiolite_viewer.lua         código ORIGINAL do Studio Lite: ShowScript, teclado mobile, NewPart
    code_editor.lua               Code Editor novo (substitui o Notepad)
    selection_sync.lua            sincroniza a seleção Dex <-> Studio Lite
    script_insert.lua             criar Script/LocalScript/ModuleScript vazios e Parts
  dex/
    core.lua                      Main do Dex++ (settings, API, init) — carrega os módulos
    modules/                      Lib, Explorer, Properties, ScriptViewer, Console,
                                  ModelViewer, SaveInstance, SettingsWindow
tools/bundle.py                   gera dist/StudioLite_DexExplorer.bundle.lua (1 arquivo offline)
dist/                             saída do bundle
```

## Onde mexer

| Quero mudar...                              | Arquivo                              |
|---------------------------------------------|--------------------------------------|
| Editor de código (botões, cores, mobile)    | `src/bridge/code_editor.lua`         |
| Como o script novo é criado/salvo           | `src/bridge/script_insert.lua`       |
| O que abre ao selecionar/duplo clique       | `src/bridge/selection_sync.lua`, `src/dex/modules/ScriptViewer.lua` |
| Explorer do Dex                             | `src/dex/modules/Explorer.lua`       |
| Biblioteca de UI do Dex (janelas, etc.)     | `src/dex/modules/Lib.lua`            |

## Desenvolver sem dar push toda hora

Copie a pasta do repo para a **workspace do executor** e use:

```lua
getgenv().DexPP_Config = {Dev = "DexPP-StudioLite/"}
loadstring(readfile("DexPP-StudioLite/main.lua"))()
```

Os arquivos são lidos do disco; quando estiver bom, dê commit/push.

## Publicar no GitHub

```bash
git init && git add . && git commit -m "Dex++ x Studio Lite modular"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/SEU_REPO.git
git push -u origin main
```

## Arquivo único (offline)

```bash
python3 tools/bundle.py   # -> dist/StudioLite_DexExplorer.bundle.lua
```

## Notas técnicas

- Cada arquivo é um *chunk*: `DexPP_Load("src/...")` devolve uma função. Os módulos do Dex retornam a tabela
  `{InitDeps, InitAfterMain, Main}`; os da ponte recebem um `ctx` (serviços, GUI do Studio Lite, Explorer, etc.).
- No arquivo único antigo, `game`, `oldgame`, `nodes` eram variáveis locais compartilhadas. Agora o `core.lua`
  as publica em `getgenv().DexPP_game / DexPP_oldgame / DexPP_nodes` e cada módulo lê de lá.
