#ifndef PLATFORM_PREFS_H
#define PLATFORM_PREFS_H

#include <stdio.h>

char *get_pref_file(const char *filename);

FILE *open_pref_file(const char *filename, const char *mode);

const char *pref_data_dir(void);

void pref_save_data_dir(const char *data_dir);

int is_save_game(const char * filepath);

#endif // PLATFORM_PREFS_H
