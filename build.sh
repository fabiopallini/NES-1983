ca65 main.asm -o main.o && \
ld65 main.o -t nes -o game.nes && \
rm main.o && \
fceux game.nes
