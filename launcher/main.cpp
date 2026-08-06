// Caelestia Greeter launcher.
//
// Runs the greeter inside a Wayland compositor (e.g. cage). When monitor
// options are given, they are applied to the running compositor via
// wlr-randr (the wlr-output-management protocol) before quickshell starts,
// so users can pick which output(s) the greeter shows on, their mode,
// refresh rate, position, transform and scale.

#include <fcntl.h>
#include <limits.h>
#include <pwd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cerrno>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <regex>
#include <sstream>
#include <string>
#include <vector>

namespace {

void die(const std::string& msg) {
    std::fprintf(stderr, "caelestia-greeter: %s\n", msg.c_str());
    std::exit(1);
}

bool isDir(const std::string& path) {
    struct stat st {};
    return ::stat(path.c_str(), &st) == 0 && S_ISDIR(st.st_mode);
}

bool isFile(const std::string& path) {
    struct stat st {};
    return ::stat(path.c_str(), &st) == 0 && S_ISREG(st.st_mode);
}

std::string dirName(const std::string& path) {
    const size_t pos = path.find_last_of('/');
    if (pos == std::string::npos) {
        return ".";
    }
    if (pos == 0) {
        return "/";
    }
    return path.substr(0, pos);
}

std::string scriptDir(const char* argv0) {
    std::string path = argv0 == nullptr ? "" : argv0;
    if (!path.empty() && path.find('/') != std::string::npos) {
        char resolved[PATH_MAX];
        if (::realpath(path.c_str(), resolved) != nullptr) {
            path = resolved;
        }
    }
    return dirName(path);
}

bool commandAvailable(const std::string& name) {
    const char* path = std::getenv("PATH");
    if (path == nullptr) {
        return false;
    }
    const std::string env(path);
    size_t start = 0;
    for (;;) {
        const size_t end = env.find(':', start);
        std::string dir = end == std::string::npos ? env.substr(start) : env.substr(start, end - start);
        if (dir.empty()) {
            dir = ".";
        }
        if (::access((dir + "/" + name).c_str(), X_OK) == 0) {
            return true;
        }
        if (end == std::string::npos) {
            break;
        }
        start = end + 1;
    }
    return false;
}

// Runs `args` in a forked child with stdout/stderr sent to /dev/null and
// returns the child's exit status, or -1 on failure to run.
int runQuiet(const std::vector<std::string>& args) {
    std::vector<char*> argv;
    argv.reserve(args.size() + 1);
    for (const auto& arg : args) {
        argv.push_back(const_cast<char*>(arg.c_str()));
    }
    argv.push_back(nullptr);

    const pid_t pid = ::fork();
    if (pid < 0) {
        return -1;
    }
    if (pid == 0) {
        const int devnull = ::open("/dev/null", O_WRONLY);
        if (devnull >= 0) {
            ::dup2(devnull, STDOUT_FILENO);
            ::dup2(devnull, STDERR_FILENO);
            ::close(devnull);
        }
        ::execvp(argv[0], argv.data());
        ::_exit(127);
    }

    int status = 0;
    ::waitpid(pid, &status, 0);
    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }
    return -1;
}

// Expands a leading '~' (to `home`) and any $VAR / ${VAR} environment
// references in a path.
std::string expandPath(std::string path, const std::string& home) {
    if (path == "~") {
        return home;
    }
    if (path.rfind("~/", 0) == 0) {
        path.replace(0, 1, home);
    }
    for (;;) {
        const size_t dollar = path.find('$');
        if (dollar == std::string::npos) {
            break;
        }
        size_t end = dollar + 1;
        if (end < path.size() && path[end] == '{') {
            const size_t close = path.find('}', end);
            if (close == std::string::npos) {
                break;
            }
            const std::string name = path.substr(end + 1, close - end - 1);
            const char* val = std::getenv(name.c_str());
            path.replace(dollar, close - dollar + 1, val == nullptr ? "" : val);
        } else {
            while (end < path.size()
                   && (std::isalnum(static_cast<unsigned char>(path[end])) || path[end] == '_')) {
                ++end;
            }
            if (end == dollar + 1) {
                break;
            }
            const std::string name = path.substr(dollar + 1, end - dollar - 1);
            const char* val = std::getenv(name.c_str());
            path.replace(dollar, end - dollar, val == nullptr ? "" : val);
        }
    }
    return path;
}

