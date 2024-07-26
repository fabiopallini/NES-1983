ca65 main.asm -o main.o
ld65 main.o -o game.nes -t nes
rm main.o
fceux game.nes
