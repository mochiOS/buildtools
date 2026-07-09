#include <ctype.h>
#include <errno.h>
#include <locale.h>
#include <ncurses.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#define MAX_OPTIONS 512
#define MAX_CHOICES 32
#define MAX_UNKNOWN 512
#define MAX_LINE 1024
#define KEY_SIZE 128
#define PROMPT_SIZE 256
#define CATEGORY_SIZE 128
#define VALUE_SIZE 256
#define CHOICE_SIZE 128
#define ERROR_SIZE 2048

typedef enum {
    OPT_BOOL,
    OPT_STRING,
    OPT_CHOICE,
} OptionType;

typedef struct {
    char key[KEY_SIZE];
    char prompt[PROMPT_SIZE];
    char category[CATEGORY_SIZE];

    OptionType type;

    char value[VALUE_SIZE];
    char default_value[VALUE_SIZE];

    char choices[MAX_CHOICES][CHOICE_SIZE];
    size_t choice_count;
} ConfigOption;

typedef struct {
    ConfigOption options[MAX_OPTIONS];
    size_t option_count;

    char unknown_lines[MAX_UNKNOWN][MAX_LINE];
    size_t unknown_count;
} ConfigState;

typedef enum {
    UI_NORMAL = 1,
    UI_HEADER,
    UI_PANEL,
    UI_PANEL_TITLE,
    UI_SELECTED,
    UI_CATEGORY,
    UI_VALUE,
    UI_FOOTER,
    UI_STATUS,
    UI_DIRTY,
} UiColor;

static bool ui_color_enabled = false;

static void init_ui_theme(void) {
    if (!has_colors()) {
        return;
    }

    start_color();
    use_default_colors();

    init_pair(UI_NORMAL, COLOR_WHITE, -1);
    init_pair(UI_HEADER, COLOR_BLACK, COLOR_CYAN);
    init_pair(UI_PANEL, COLOR_WHITE, -1);
    init_pair(UI_PANEL_TITLE, COLOR_CYAN, -1);
    init_pair(UI_SELECTED, COLOR_BLACK, COLOR_WHITE);
    init_pair(UI_CATEGORY, COLOR_CYAN, -1);
    init_pair(UI_VALUE, COLOR_GREEN, -1);
    init_pair(UI_FOOTER, COLOR_BLACK, COLOR_WHITE);
    init_pair(UI_STATUS, COLOR_GREEN, -1);
    init_pair(UI_DIRTY, COLOR_YELLOW, -1);

    ui_color_enabled = true;
}

static void ui_attr_on(const int pair, const int attrs) {
    if (ui_color_enabled) {
        attron(COLOR_PAIR(pair));
    }

    if (attrs != A_NORMAL) {
        attron(attrs);
    }
}

static void ui_attr_off(const int pair, const int attrs) {
    if (attrs != A_NORMAL) {
        attroff(attrs);
    }

    if (ui_color_enabled) {
        attroff(COLOR_PAIR(pair));
    }
}

static void draw_fill(const int y, const int x, const int width) {
    if (width <= 0) {
        return;
    }

    mvhline(y, x, ' ', width);
}

static void draw_box(const int y, const int x, const int height, const int width) {
    if (height < 2 || width < 2) {
        return;
    }

    mvaddch(y, x, ACS_ULCORNER);
    mvaddch(y, x + width - 1, ACS_URCORNER);
    mvaddch(y + height - 1, x, ACS_LLCORNER);
    mvaddch(y + height - 1, x + width - 1, ACS_LRCORNER);

    mvhline(y, x + 1, ACS_HLINE, width - 2);
    mvhline(y + height - 1, x + 1, ACS_HLINE, width - 2);
    mvvline(y + 1, x, ACS_VLINE, height - 2);
    mvvline(y + 1, x + width - 1, ACS_VLINE, height - 2);
}

static void draw_right_text(const int y, const char *text, const int max_x) {
    const int len = (int)strlen(text);

    if (len >= max_x) {
        return;
    }

    mvaddnstr(y, max_x - len - 2, text, len);
}

static void copy_string(char *dst, const size_t dst_size, const char *src) {
    if (src == NULL) {
        dst[0] = '\0';
        return;
    }

    size_t len = strlen(src);

    if (len >= dst_size) {
        len = dst_size - 1;
    }

    memcpy(dst, src, len);
    dst[len] = '\0';
}

