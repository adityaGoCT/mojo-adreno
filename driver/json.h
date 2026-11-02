// A minimal JSON reader, for the launch descriptions in Mojo's SPIR-V modules
// (OpModuleProcessed "mojo.vulkan.abi {json}").
#ifndef DRIVER_JSON_H
#define DRIVER_JSON_H

#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <string>
#include <utility>
#include <vector>

struct Json {
  enum Kind { Null, Bool, Number, String, Array, Object } kind = Null;
  double number = 0;
  std::string text;
  std::vector<Json> items;
  std::vector<std::pair<std::string, Json>> fields;

  const Json *get(const char *key) const {
    for (auto &field : fields)
      if (field.first == key)
        return &field.second;
    return nullptr;
  }
  int64_t integer(const char *key, int64_t fallback = -1) const {
    const Json *value = get(key);
    return value && value->kind == Number ? static_cast<int64_t>(value->number) : fallback;
  }
};

struct JsonParser {
  const char *p, *end;
  void space() {
    while (p < end && isspace(static_cast<unsigned char>(*p)))
      ++p;
  }
  bool parse(Json &out) {
    space();
    if (p >= end)
      return false;
    if (*p == '{') {
      out.kind = Json::Object;
      ++p;
      space();
      if (p < end && *p == '}')
        return ++p, true;
      for (;;) {
        Json key, value;
        if (!parse(key) || key.kind != Json::String)
          return false;
        space();
        if (p >= end || *p++ != ':' || !parse(value))
          return false;
        out.fields.emplace_back(key.text, std::move(value));
        space();
        if (p < end && *p == ',') { ++p; continue; }
        return p < end && *p++ == '}';
      }
    }
    if (*p == '[') {
      out.kind = Json::Array;
      ++p;
      space();
      if (p < end && *p == ']')
        return ++p, true;
      for (;;) {
        Json value;
        if (!parse(value))
          return false;
        out.items.push_back(std::move(value));
        space();
        if (p < end && *p == ',') { ++p; continue; }
        return p < end && *p++ == ']';
      }
    }
    if (*p == '"') {
      out.kind = Json::String;
      for (++p; p < end && *p != '"'; ++p) {
        if (*p == '\\' && p + 1 < end)
          ++p;  // the descriptions only escape quotes and backslashes
        out.text += *p;
      }
      return p < end && *p++ == '"';
    }
    if (!strncmp(p, "null", 4)) { p += 4; return true; }
    if (!strncmp(p, "true", 4)) { out.kind = Json::Bool; out.number = 1; p += 4; return true; }
    if (!strncmp(p, "false", 5)) { out.kind = Json::Bool; p += 5; return true; }
    char *next;
    out.kind = Json::Number;
    out.number = strtod(p, &next);
    if (next == p)
      return false;
    p = next;
    return true;
  }
};

// The launch description in a SPIR-V module, or false.
inline bool launchDescription(const uint32_t *words, size_t count, Json &out) {
  static const char prefix[] = "mojo.vulkan.abi ";
  for (size_t at = 5; at < count;) {
    uint32_t n = words[at] >> 16, opcode = words[at] & 0xffff;
    if (!n || at + n > count)
      break;
    if (opcode == 330) {  // OpModuleProcessed
      const char *text = reinterpret_cast<const char *>(&words[at + 1]);
      size_t length = strnlen(text, (n - 1) * 4);
      if (length > sizeof prefix - 1 && !strncmp(text, prefix, sizeof prefix - 1)) {
        JsonParser parser{text + sizeof prefix - 1, text + length};
        return parser.parse(out) && out.kind == Json::Object;
      }
    }
    at += n;
  }
  return false;
}

#endif  // DRIVER_JSON_H
