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

enum Action {
    case startstop 
    case reset
    case quit 
    case none
}

nonisolated(unsafe) var setAction = Action.none

class Input: Thread {
    let onAction: @Sendable (Action) -> Void

    init(onAction: @escaping @Sendable (Action) -> Void) {
        self.onAction = onAction
        super.init()
    }

    override func main() {
        let onAction = self.onAction
        while true {
            var key = rawterm.wait_for_input();
            let action: Action

            switch (key.code) {
            case CChar("r"):
                action = .reset
            case CChar(" "):
                if key.getMod() == rawterm.Mod.Space {
                    action = .startstop
                } else {
                    continue
                }
            case CChar("q"):
                action = .quit
            default:
                continue
            }

            DispatchQueue.main.async {
                onAction(action)
            }
        }
    }
}

@main
struct timer {
   nonisolated(unsafe) static let timerSource = DispatchSource.makeTimerSource(queue: .main)
   nonisolated(unsafe) static var suspended = false

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

        let inputThread = Input { action in
            setAction = action
        }
        inputThread.start()

        timerSource.schedule(deadline: .now(), repeating: .seconds(1))

        startTimer(cur: cur, numCells: numCells)
        dispatchMain()

        rawterm.Cursor.cursor_show();
    }

    static func startTimer(cur: rawterm.Cursor, numCells: Array<rawterm.Pos>) {
        var cur = cur
        let start = Date()
        timerSource.setEventHandler {
            let elapsedSeconds = Date().timeIntervalSince(start)
            drawDigits(cur: &cur, time: elapsedSeconds, numCells: numCells);

            switch setAction {
                case Action.startstop:
                    (suspended ? timerSource.resume() : timerSource.suspend())
                case Action.reset:
                    timerSource.cancel()
                    startTimer(cur: cur, numCells: numCells)
                case Action.quit:
                    timerSource.cancel()
                case Action.none:
                    break
            }

            setAction = .none
        }

        timerSource.resume()
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