static void set_error(char *error, const char *format, ...) {
    va_list args;
    va_start(args, format);
    const int written = vsnprintf(error, ERROR_SIZE, format, args);
    va_end(args);

    if (written < 0) {
        copy_string(error, ERROR_SIZE, "failed to format error message");
    } else if ((size_t)written >= ERROR_SIZE) {
        error[ERROR_SIZE - 1] = '\0';
    }
}

static char *trim(char *text) {
    while (isspace((unsigned char)*text)) {
        text++;
    }

    char *end = text + strlen(text);
    while (end > text && isspace((unsigned char)end[-1])) {
        end--;
    }

    *end = '\0';
    return text;
}

static bool starts_with(const char *text, const char *prefix) {
    return strncmp(text, prefix, strlen(prefix)) == 0;
}

static void skip_spaces(char **cursor) {
    while (isspace((unsigned char)**cursor)) {
        (*cursor)++;
    }
}

static bool read_word(char **cursor, char *out, const size_t out_size) {
    skip_spaces(cursor);

    if (**cursor == '\0') {
        return false;
    }

    size_t len = 0;

    while (**cursor != '\0' && !isspace((unsigned char)**cursor)) {
        if (len + 1 < out_size) {
            out[len++] = **cursor;
        }

        (*cursor)++;
    }

    out[len] = '\0';
    return len > 0;
}

static bool read_quoted(char **cursor, char *out, const size_t out_size) {
    skip_spaces(cursor);

    if (**cursor != '"') {
        return false;
    }

    (*cursor)++;

    size_t len = 0;

    while (**cursor != '\0' && **cursor != '"') {
        char c = **cursor;

        if (c == '\\') {
            (*cursor)++;

            if (**cursor == '\0') {
                break;
            }

            switch (**cursor) {
                case 'n':
                    c = '\n';
                    break;
                case 't':
                    c = '\t';
                    break;
                case '"':
                    c = '"';
                    break;
                case '\\':
                    c = '\\';
                    break;
                default:
                    c = **cursor;
                    break;
            }
        }

        if (len + 1 < out_size) {
            out[len++] = c;
        }

        (*cursor)++;
    }

    if (**cursor != '"') {
        return false;
    }

    (*cursor)++;
    out[len] = '\0';

    return true;
}

static bool read_value(char **cursor, char *out, const size_t out_size) {
    skip_spaces(cursor);

    if (**cursor == '"') {
        return read_quoted(cursor, out, out_size);
    }

    return read_word(cursor, out, out_size);
}

static ConfigOption *find_option(ConfigState *state, const char *key) {
    for (size_t i = 0; i < state->option_count; i++) {
        if (strcmp(state->options[i].key, key) == 0) {
            return &state->options[i];
        }
    }

    return NULL;
}

static bool choice_contains(const ConfigOption *option, const char *value) {
    for (size_t i = 0; i < option->choice_count; i++) {
        if (strcmp(option->choices[i], value) == 0) {
            return true;
        }
    }

    return false;
}

static int choice_index(const ConfigOption *option) {
    for (size_t i = 0; i < option->choice_count; i++) {
        if (strcmp(option->choices[i], option->value) == 0) {
            return (int)i;
        }
    }

    return 0;
}

