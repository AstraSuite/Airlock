#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <cctype>
#include <fstream>
#include <iostream>
#include <memory>
#include <regex>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include <fcntl.h>
#include <limits.h>
#include <pwd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

namespace {

[[noreturn]] void die(const std::string& msg) {
    std::fprintf(stderr, "caelestia-greeter: error: %s\n", msg.c_str());
    std::exit(1);
}

bool isDir(const std::string& path) {
    struct stat st;
    return ::stat(path.c_str(), &st) == 0 && S_ISDIR(st.st_mode);
}

bool isFile(const std::string& path) {
    struct stat st;
    return ::stat(path.c_str(), &st) == 0 && S_ISREG(st.st_mode);
}

std::string dirName(const std::string& path) {
    const size_t pos = path.rfind('/');
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

// Runs `args` and captures stderr output. Returns the exit status.
int runCommand(const std::vector<std::string>& args, std::string* outStderr = nullptr) {
    std::vector<char*> argv;
    argv.reserve(args.size() + 1);
    for (const auto& arg : args) {
        argv.push_back(const_cast<char*>(arg.c_str()));
    }
    argv.push_back(nullptr);

    int pipefd[2];
    if (outStderr != nullptr) {
        if (::pipe(pipefd) < 0) {
            return -1;
        }
    }

    const pid_t pid = ::fork();
    if (pid < 0) {
        if (outStderr != nullptr) {
            ::close(pipefd[0]);
            ::close(pipefd[1]);
        }
        return -1;
    }
    if (pid == 0) {
        const int devnull = ::open("/dev/null", O_WRONLY);
        if (devnull >= 0) {
            ::dup2(devnull, STDOUT_FILENO);
        }
        if (outStderr != nullptr) {
            ::close(pipefd[0]);
            ::dup2(pipefd[1], STDERR_FILENO);
            ::close(pipefd[1]);
        } else if (devnull >= 0) {
            ::dup2(devnull, STDERR_FILENO);
        }
        if (devnull >= 0) {
            ::close(devnull);
        }
        ::execvp(argv[0], argv.data());
        ::_exit(127);
    }

    if (outStderr != nullptr) {
        ::close(pipefd[1]);
        char buf[512];
        ssize_t n;
        while ((n = ::read(pipefd[0], buf, sizeof(buf) - 1)) > 0) {
            buf[n] = '\0';
            *outStderr += buf;
        }
        ::close(pipefd[0]);
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
        cur = path.substr(0, next);
        if (!cur.empty() && !isDir(cur)) {
            if (::mkdir(cur.c_str(), 0755) != 0 && errno != EEXIST) {
                return false;
            }
        }
        if (next == std::string::npos) {
            break;
        }
        pos = next + 1;
    }
    return true;
}

// Sets the profile picture for `user` by copying `source` into the shared
// avatar store.
int setPfp(std::string source, const std::string& user) {
    if (source.empty()) {
        std::fprintf(stderr, "caelestia-greeter: --set-pfp requires a file path\n");
        return 1;
    }
    if (user.empty()) {
        std::fprintf(stderr, "caelestia-greeter: could not determine user name\n");
        return 1;
    }

    const std::string avatarDir = "/var/cache/caelestia-greeter/avatars";

    std::string home;
    if (const char* sudo = std::getenv("SUDO_USER"); sudo != nullptr && *sudo != '\0') {
        if (struct passwd* pw = ::getpwnam(sudo); pw != nullptr && pw->pw_dir != nullptr) {
            home = pw->pw_dir;
        }
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

// Lists connected output names from `wlr-randr` ("NAME \"desc\"" lines),
// with retries for compositor startup delay.
std::vector<std::string> listOutputs() {
    std::vector<std::string> names;
    for (int attempt = 0; attempt < 12; ++attempt) {
        FILE* pipe = ::popen("wlr-randr 2>/dev/null", "r");
        if (pipe != nullptr) {
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
        }
        if (!names.empty()) {
            return names;
        }
        ::usleep(200000); // 200ms sleep between attempts
    }
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

// Formats a mode string for wlr-randr (--custom-mode if it has a refresh rate).
std::string formatModeFlag(const std::string& mode) {
    if (mode == "preferred" || mode == "auto") {
        return "--preferred";
    }
    if (mode.find('@') != std::string::npos) {
        std::string m = mode;
        if (m.find("Hz") == std::string::npos && m.find("hz") == std::string::npos) {
            m += "Hz";
        }
        return "--custom-mode " + m;
    }
    return "--mode " + mode;
}

// Appends the monitor flags for one output.
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
        if (!mode.empty()) {
            group += " " + formatModeFlag(mode);
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

// Reads monitor configurations from a Hyprland config.
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
        "  --custom-mode WxH[@RATE] set custom mode with exact refresh rate\n"
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
        "                           run with sudo. ~ and $VAR are expanded.\n"
        "\n"
        "  --convert FILE | -c FILE  read monitor configurations from a Hyprland\n"
        "                           config (plain `monitor =` lines or Lua\n"
        "                           `hl.monitor({ ... })` blocks) and print the\n"
        "                           equivalent caelestia-greeter flags\n"
        "\n"
        "Any other arguments are passed through to quickshell.\n");
}

// Executes wlr-randr with fallback strategies for modes and individual outputs.
bool applyRandr(const std::vector<std::string>& randrArgs) {
    if (randrArgs.empty()) {
        return true;
    }

    std::vector<std::string> baseCmd;
    baseCmd.push_back("wlr-randr");
    baseCmd.insert(baseCmd.end(), randrArgs.begin(), randrArgs.end());

    std::string err;
    int res = -1;
    for (int attempt = 0; attempt < 15 && res != 0; ++attempt) {
        err.clear();
        res = runCommand(baseCmd, &err);
        if (res != 0) {
            ::usleep(150000);
        }
    }
    if (res == 0) {
        return true;
    }

    // Fallback 1: convert any `--mode <with-@>` to `--custom-mode <mode>Hz`
    std::vector<std::string> customCmd;
    customCmd.push_back("wlr-randr");
    for (size_t i = 0; i < randrArgs.size(); ++i) {
        if (randrArgs[i] == "--mode" && i + 1 < randrArgs.size() && randrArgs[i + 1].find('@') != std::string::npos) {
            customCmd.push_back("--custom-mode");
            std::string m = randrArgs[++i];
            if (m.find("Hz") == std::string::npos && m.find("hz") == std::string::npos) {
                m += "Hz";
            }
            customCmd.push_back(m);
        } else {
            customCmd.push_back(randrArgs[i]);
        }
    }
    err.clear();
    res = runCommand(customCmd, &err);
    if (res == 0) {
        return true;
    }

    // Fallback 2: convert any `--mode WxH@...` to `--mode WxH` (resolution only)
    std::vector<std::string> resOnlyCmd;
    resOnlyCmd.push_back("wlr-randr");
    for (size_t i = 0; i < randrArgs.size(); ++i) {
        if ((randrArgs[i] == "--mode" || randrArgs[i] == "--custom-mode") && i + 1 < randrArgs.size()) {
            std::string m = randrArgs[++i];
            const size_t at = m.find('@');
            if (at != std::string::npos) {
                m = m.substr(0, at);
            }
            resOnlyCmd.push_back("--mode");
            resOnlyCmd.push_back(m);
        } else {
            resOnlyCmd.push_back(randrArgs[i]);
        }
    }
    err.clear();
    res = runCommand(resOnlyCmd, &err);
    if (res == 0) {
        return true;
    }

    // Fallback 3: apply each output group individually
    std::vector<std::vector<std::string>> groups;
    std::vector<std::string> curGroup;
    for (size_t i = 0; i < randrArgs.size(); ++i) {
        if (randrArgs[i] == "--output" && !curGroup.empty()) {
            groups.push_back(curGroup);
            curGroup.clear();
        }
        curGroup.push_back(randrArgs[i]);
    }
    if (!curGroup.empty()) {
        groups.push_back(curGroup);
    }

    bool anySuccess = false;
    for (const auto& group : groups) {
        std::vector<std::string> subCmd;
        subCmd.push_back("wlr-randr");
        subCmd.insert(subCmd.end(), group.begin(), group.end());
        err.clear();
        if (runCommand(subCmd, &err) == 0) {
            anySuccess = true;
        } else {
            // Try subCmd with custom-mode
            std::vector<std::string> subCustom;
            subCustom.push_back("wlr-randr");
            for (size_t j = 0; j < group.size(); ++j) {
                if (group[j] == "--mode" && j + 1 < group.size() && group[j + 1].find('@') != std::string::npos) {
                    subCustom.push_back("--custom-mode");
                    std::string m = group[++j];
                    if (m.find("Hz") == std::string::npos && m.find("hz") == std::string::npos) {
                        m += "Hz";
                    }
                    subCustom.push_back(m);
                } else {
                    subCustom.push_back(group[j]);
                }
            }
            if (runCommand(subCustom, &err) == 0) {
                anySuccess = true;
            }
        }
    }

    if (!anySuccess && !err.empty()) {
        std::fprintf(stderr, "caelestia-greeter: warning: could not apply wlr-randr configuration: %s\n", trim(err).c_str());
    }
    return anySuccess;
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

    // Configure QML import path so Caelestia.Greeter plugin is loaded
    std::string qmlImport = "";
    if (const char* envQml = std::getenv("QML_IMPORT_PATH"); envQml != nullptr && *envQml != '\0') {
        qmlImport = envQml;
    }
    for (const std::string& p : {dir + "/qml", dir + "/../qml", dir + "/../build/qml", dir + "/build/qml", std::string("/usr/lib/qt6/qml"), std::string("/usr/lib64/qt6/qml")}) {
        if (isDir(p)) {
            if (!qmlImport.empty()) {
                qmlImport += ":";
            }
            qmlImport += p;
        }
    }
    if (!qmlImport.empty()) {
        ::setenv("QML_IMPORT_PATH", qmlImport.c_str(), 1);
        ::setenv("QML2_IMPORT_PATH", qmlImport.c_str(), 1);
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
            std::fprintf(stderr, "caelestia-greeter: warning: could not query connected outputs\n");
        } else {
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
    }

    // Apply the requested output configuration.
    if (haveRandR) {
        if (!commandAvailable("wlr-randr")) {
            die("wlr-randr is required but was not found in PATH");
        }
        applyRandr(randrArgs);
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
