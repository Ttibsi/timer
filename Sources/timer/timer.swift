import Foundation;
import CoreFoundation;
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

enum Command {
    case toggle 
    case reset
    case quit 
}

@MainActor
@main
struct timer {
    static let timerSource = DispatchSource.makeTimerSource(queue: .main)

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

        let topLine: Int32 = 4;
        let numCells = [
            rawterm.Pos(topLine, dims.horizontal / 2 - 12),
            rawterm.Pos(topLine, dims.horizontal / 2 - 6),
            rawterm.Pos(topLine, dims.horizontal / 2 + 2),
            rawterm.Pos(topLine, dims.horizontal / 2 + 8)
        ]

        timerSource.schedule(deadline: .now(), repeating: .seconds(1))

        startTimer(cur: cur, numCells: numCells)
        dispatchMain()

        rawterm.Cursor.cursor_show();
    }

    nonisolated static func wait_for_input() -> Command {
        while (true) {
            var k: rawterm.Key? = Optional(fromCxx: rawterm.process_keypress())
            if k != nil {
                switch k!.code {
                    case CChar("r"):
                        return Command.reset
                    case CChar("q"):
                            return Command.quit
                    case CChar(" "):
                        if (k!.getMod() == rawterm.Mod.Space) {
                            return Command.toggle
                        }
                    default:
                        continue
                }
            }
        }
    }

    static func startTimer(cur: rawterm.Cursor, numCells: Array<rawterm.Pos>) {
        let inputQueue = DispatchQueue(label: "userInput", qos: .userInitiated)
        nonisolated var suspended = false
            var cur = cur
            let start = Date()
            timerSource.setEventHandler {
                let elapsedSeconds = Date().timeIntervalSince(start)
                    drawDigits(cur: &cur, time: elapsedSeconds, numCells: numCells);

                inputQueue.async {
                    let result = wait_for_input()
                        DispatchQueue.main.async {
                            switch result {
                                case Command.toggle:
                                    (suspended ? timerSource.resume() : timerSource.suspend())
                                        suspended = !suspended
                                case Command.reset:
                                        timerSource.cancel()
                                            startTimer(cur: cur, numCells: numCells)
                                case Command.quit:
                                            timerSource.cancel()
                            }
                        }
                }

                timerSource.resume()
            }
    }


    static func drawDigits(cur: inout rawterm.Cursor, time: Double, numCells: Array<rawterm.Pos>) {
        let mins = Int(time / 60)
            let secs = Int(time.truncatingRemainder(dividingBy: 60))
            assert(mins < 60) // TODO: handle hours as well

            let displayNums = [
            (mins < 10 ? 0 : Int(mins/10)),
            mins % 10,
            (secs < 10 ? 0 : Int(secs/10)),
            secs % 10
            ]

            let backFiveDownOne = "\u{1B}[6D\u{1B}[B"
            for (cell, display) in zip(numCells, displayNums) {
                cur.move(cell)
                    print(digits[display].replacing("\n", with: backFiveDownOne))
            }
    }
}