static bool parse_option_line(
    ConfigState *state,
    char *line,
    const char *category,
    const size_t line_number
) {
    if (state->option_count >= MAX_OPTIONS) {
        fprintf(stderr, "schema:%zu: too many options\n", line_number);
        return false;
    }

    char *cursor = line;

    char type_word[32];
    char key[KEY_SIZE];
    char prompt[PROMPT_SIZE];
    char default_value[VALUE_SIZE];

    if (!read_word(&cursor, type_word, sizeof(type_word))) {
        return true;
    }

    if (!read_word(&cursor, key, sizeof(key))) {
        fprintf(stderr, "schema:%zu: missing key\n", line_number);
        return false;
    }

    if (!read_quoted(&cursor, prompt, sizeof(prompt))) {
        fprintf(stderr, "schema:%zu: missing prompt\n", line_number);
        return false;
    }

    ConfigOption *option = &state->options[state->option_count];
    memset(option, 0, sizeof(*option));

    copy_string(option->key, sizeof(option->key), key);
    copy_string(option->prompt, sizeof(option->prompt), prompt);
    copy_string(option->category, sizeof(option->category), category);

    if (strcmp(type_word, "bool") == 0) {
        option->type = OPT_BOOL;

        if (!read_value(&cursor, default_value, sizeof(default_value))) {
            copy_string(default_value, sizeof(default_value), "n");
        }

        if (strcmp(default_value, "y") != 0 && strcmp(default_value, "n") != 0) {
            fprintf(stderr, "schema:%zu: bool default must be y or n\n", line_number);
            return false;
        }

        copy_string(option->default_value, sizeof(option->default_value), default_value);
        copy_string(option->value, sizeof(option->value), default_value);
    } else if (strcmp(type_word, "string") == 0) {
        option->type = OPT_STRING;

        if (!read_value(&cursor, default_value, sizeof(default_value))) {
            default_value[0] = '\0';
        }

        copy_string(option->default_value, sizeof(option->default_value), default_value);
        copy_string(option->value, sizeof(option->value), default_value);
    } else if (strcmp(type_word, "choice") == 0) {
        option->type = OPT_CHOICE;

        if (!read_value(&cursor, default_value, sizeof(default_value))) {
            fprintf(stderr, "schema:%zu: missing choice default\n", line_number);
            return false;
        }

        copy_string(option->default_value, sizeof(option->default_value), default_value);
        copy_string(option->value, sizeof(option->value), default_value);

        char choice[CHOICE_SIZE];

        while (read_value(&cursor, choice, sizeof(choice))) {
            if (option->choice_count >= MAX_CHOICES) {
                fprintf(stderr, "schema:%zu: too many choices\n", line_number);
                return false;
            }

            copy_string(
                option->choices[option->choice_count],
                sizeof(option->choices[option->choice_count]),
                choice
            );

            option->choice_count++;
        }

        if (option->choice_count == 0) {
            fprintf(stderr, "schema:%zu: choice needs values\n", line_number);
            return false;
        }

        if (!choice_contains(option, option->default_value)) {
            fprintf(stderr, "schema:%zu: choice default is not in values\n", line_number);
            return false;
        }
    } else {
        fprintf(stderr, "schema:%zu: unknown option type: %s\n", line_number, type_word);
        return false;
    }

    state->option_count++;
    return true;
}

static bool load_schema(ConfigState *state, const char *path) {
    FILE *file = fopen(path, "r");

    if (file == NULL) {
        fprintf(stderr, "failed to open schema: %s: %s\n", path, strerror(errno));
        return false;
    }

    char line[MAX_LINE];
    char category[CATEGORY_SIZE] = "General";

    size_t line_number = 0;

    while (fgets(line, sizeof(line), file) != NULL) {
        line_number++;

        char *text = trim(line);

        if (*text == '\0' || *text == '#') {
            continue;
        }

        if (starts_with(text, "menu")) {
            char *cursor = text + 4;
            char name[CATEGORY_SIZE];

            if (!read_quoted(&cursor, name, sizeof(name))) {
                fprintf(stderr, "schema:%zu: menu needs quoted name\n", line_number);
                fclose(file);
                return false;
            }

            copy_string(category, sizeof(category), name);
            continue;
        }

        if (strcmp(text, "endmenu") == 0) {
            copy_string(category, sizeof(category), "General");
            continue;
        }

        if (!parse_option_line(state, text, category, line_number)) {
            fclose(file);
            return false;
        }
    }

    fclose(file);
    return true;
}

static void normalize_config_value(ConfigOption *option) {
    if (option->type == OPT_BOOL) {
        if (strcmp(option->value, "y") != 0 && strcmp(option->value, "n") != 0) {
            copy_string(option->value, sizeof(option->value), option->default_value);
        }
    } else if (option->type == OPT_CHOICE) {
        if (!choice_contains(option, option->value)) {
            copy_string(option->value, sizeof(option->value), option->default_value);
        }
    }
}

