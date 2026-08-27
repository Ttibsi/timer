#ifndef BRIDGE_H
#define BRIDGE_H

#include <span>
#include <string>
#include <vector>

#include "rawterm/cursor.h"
#include "rawterm/extras/border.h"

using lines_t = std::vector<std::string>;
namespace rawterm_bridge {
    using namespace rawterm;

    inline void drawBorder(Border& b, Cursor& cur, const std::string* data, std::size_t count) {
        std::vector<std::string> v(data, data + count);
        b.draw(cur, v);
    }
}

#endif // BRIDGE_H
