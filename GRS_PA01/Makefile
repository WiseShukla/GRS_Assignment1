CC = gcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS_A = -lm
LDFLAGS_B = -lpthread -lm

all: program_a program_b

program_a: PhD25001_Part_A_Program_A.c
	$(CC) $(CFLAGS) -o program_a PhD25001_Part_A_Program_A.c $(LDFLAGS_A)

program_b: PhD25001_Part_B_Program_B.c
	$(CC) $(CFLAGS) -o program_b PhD25001_Part_B_Program_B.c $(LDFLAGS_B)

run_c: all
	chmod +x PhD25001_Part_C_shell.sh
	./PhD25001_Part_C_shell.sh

run_d: all
	chmod +x PhD25001_Part_D_shell.sh
	./PhD25001_Part_D_shell.sh

clean:
	rm -f program_a program_b *.csv *.png *.tmp