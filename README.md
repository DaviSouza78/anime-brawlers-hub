# Anime Brawlers Hub

Menu Rayfield Gen2 para Anime Brawlers Simulator (place `117337409758030`).

## Carregar no Real

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DaviSouza78/anime-brawlers-hub/main/anime-brawlers-hub.luau"))()
```

## Auto Fuse

1. Abra a aba **Auto Fuse** e escolha o boneco que recebera o XP. O UID diferencia copias com o mesmo nome.
2. Selecione uma ou mais raridades usadas como material e confira a previa.
3. Ative **Ativar Auto Fuse**, ou use **Fundir um lote agora**.

Equipados, travados, o inicial e o destino nunca sao usados como material. Shinies exigem ativacao explicita. A fusao aguarda confirmacao do inventario antes de enviar outro lote, pausa na trial e para no nivel maximo. Materiais consumidos pela fusao sao removidos pelo jogo.

O menu inclui tambem Auto Attack, autofarm, auto open, Auto Trial, equipe, missoes e ajustes de desempenho. As automacoes iniciam desligadas. **F8** para os proximos lotes e as automacoes; **Right Ctrl** mostra/esconde o menu.

Execute novamente apos trocar de servidor. O codigo depende das interfaces do jogo e da biblioteca Rayfield Gen2, carregada de `sirius.menu/gen2`.

## Validacao

Auto Fuse: onze testes deterministas de selecao, protecoes e controle de pedidos passaram. A interface e a previa foram verificadas no cliente v3417. Nenhum material real foi consumido durante esses testes.
