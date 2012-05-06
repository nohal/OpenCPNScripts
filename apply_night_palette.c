/*
   Apply Day, Dusk, and Night palettes to a KAP file header.

   (c) 2011 The OpenCPN Development Team
   http://www.opencpn.org

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.


   *** NOT FOR NAVIGATIONAL USE - USE AT YOUR OWN RISK ***
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


   This is experimental software intended to explore the KAP header format
   and teach the user how night-color palettes might be constructed.
   See also libbsb from http://libbsb.sf.net.

   USAGE:
   The -c flag performs the opposite action: clears DAY/DSK/NGT color rules.
   The -f flag tries to run the bsbfix program on the map after the edits.
   A backup of the input map is saved to "filename.kap~"
   The filename.kap must be the last command line arguement.

   BUGS:
   Probably. See above re. NOT FOR NAVIGATIONAL USE - USE AT YOUR OWN RISK
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define FALSE 0
#define TRUE 1

/* supported on non-GNU build environs?
   #include <unistd.h>   // for getopt() command line parsing
 */

/* tuned for NZ charts: */
#define DAY1 "127,127,127"
#define DAY2 "5,5,5"
#define DAY3 "100,0,127"
#define DAY4 "120,92,127"
#define DAY5 "30,95,108"
#define DAY6 "98,117,122"
#define DAY7 "49,85,58"
#define DAY8 "123,100,55"
#define DAY9 "92,75,41"

#define DSK1 "63,63,63"
#define DSK2 "2,2,2"
#define DSK3 "50,0,63"
#define DSK4 "60,46,63"
#define DSK5 "15,47,54"
#define DSK6 "49,58,61"
#define DSK7 "24,42,29"
#define DSK8 "61,50,27"
#define DSK9 "46,37,20"

#define NGT1 "0,0,0"
#define NGT2 "30,30,30"
#define NGT3 "30,0,30"
#define NGT4 "15,10,15"
#define NGT5 "0,10,25"
#define NGT6 "0,5,15"
#define NGT7 "0,15,0"
#define NGT8 "20,10,0"
#define NGT9 "18,18,18"

/* other possibilites: NGR/ (night red), GRY/ (grey), PRC/ (? color), PRG/ (? grey) */