// The real user to attribute the action to, honoring `sudo` invocations.
std::string currentUser() {
    if (const char* sudo = std::getenv("SUDO_USER"); sudo != nullptr && *sudo != '\0') {
        return sudo;
    }
    if (struct passwd* pw = ::getpwuid(::getuid()); pw != nullptr && pw->pw_name != nullptr) {
        return pw->pw_name;
    }
    return "user";
}

// Recursively creates a directory tree with 0755 permissions.
bool mkdirs(const std::string& path) {
    if (path.empty()) {
        return false;
    }
    std::string cur;
    for (size_t pos = path[0] == '/' ? 1 : 0; pos != std::string::npos;) {
        const size_t next = path.find('/', pos);
        cur = path.substr(0, next == std::string::npos ? path.size() : next);
        if (!cur.empty() && ::mkdir(cur.c_str(), 0755) != 0 && errno != EEXIST) {
            return false;
        }
        pos = next == std::string::npos ? std::string::npos : next + 1;
    }
    return true;
}

// Copies `source` into the shared avatar store as `<user>`, where the greeter
// process can read it even when the user's home directory is not traversable.
// Images are stored world-readable (0644); they are just profile pictures.
int setPfp(std::string source, const std::string& user) {
    const std::string avatarDir = "/var/cache/caelestia-greeter/avatars";

    std::string home;
    if (struct passwd* pw = ::getpwnam(user.c_str()); pw != nullptr && pw->pw_dir != nullptr) {
        home = pw->pw_dir;
    } else if (const char* h = std::getenv("HOME"); h != nullptr) {
        home = h;
    }
    source = expandPath(std::move(source), home.empty() ? "/home/" + user : home);

    if (!isFile(source)) {
        std::fprintf(stderr, "caelestia-greeter: '%s' is not a readable regular file\n", source.c_str());
        return 1;
    }
    if (!mkdirs(avatarDir)) {
        std::fprintf(stderr, "caelestia-greeter: could not create '%s'\n", avatarDir.c_str());
        return 1;
    }

    const std::string dest = avatarDir + "/" + user;

    std::ifstream in(source, std::ios::binary);
    std::ofstream out(dest, std::ios::binary | std::ios::trunc);
    if (!in || !out) {
        std::fprintf(stderr, "caelestia-greeter: could not write '%s'\n", dest.c_str());
        return 1;
    }
    out << in.rdbuf();
    out.close();
    if (!out) {
        std::fprintf(stderr, "caelestia-greeter: write to '%s' failed\n", dest.c_str());
        return 1;
    }
    ::chmod(dest.c_str(), 0644);

    std::printf("caelestia-greeter: set profile picture for '%s' from '%s'\n", user.c_str(), source.c_str());
    return 0;
}

// Lists connected output names from `wlr-randr` ("NAME \"desc\"" lines).
std::vector<std::string> listOutputs() {
    std::vector<std::string> names;
    FILE* pipe = ::popen("wlr-randr 2>/dev/null", "r");
    if (pipe == nullptr) {
        return names;
    }
    char* line = nullptr;
    size_t len = 0;
    while (::getline(&line, &len, pipe) != -1) {
        if (line[0] == ' ' || line[0] == '\t' || line[0] == '\n') {
            continue;
        }
        char name[256];
        if (std::sscanf(line, "%255s", name) == 1) {
            names.emplace_back(name);
        }
    }
    std::free(line);
    ::pclose(pipe);
    return names;
}

// Trims surrounding whitespace from a string.
std::string trim(const std::string& s) {
    const size_t first = s.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        return "";
    }
    const size_t last = s.find_last_not_of(" \t\r\n");
    return s.substr(first, last - first + 1);
}

// Removes surrounding double quotes from a string.
std::string stripQuotes(const std::string& s) {
    const std::string t = trim(s);
    if (t.size() >= 2 && t.front() == '"' && t.back() == '"') {
        return t.substr(1, t.size() - 2);
    }
    return t;
}

// Converts a Hyprland "WxH" position into wlr-randr's "X,Y" form.
std::string hyprPositionToWlr(std::string pos) {
    for (char& c : pos) {
        if (c == 'x') {
            c = ',';
        }
    }
    return pos;
}