static void load_config(ConfigState *state, const char *path) {
    FILE *file = fopen(path, "r");

    if (file == NULL) {
        return;
    }

    char line[MAX_LINE];

    while (fgets(line, sizeof(line), file) != NULL) {
        char original[MAX_LINE];
        copy_string(original, sizeof(original), line);
        original[strcspn(original, "\r\n")] = '\0';

        char *text = trim(line);

        if (*text == '\0' || *text == '#') {
            continue;
        }

        char *equal = strchr(text, '=');

        if (equal == NULL) {
            continue;
        }

        *equal = '\0';

        char *key = trim(text);
        char *value_text = trim(equal + 1);

        ConfigOption *option = find_option(state, key);

        if (option == NULL) {
            if (starts_with(key, "CONFIG_") && state->unknown_count < MAX_UNKNOWN) {
                copy_string(
                    state->unknown_lines[state->unknown_count],
                    sizeof(state->unknown_lines[state->unknown_count]),
                    trim(original)
                );

                state->unknown_count++;
            }

            continue;
        }

        char *cursor = value_text;
        char value[VALUE_SIZE];

        if (!read_value(&cursor, value, sizeof(value))) {
            value[0] = '\0';
        }

        copy_string(option->value, sizeof(option->value), value);
        normalize_config_value(option);
    }

    fclose(file);
}

static void escape_config_string(FILE *file, const char *value) {
    fputc('"', file);

    for (const char *p = value; *p != '\0'; p++) {
        switch (*p) {
            case '\\':
                fputs("\\\\", file);
                break;
            case '"':
                fputs("\\\"", file);
                break;
            case '\n':
                fputs("\\n", file);
                break;
            case '\t':
                fputs("\\t", file);
                break;
            default:
                fputc(*p, file);
                break;
        }
    }

    fputc('"', file);
}

static bool save_config(
    ConfigState *state,
    const char *path,
    char *error
) {
    char tmp_path[1024];
    const int tmp_written = snprintf(tmp_path, sizeof(tmp_path), "%s.tmp", path);

    if (tmp_written < 0 || (size_t)tmp_written >= sizeof(tmp_path)) {
        set_error(error, "config path is too long: %s", path);
        return false;
    }

    FILE *file = fopen(tmp_path, "w");

    if (file == NULL) {
        set_error(error, "config path is too long: %s", path);
        return false;
    }

    fprintf(file, "# Generated by mochiOS menuconfig\n");

    for (size_t i = 0; i < state->option_count; i++) {
        ConfigOption *option = &state->options[i];

        fprintf(file, "%s=", option->key);

        if (option->type == OPT_BOOL) {
            fprintf(file, "%s", option->value);
        } else {
            escape_config_string(file, option->value);
        }

        fputc('\n', file);
    }

    if (state->unknown_count > 0) {
        fprintf(file, "\n# Preserved unknown entries\n");

        for (size_t i = 0; i < state->unknown_count; i++) {
            fprintf(file, "%s\n", state->unknown_lines[i]);
        }
    }

    if (fclose(file) != 0) {
        set_error(error, "config path is too long: %s", path);
        return false;
    }

    if (rename(tmp_path, path) != 0) {
        set_error(error, "config path is too long: %s", path);
        return false;
    }

    return true;
}

static void option_display_value(
    const ConfigOption *option,
    char *out
) {
    const size_t out_size = 264;

    if (option->type == OPT_BOOL) {
        copy_string(out, out_size, strcmp(option->value, "y") == 0 ? "[*]" : "[ ]");
    } else if (option->type == OPT_STRING) {
        snprintf(out, out_size, "\"%s\"", option->value);
    } else {
        snprintf(out, out_size, "<%s>", option->value);
    }
}