int main(int argc, char *argv[])
{
    int i, j, k, palette_size;
    int clear_prev = FALSE, run_bsbfix = FALSE;
    int has_night_rules = FALSE, next_line_write = FALSE, task_is_done = FALSE;
    char c, ncolor_str[64], backupfile[4096], runcmd[4096], buff[32];
    char *filename;
    FILE *fp_orig, *fp_new;

    if (argc < 2 || argc > 4) {
	fprintf(stderr,
		"USAGE: apply_night_palette [-c] [-f] filename.kap\n");
	exit(EXIT_FAILURE);
    }

    for (i = 1; i < argc; i++) {
	if (strcmp(argv[i], "-c") == 0)
	    clear_prev = TRUE;
	if (strcmp(argv[i], "-f") == 0)
	    run_bsbfix = TRUE;
    }

    if (argc < clear_prev + run_bsbfix + 2) {
	fprintf(stderr,
		"USAGE: apply_night_palette [-c] [-f] filename.kap\n");
	exit(EXIT_FAILURE);
    }

    filename = argv[argc - 1];
    strncpy(backupfile, filename, sizeof(backupfile) - 2);
    strcat(backupfile, "~");
    strcpy(runcmd, "bsbfix ");
    strcat(runcmd, filename);

#define DEBUG 1
#ifdef DEBUG
    printf("clear? [%s]  run bsbfix? [%s]  filename=[%s]  backup=[%s]\n",
	   clear_prev ? "y" : "n", run_bsbfix ? "y" : "n",
	   filename, backupfile);
#endif


    /*** first we make a backup copy to work from ***/
    if ((fp_orig = fopen(filename, "rb")) == NULL) {
	fprintf(stderr, "Couldn't open [%s].\n", filename);
	exit(EXIT_FAILURE);
    }
    if ((fp_new = fopen(backupfile, "wb")) == NULL) {
	fprintf(stderr, "Couldn't open [%s] for backup.\n", backupfile);
	exit(EXIT_FAILURE);
    }

    i = j = -1;
    palette_size = 0;

    while (!feof(fp_orig)) {
	c = fgetc(fp_orig);
	if (ferror(fp_orig)) {
	    printf("Error reading from [%s].\n", filename);
	    exit(EXIT_FAILURE);
	}

	/* count number of RGB/ rules */
	if (c == '\n')
	    i = 0;
	else if (i >= 0) {
	    if (i == 0 && c == 'R')
		i++;
	    else if (i == 1 && c == 'G')
		i++;
	    else if (i == 2 && c == 'B')
		i++;
	    else if (i == 3 && c == '/')
		i++;
	    else if (i == 4 && c >= '1' && c <= '9') {
		palette_size++;
		i = -1;
	    }
	    else
		i = -1;
	}
	else
	    i = -1;


	/* search for NGT/ rules */
	if (c == '\n')
	    j = 0;
	else if (j >= 0) {
	    if (j == 0 && c == 'N')
		j++;
	    else if (j == 1 && c == 'G')
		j++;
	    else if (j == 2 && c == 'T')
		j++;
	    else if (j == 3 && c == '/')
		j++;
	    else if (j == 4 && c >= '1' && c <= '9') {
		has_night_rules = TRUE;
		j = -1;
	    }
	    else
		j = -1;
	}
	else
	    j = -1;


	if (!feof(fp_orig))
	    fputc(c, fp_new);
	if (ferror(fp_new)) {
	    printf("Error writing to [%s].\n", backupfile);
	    exit(EXIT_FAILURE);
	}
    }

    if (fclose(fp_orig) != 0) {
	printf("Error closing [%s] file.\n", filename);
	exit(EXIT_FAILURE);
    }
    if (fclose(fp_new) != 0) {
	printf("Error closing [%s] backup file.\n", backupfile);
	exit(EXIT_FAILURE);
    }


    sprintf(ncolor_str, "%d", palette_size);
    fprintf(stdout, "%d RGB palette entries found.\n", palette_size);

    if (has_night_rules) {
	fprintf(stdout, "Night colors already exist in [%s].", filename);
	if (!clear_prev) {
	    fprintf(stdout, " Exiting.\n");

	    unlink(backupfile);

	    if (run_bsbfix)
		system(runcmd);

	    exit(EXIT_SUCCESS);
	}
	else
	    fprintf(stdout, " These will be removed.\n");
    }



    /*** now that backup file is in place, get to work writing out a new one ***/
    if (unlink(filename) != 0) {
	printf("Error flushing [%s] file.\n", filename);
	exit(EXIT_FAILURE);
    }
    if ((fp_new = fopen(backupfile, "rb")) == NULL) {
	fprintf(stderr, "Couldn't open [%s].\n", backupfile);
	exit(EXIT_FAILURE);
    }
    if ((fp_orig = fopen(filename, "wb")) == NULL) {
	fprintf(stderr, "Couldn't open [%s].\n", filename);
	exit(EXIT_FAILURE);
    }

    while (!feof(fp_new)) {
	c = fgetc(fp_new);
	if (ferror(fp_new)) {
	    fprintf(stderr, "Error reading from [%s].\n", backupfile);
	    exit(EXIT_FAILURE);
	}

	if (clear_prev) {  /* remove DAY/DSK/NGT rules from file */

	    /* search for DAY/ */
	    if (c == '\n')
		i = 0;
	    else if (i >= 0) {
		if (i == 0 && c == 'D')
		    i++;
		else if (i == 1 && c == 'A')
		    i++;
		else if (i == 2 && c == 'Y')
		    i++;
		else if (i == 3 && c == '/') {
		    /* max str length = "RGB/128,255,255,255\r\n" (21), round up to 32. */
		    fgets(buff, sizeof(buff), fp_new);
		    //if( strlen(buff) == sizeof(buff)-1) printf("Processing error\n");
		    fseek(fp_new, -1, SEEK_CUR);
		    fseek(fp_orig, -4, SEEK_CUR);
		    i = -1;
		    continue;
		}
		else
		    i = -1;
	    }
	    else
		i = -1;

	    /* search for DSK/ */
	    if (c == '\n')
		j = 0;
	    else if (j >= 0) {
		if (j == 0 && c == 'D')
		    j++;
		else if (j == 1 && c == 'S')
		    j++;
		else if (j == 2 && c == 'K')
		    j++;
		else if (j == 3 && c == '/') {
		    fgets(buff, sizeof(buff), fp_new);
		    fseek(fp_new, -1, SEEK_CUR);
		    fseek(fp_orig, -4, SEEK_CUR);
		    j = -1;
		    continue;
		}
		else
		    j = -1;
	    }
	    else
		j = -1;

	    /* search for NGT/ */
	    if (c == '\n')
		k = 0;
	    else if (k >= 0) {
		if (k == 0 && c == 'N')
		    k++;
		else if (k == 1 && c == 'G')
		    k++;
		else if (k == 2 && c == 'T')
		    k++;
		else if (k == 3 && c == '/') {
		    fgets(buff, sizeof(buff), fp_new);
		    fseek(fp_new, -1, SEEK_CUR);
		    fseek(fp_orig, -4, SEEK_CUR);
		    k = -1;
		    continue;
		}
		else
		    k = -1;
	    }
	    else
		k = -1;
	}



	else {  /* add new rules */
	    if (c == '\n')
		i = 0;
	    else if (i >= 0) {
		if (i == 0 && c == 'R')
		    i++;
		else if (i == 1 && c == 'G')
		    i++;
		else if (i == 2 && c == 'B')
		    i++;
		else if (i == 3 && c == '/')
		    i++;
		else if (i == 4 && c == ncolor_str[0]) {
		    /* more needed here if palettes will have more than 9 entries */
		    i++;
		}
		else if (i == 5 && c == ',') {
		    next_line_write = TRUE;
		    i = -1;
		}
		else
		    i = -1;
	    }
	    else
		i = -1;

	    if (c == '\n' && next_line_write == TRUE && task_is_done == FALSE) {

		fprintf(fp_orig, "\n"
			"DAY/1,%s\r\n"
			"DAY/2,%s\r\n"
			"DAY/3,%s\r\n"
			"DAY/4,%s\r\n"
			"DAY/5,%s\r\n"
			"DAY/6,%s\r\n",
			DAY1, DAY2, DAY3, DAY4, DAY5, DAY6);
		if (palette_size >= 7)
		    fprintf(fp_orig, "DAY/7,%s\r\n", DAY7);
		if (palette_size >= 8)
		    fprintf(fp_orig, "DAY/8,%s\r\n", DAY8);
		if (palette_size >= 9)
		    fprintf(fp_orig, "DAY/9,%s\r\n", DAY9);

		fprintf(fp_orig,
			"DSK/1,%s\r\n"
			"DSK/2,%s\r\n"
			"DSK/3,%s\r\n"
			"DSK/4,%s\r\n"
			"DSK/5,%s\r\n"
			"DSK/6,%s\r\n",
			DSK1, DSK2, DSK3, DSK4, DSK5, DSK6);
		if (palette_size >= 7)
		    fprintf(fp_orig, "DSK/7,%s\r\n", DSK7);
		if (palette_size >= 8)
		    fprintf(fp_orig, "DSK/8,%s\r\n", DSK8);
		if (palette_size >= 9)
		    fprintf(fp_orig, "DSK/9,%s\r\n", DSK9);

		fprintf(fp_orig,
			"NGT/1,%s\r\n"
			"NGT/2,%s\r\n"
			"NGT/3,%s\r\n"
			"NGT/4,%s\r\n"
			"NGT/5,%s\r\n"
			"NGT/6,%s\r",
			NGT1, NGT2, NGT3, NGT4, NGT5, NGT6);
		if (palette_size >= 7)
		    fprintf(fp_orig, "\nNGT/7,%s\r", NGT7);
		if (palette_size >= 8)
		    fprintf(fp_orig, "\nNGT/8,%s\r", NGT8);
		if (palette_size >= 9)
		    fprintf(fp_orig, "\nNGT/9,%s\r", NGT9);

		next_line_write = FALSE;
		task_is_done = TRUE;
	    }
	}

	if (!feof(fp_new))
	    fputc(c, fp_orig);
	if (ferror(fp_orig)) {
	    fprintf(stderr, "Error writing to [%s].\n", filename);
	    exit(EXIT_FAILURE);
	}
    }


    if (fclose(fp_new) != 0) {
	fprintf(stderr, "Error closing [%s].\n", backupfile);
	exit(EXIT_FAILURE);
    }
    if (fclose(fp_orig) != 0) {
	fprintf(stderr, "Error closing [%s].\n", filename);
	exit(EXIT_FAILURE);
    }


    if (run_bsbfix)
	system(runcmd);
    else
	fprintf(stdout, "You need to run: \"%s\"\n", runcmd);


    exit(EXIT_SUCCESS);
}