// Maps a Hyprland transform number to wlr-randr's transform name.
std::string hyprTransformToWlr(int transform) {
    static const char* const names[] = {
        "normal",      "90",          "180",          "270",
        "flipped",     "flipped-90",  "flipped-180",  "flipped-270",
    };
    if (transform >= 0 && transform < 8) {
        return names[transform];
    }
    return "normal";
}

// Appends the monitor flags for one output (with a leading space unless the
// group is empty).
void appendMonitorGroup(std::vector<std::string>& groups, const std::string& name, bool disabled,
                        const std::string& mode, const std::string& position, const std::string& scale,
                        int transform) {
    if (name.empty()) {
        return;
    }
    std::string group = "--output " + name;
    if (disabled) {
        group += " --off";
    } else {
        if (mode == "preferred" || mode == "auto") {
            group += " --preferred";
        } else if (!mode.empty()) {
            group += " --mode " + mode;
        }
        if (!position.empty() && position != "auto") {
            group += " --pos " + hyprPositionToWlr(position);
        }
        if (!scale.empty() && scale != "auto") {
            group += " --scale " + scale;
        }
        if (transform != 0) {
            group += " --transform " + hyprTransformToWlr(transform);
        }
    }
    groups.push_back(group);
}

// Reads monitor configurations from a Hyprland config (either plain
// `monitor = ...` lines or Lua `hl.monitor({ ... })` blocks as generated by
// HyprMod) and prints the equivalent caelestia-greeter flags to stdout.
int convertFile(const std::string& path) {
    std::ifstream file(path);
    if (!file) {
        std::fprintf(stderr, "caelestia-greeter: could not open file '%s'\n", path.c_str());
        return 1;
    }
    std::ostringstream buf;
    buf << file.rdbuf();
    const std::string content = buf.str();

    std::vector<std::string> groups;

    // Lua `hl.monitor({ ... })` blocks
    static const std::regex blockRe(R"(hl\.monitor\s*\(\s*\{([\s\S]*?)\}\s*\))");
    static const std::regex pairRe(R"(([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*("[^"]*"|[^,\s][^,]*))");
    for (std::sregex_iterator it(content.begin(), content.end(), blockRe), end; it != end; ++it) {
        const std::string body = (*it)[1].str();
        std::string output;
        bool disabled = false;
        std::string mode;
        std::string position;
        std::string scale;
        int transform = 0;
        for (std::sregex_iterator p(body.begin(), body.end(), pairRe), pend; p != pend; ++p) {
            const std::string key = (*p)[1].str();
            const std::string value = stripQuotes((*p)[2].str());
            if (key == "output") {
                output = value;
            } else if (key == "disabled") {
                disabled = value == "true";
            } else if (key == "mode") {
                mode = value;
            } else if (key == "position") {
                position = value;
            } else if (key == "scale") {
                scale = value;
            } else if (key == "transform") {
                transform = std::atoi(value.c_str());
            }
        }
        appendMonitorGroup(groups, output, disabled, mode, position, scale, transform);
    }

    // Plain Hyprland `monitor = ...` lines
    static const std::regex monitorRe(R"(^\s*monitor\s*=\s*(.*)$)");
    std::istringstream lines(content);
    std::string line;
    while (std::getline(lines, line)) {
        std::smatch m;
        if (!std::regex_match(line, m, monitorRe)) {
            continue;
        }
        std::vector<std::string> fields;
        std::string cur;
        for (const char c : m[1].str()) {
            if (c == ',') {
                fields.push_back(trim(cur));
                cur.clear();
            } else {
                cur += c;
            }
        }
        fields.push_back(trim(cur));

        if (fields.empty() || fields[0].empty()) {
            continue;
        }
        const std::string name = fields[0];
        bool disabled = false;
        std::string mode;
        std::string position;
        std::string scale;
        int transform = 0;
        for (size_t i = 1; i < fields.size(); ++i) {
            const std::string field = trim(fields[i]);
            if (field.empty() || field == "auto") {
                continue;
            }
            if (field == "disable" || field == "disabled") {
                disabled = true;
            } else if (field == "preferred") {
                mode = "preferred";
            } else if (i == 1) {
                mode = field;
            } else if (i == 2) {
                position = field;
            } else if (i == 3) {
                scale = field;
            } else if (field == "transform" && i + 1 < fields.size()) {
                transform = std::atoi(fields[++i].c_str());
            }
        }
        appendMonitorGroup(groups, name, disabled, mode, position, scale, transform);
    }

    if (groups.empty()) {
        std::fprintf(stderr, "caelestia-greeter: no monitor configurations found in '%s'\n", path.c_str());
        return 1;
    }

    std::printf("caelestia-greeter");
    for (const auto& group : groups) {
        std::printf(" %s", group.c_str());
    }
    std::printf("\n");
    return 0;
}