static void render(
    ConfigState *state,
    const int selected,
    const int offset,
    const bool dirty,
    const char *config_path,
    const char *status
) {
    int max_y;
    int max_x;

    getmaxyx(stdscr, max_y, max_x);

    erase();

    if (max_y < 8 || max_x < 48) {
        mvaddnstr(0, 0, "terminal is too small", max_x - 1);
        refresh();
        return;
    }

    ui_attr_on(UI_HEADER, A_BOLD);
    draw_fill(0, 0, max_x);
    mvaddnstr(0, 2, "mochiOS BuildConfig", max_x - 4);

    if (dirty) {
        draw_right_text(0, "[modified]", max_x);
    } else {
        draw_right_text(0, "[clean]", max_x);
    }

    ui_attr_off(UI_HEADER, A_BOLD);

    ui_attr_on(UI_NORMAL, A_NORMAL);
    draw_fill(1, 0, max_x);
    mvaddnstr(1, 2, "Config:", max_x - 4);
    mvaddnstr(1, 10, config_path, max_x - 12);
    ui_attr_off(UI_NORMAL, A_NORMAL);

    const int panel_y = 3;
    const int panel_x = 1;
    const int panel_h = max_y - 7;
    const int panel_w = max_x - 2;

    ui_attr_on(UI_PANEL, A_NORMAL);
    draw_box(panel_y, panel_x, panel_h, panel_w);
    ui_attr_off(UI_PANEL, A_NORMAL);

    ui_attr_on(UI_PANEL_TITLE, A_BOLD);
    mvaddnstr(panel_y, panel_x + 2, " Options ", panel_w - 4);
    ui_attr_off(UI_PANEL_TITLE, A_BOLD);

    const int header_y = panel_y + 1;
    const int list_y = panel_y + 2;
    const int list_h = panel_h - 3;

    const int category_x = panel_x + 3;
    const int prompt_x = panel_x + 18;
    int value_x = max_x - 30;

    if (value_x < prompt_x + 16) {
        value_x = prompt_x + 16;
    }

    const int category_w = prompt_x - category_x - 1;
    const int prompt_w = value_x - prompt_x - 2;
    const int value_w = max_x - value_x - 3;

    ui_attr_on(UI_PANEL_TITLE, A_BOLD);
    mvaddnstr(header_y, category_x, "Category", category_w);
    mvaddnstr(header_y, prompt_x, "Option", prompt_w);
    mvaddnstr(header_y, value_x, "Value", value_w);
    ui_attr_off(UI_PANEL_TITLE, A_BOLD);

    for (int row = 0; row < list_h; row++) {
        const int option_index = offset + row;
        const int y = list_y + row;

        draw_fill(y, panel_x + 1, panel_w - 2);

        if (option_index >= (int)state->option_count) {
            continue;
        }

        ConfigOption *option = &state->options[option_index];

        char value[VALUE_SIZE + 8];
        option_display_value(option, value);

        const bool is_selected = option_index == selected;

        if (is_selected) {
            ui_attr_on(UI_SELECTED, A_BOLD);
            draw_fill(y, panel_x + 1, panel_w - 2);
            mvaddnstr(y, panel_x + 2, ">", 1);
            mvaddnstr(y, category_x, option->category, category_w);
            mvaddnstr(y, prompt_x, option->prompt, prompt_w);
            mvaddnstr(y, value_x, value, value_w);
            ui_attr_off(UI_SELECTED, A_BOLD);
        } else {
            ui_attr_on(UI_CATEGORY, A_NORMAL);
            mvaddnstr(y, category_x, option->category, category_w);
            ui_attr_off(UI_CATEGORY, A_NORMAL);

            ui_attr_on(UI_NORMAL, A_NORMAL);
            mvaddnstr(y, prompt_x, option->prompt, prompt_w);
            ui_attr_off(UI_NORMAL, A_NORMAL);

            ui_attr_on(UI_VALUE, A_NORMAL);
            mvaddnstr(y, value_x, value, value_w);
            ui_attr_off(UI_VALUE, A_NORMAL);
        }
    }

    int progress_y = max_y - 4;
    char progress[64];

    snprintf(
        progress,
        sizeof(progress),
        "%d/%zu",
        selected + 1,
        state->option_count
    );

    ui_attr_on(UI_NORMAL, A_DIM);
    mvaddnstr(progress_y, 2, progress, max_x - 4);
    ui_attr_off(UI_NORMAL, A_DIM);

    const int footer_y = max_y - 2;

    ui_attr_on(UI_FOOTER, A_NORMAL);
    draw_fill(footer_y, 0, max_x);
    mvaddnstr(
        footer_y,
        2,
        "Up/Down: move   Space: toggle/next   Enter: edit/next   s: save   q: quit",
        max_x - 4
    );
    ui_attr_off(UI_FOOTER, A_NORMAL);

    draw_fill(max_y - 1, 0, max_x);

    if (status[0] != '\0') {
        ui_attr_on(UI_STATUS, A_BOLD);
        mvaddnstr(max_y - 1, 2, status, max_x - 4);
        ui_attr_off(UI_STATUS, A_BOLD);
    } else if (dirty) {
        ui_attr_on(UI_DIRTY, A_NORMAL);
        mvaddnstr(max_y - 1, 2, "Unsaved changes", max_x - 4);
        ui_attr_off(UI_DIRTY, A_NORMAL);
    } else {
        ui_attr_on(UI_NORMAL, A_DIM);
        mvaddnstr(max_y - 1, 2, "Ready", max_x - 4);
        ui_attr_off(UI_NORMAL, A_DIM);
    }

    refresh();
}

