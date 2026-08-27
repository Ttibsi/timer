import CRawterm;
import CRawtermBridge;

/*
1 - Get the terminal dimensions
    1a - if the dimensions are too small, we exit out (what dimensions are needed?)
2 - Draw 00:00 to the screen with a message below
    2a - The message is read live from a text file
3 - Wait for user input - when `SPC` is pressed, start the timer
4 - Build live-reloading in to re-read from the text file (automatically? Or on keypress?)
5 - Restart the timer when `r` is presssed
6 - Pause when `SPC` is pressed
*/

@main
struct timer {
    static func main() {
        var dims = rawterm.get_term_size();
        if dims.horizontal < 35 || dims.vertical < 11 {
            print("ERROR: Terminal dimensions too small")
            return;
        }

        dims.vertical -= 1;

        rawterm.enable_raw_mode()
        rawterm.enter_alt_screen();

        rawterm.Cursor.cursor_hide();
        var cur = rawterm.Cursor();
        cur.reset();

        // Draw border once
        let region = rawterm.Region(rawterm.Pos(1, 1), dims);
        var border = rawterm.Border(region);
        let inside_border = Int(dims.vertical);
        let contents = Array(repeating: std.string(""), count: inside_border);
        rawterm_bridge.drawBorder(&border, &cur, contents, inside_border);

        sleep(5);

        // var time = [ZERO, ZERO, ZERO, ZERO]
        //
        // while true {
        //     let display = draw_time(digits: time)
        //     print_display(display: display, cursor: cur)
        // }

        rawterm.Cursor.cursor_show();
    }
}