void printUsage() {
    std::printf(
        "usage: caelestia-greeter [monitor options...] [quickshell options...]\n"
        "\n"
        "Monitor options (applied to the running compositor via wlr-randr):\n"
        "\n"
        "  --only NAME              disable every connected output except NAME\n"
        "                           (repeatable to keep several outputs)\n"
        "\n"
        "  --output NAME            target the named output; every following output\n"
        "                           option applies to it until the next --output\n"
        "\n"
        "  --on | --off | --toggle  enable / disable / toggle the current output\n"
        "\n"
        "  --mode WxH[@RATE]        set the current output mode (e.g. 1920x1080@144)\n"
        "  --custom-mode WxH[@RATE] same as --mode\n"
        "  --preferred              use the output's preferred mode\n"
        "\n"
        "  --pos X,Y                set the output position in the global layout\n"
        "  --left-of NAME           place the current output left of NAME\n"
        "  --right-of NAME          place the current output right of NAME\n"
        "  --above NAME             place the current output above NAME\n"
        "  --below NAME             place the current output below NAME\n"
        "\n"
        "  --transform TRANSFORM    normal|90|180|270|flipped|flipped-90|flipped-180|flipped-270\n"
        "  --scale FACTOR           set the output scaling factor\n"
        "\n"
        "  --adaptive-sync MODE     enabled|disabled\n"
        "\n"
        "Other modes:\n"
        "\n"
        "  --set-pfp FILE            copy FILE into the shared avatar store\n"
        "                           (/var/cache/caelestia-greeter/avatars/<user>)\n"
        "                           as the profile picture for the current user;\n"
        "                           run with sudo (the greeter cannot read user\n"
        "                           home directories). ~ and $VAR are expanded.\n"
        "\n"
        "  --convert FILE | -c FILE  read monitor configurations from a Hyprland\n"
        "                           config (plain `monitor =` lines or Lua\n"
        "                           `hl.monitor({ ... })` blocks) and print the\n"
        "                           equivalent caelestia-greeter flags\n"
        "\n"
        "Any other arguments are passed through to quickshell.\n"
        "\n"
        "Examples:\n"
        "  caelestia-greeter --only DP-2\n"
        "  sudo caelestia-greeter --set-pfp ~/.face\n"
        "  caelestia-greeter --output DP-2 --mode 2560x1440@120 --pos 0,0 \\\n"
        "                    --output DP-1 --off --output DP-3 --off\n");
}

}  // namespace