static void toggle_bool(ConfigOption *option) {
    copy_string(
        option->value,
        sizeof(option->value),
        strcmp(option->value, "y") == 0 ? "n" : "y"
    );
}

static void cycle_choice(ConfigOption *option) {
    if (option->choice_count == 0) {
        return;
    }

    int index = choice_index(option);
    index = (index + 1) % (int)option->choice_count;

    copy_string(option->value, sizeof(option->value), option->choices[index]);
}

static void edit_string(ConfigOption *option) {
    int max_y;
    int max_x;

    getmaxyx(stdscr, max_y, max_x);

    char input[VALUE_SIZE];
    copy_string(input, sizeof(input), option->value);

    move(max_y - 1, 0);
    clrtoeol();
    mvprintw(max_y - 1, 0, "%s: ", option->prompt);

    echo();
    curs_set(1);
    getnstr(input, (int)sizeof(input) - 1);
    curs_set(0);
    noecho();

    (void)max_x;

    copy_string(option->value, sizeof(option->value), input);
}

static bool confirm_discard(void) {
    int max_y;
    int max_x;

    getmaxyx(stdscr, max_y, max_x);

    move(max_y - 1, 0);
    clrtoeol();
    mvaddnstr(max_y - 1, 0, "Discard unsaved changes? y/N", max_x - 1);
    refresh();

    const int ch = getch();

    return ch == 'y' || ch == 'Y';
}

static void usage(const char *program) {
    fprintf(stderr, "usage: %s --schema <schema.conf> --config <.config>\n", program);
}

int main(const int argc, char **argv) {
    const char *schema_path = NULL;
    const char *config_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--schema") == 0 && i + 1 < argc) {
            schema_path = argv[++i];
        } else if (strcmp(argv[i], "--config") == 0 && i + 1 < argc) {
            config_path = argv[++i];
        } else {
            usage(argv[0]);
            return 1;
        }
    }

    if (schema_path == NULL || config_path == NULL) {
        usage(argv[0]);
        return 1;
    }

    ConfigState state = {0};

    if (!load_schema(&state, schema_path)) {
        return 1;
    }

    if (state.option_count == 0) {
        fprintf(stderr, "schema has no options\n");
        return 1;
    }

    load_config(&state, config_path);

    setlocale(LC_ALL, "");

    initscr();
    init_ui_theme();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
    curs_set(0);

    bool dirty = false;
    int selected = 0;
    int offset = 0;
    char status[256] = "";

    for (;;) {
        int max_y;
        int max_x;

        getmaxyx(stdscr, max_y, max_x);

        int visible = max_y - 6;

        if (visible < 1) {
            visible = 1;
        }

        if (selected < offset) {
            offset = selected;
        }

        if (selected >= offset + visible) {
            offset = selected - visible + 1;
        }

        render(&state, selected, offset, dirty, config_path, status);
        status[0] = '\0';

        const int ch = getch();
        ConfigOption *option = &state.options[selected];

        if (ch == KEY_UP || ch == 'k') {
            if (selected > 0) {
                selected--;
            }
        } else if (ch == KEY_DOWN || ch == 'j') {
            if (selected + 1 < (int)state.option_count) {
                selected++;
            }
        } else if (ch == ' ') {
            if (option->type == OPT_BOOL) {
                toggle_bool(option);
                dirty = true;
            } else if (option->type == OPT_CHOICE) {
                cycle_choice(option);
                dirty = true;
            }
        } else if (ch == '\n' || ch == '\r' || ch == KEY_ENTER) {
            if (option->type == OPT_STRING) {
                edit_string(option);
                dirty = true;
            } else if (option->type == OPT_BOOL) {
                toggle_bool(option);
                dirty = true;
            } else if (option->type == OPT_CHOICE) {
                cycle_choice(option);
                dirty = true;
            }
        } else if (ch == 's' || ch == 'S') {
            char error[ERROR_SIZE];

            if (save_config(&state, config_path, error)) {
                dirty = false;
                copy_string(status, sizeof(status), "saved");
            } else {
                copy_string(status, sizeof(status), error);
            }
        } else if (ch == 'q' || ch == 'Q') {
            if (!dirty || confirm_discard()) {
                break;
            }
        }

        (void)max_x;
    }

    endwin();

    return 0;
}