int main(int argc, char** argv) {
    if (const char* qpa = std::getenv("QT_QPA_PLATFORM"); qpa == nullptr || *qpa == '\0') {
        ::setenv("QT_QPA_PLATFORM", "wayland", 0);
    }

    // Resolve the configuration directory.
    const std::string dir = scriptDir(argv[0]);
    std::string configPath;
    if (const char* env = std::getenv("CAELESTIA_GREETER_DIR"); env != nullptr && *env != '\0' && isDir(env)) {
        configPath = env;
    } else if (isDir("/etc/xdg/quickshell/caelestia-greeter")) {
        configPath = "/etc/xdg/quickshell/caelestia-greeter";
    } else if (isDir(dir + "/../etc/xdg/quickshell/caelestia-greeter")) {
        configPath = dir + "/../etc/xdg/quickshell/caelestia-greeter";
    } else if (isDir("/usr/share/caelestia-greeter")) {
        configPath = "/usr/share/caelestia-greeter";
    } else if (isFile(dir + "/../shell.qml")) {
        configPath = dir + "/..";
    } else {
        die("could not locate configuration directory (set CAELESTIA_GREETER_DIR)");
    }

    // Parse monitor options.
    std::vector<std::string> randrArgs;
    std::vector<std::string> onlyKeep;
    std::vector<std::string> passthrough;
    bool haveRandR = false;
    std::string curOutput;

    for (int i = 1; i < argc; ++i) {
        const std::string arg = argv[i];
        const auto takeValue = [&]() -> std::string {
            if (i + 1 >= argc) {
                die("option '" + arg + "' requires an argument");
            }
            return argv[++i];
        };
        const auto requireOutput = [&]() {
            if (curOutput.empty()) {
                die("option '" + arg + "' used before --output");
            }
        };

        if (arg == "--help" || arg == "-h") {
            printUsage();
            return 0;
        } else if (arg == "--set-pfp") {
            return setPfp(takeValue(), currentUser());
        } else if (arg == "--convert" || arg == "-c") {
            return convertFile(takeValue());
        } else if (arg == "--only") {
            onlyKeep.push_back(takeValue());
            haveRandR = true;
        } else if (arg == "--output") {
            curOutput = takeValue();
            randrArgs.push_back("--output");
            randrArgs.push_back(curOutput);
            haveRandR = true;
        } else if (arg == "--on" || arg == "--off" || arg == "--toggle" || arg == "--preferred") {
            requireOutput();
            randrArgs.push_back(arg);
            haveRandR = true;
        } else if (arg == "--mode" || arg == "--custom-mode" || arg == "--pos" || arg == "--left-of" ||
                   arg == "--right-of" || arg == "--above" || arg == "--below" || arg == "--transform" ||
                   arg == "--scale" || arg == "--adaptive-sync") {
            requireOutput();
            randrArgs.push_back(arg);
            randrArgs.push_back(takeValue());
            haveRandR = true;
        } else {
            passthrough.push_back(arg);
        }
    }

    // Expand --only into --off for every other connected output.
    if (!onlyKeep.empty()) {
        if (!commandAvailable("wlr-randr")) {
            die("wlr-randr is required for '--only' but was not found in PATH");
        }
        const std::vector<std::string> outputs = listOutputs();
        if (outputs.empty()) {
            die("could not query connected outputs (is the compositor running?)");
        }
        for (const auto& name : outputs) {
            bool keep = false;
            for (const auto& keepName : onlyKeep) {
                if (name == keepName) {
                    keep = true;
                    break;
                }
            }
            if (!keep) {
                randrArgs.push_back("--output");
                randrArgs.push_back(name);
                randrArgs.push_back("--off");
            }
        }
    }

    // Apply the requested output configuration. The compositor is fully
    // initialized before this launcher is spawned (cage registers the
    // wlr-output-management global first), but retry a few times in case the
    // socket is not ready yet. On failure, warn and continue so greetd does
    // not enter a respawn loop.
    if (haveRandR) {
        if (!commandAvailable("wlr-randr")) {
            die("wlr-randr is required but was not found in PATH");
        }
        std::vector<std::string> cmd;
        cmd.reserve(randrArgs.size() + 1);
        cmd.push_back("wlr-randr");
        cmd.insert(cmd.end(), randrArgs.begin(), randrArgs.end());

        int result = -1;
        for (int attempt = 0; attempt < 20 && result != 0; ++attempt) {
            result = runQuiet(cmd);
            if (result != 0) {
                ::usleep(250000);
            }
        }
        if (result != 0) {
            std::fprintf(stderr, "caelestia-greeter: warning: could not apply wlr-randr configuration\n");
        }
    }

    // Hand off to quickshell.
    std::vector<std::string> qsArgs;
    qsArgs.reserve(passthrough.size() + 3);
    qsArgs.emplace_back("quickshell");
    qsArgs.emplace_back("-p");
    qsArgs.push_back(configPath);
    qsArgs.insert(qsArgs.end(), passthrough.begin(), passthrough.end());

    std::vector<char*> qsArgv;
    qsArgv.reserve(qsArgs.size() + 1);
    for (const auto& arg : qsArgs) {
        qsArgv.push_back(const_cast<char*>(arg.c_str()));
    }
    qsArgv.push_back(nullptr);

    ::execvp("quickshell", qsArgv.data());
    die("could not exec quickshell (is it installed and in PATH?)");
}
