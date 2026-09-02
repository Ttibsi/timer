import Foundation;
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

@MainActor
@main
struct timer {
    static var cur = rawterm.Cursor()
    static let timerSource = DispatchSource.makeTimerSource(queue: .main)
    static let inputSource = DispatchSource.makeTimerSource(queue: .main)
    static var timerStarted = false
    static var suspended = false
    static var caption = ""

    static var wiggleMode = false
    static var wiggleOffset: Int32 = -1
    static var wiggleCount = 1
    static var lastWiggleCount = 1

    static func main() {
        var dims = rawterm.get_term_size();
        if dims.horizontal < 35 || dims.vertical < 11 {
            print("ERROR: Terminal dimensions too small")
            return;
        }

        let argv = CommandLine.arguments
        if argv.contains("--wiggle") {
            wiggleMode = true
        }

        dims.vertical -= 1

        rawterm.enable_raw_mode()
        rawterm.enter_alt_screen()

        rawterm.Cursor.cursor_hide()
        cur.reset()

        // Draw border once
        let region = rawterm.Region(rawterm.Pos(1, 1), dims)
        var border = rawterm.Border(region)
        let inside_border = Int(dims.vertical)
        let contents = Array(repeating: std.string(""), count: inside_border)
        rawterm_bridge.drawBorder(&border, &cur, contents, inside_border)

        let topLine: Int32 = 4;
        let numCells = [
            rawterm.Pos(topLine, dims.horizontal / 2 - 13),
            rawterm.Pos(topLine, dims.horizontal / 2 - 7),
            rawterm.Pos(topLine, dims.horizontal / 2),
            rawterm.Pos(topLine, dims.horizontal / 2 + 3),
            rawterm.Pos(topLine, dims.horizontal / 2 + 9)
        ]

        timerSource.schedule(deadline: .now(), repeating: .seconds(1))
        inputSource.schedule(deadline: .now(), repeating: .milliseconds(20))
        inputSource.setEventHandler {
            dispatchPrecondition(condition: .onQueue(.main))
            pollInput(numCells: numCells, horizontal: dims.horizontal)
        }
        inputSource.resume()

        startTimer(numCells: numCells, horizontal: dims.horizontal)
        dispatchMain()
    }

    static func startTimer(numCells: Array<rawterm.Pos>, horizontal: Int32) {
        let start = Date()
        timerSource.setEventHandler {
            dispatchPrecondition(condition: .onQueue(.main))
            let elapsedSeconds = Date().timeIntervalSince(start)
            drawDigits(time: elapsedSeconds, numCells: numCells, horizontal: horizontal);
        }

        if !timerStarted {
            timerSource.resume()
            timerStarted = true
        }
    }

    static func pollInput(numCells: Array<rawterm.Pos>, horizontal: Int32) {
        guard var k: rawterm.Key = Optional(fromCxx: rawterm.process_keypress()) else { return }
        let keyCode = UInt8(bitPattern: k.code)
        switch keyCode {
            case Character("r").asciiValue!:
                if suspended {
                    timerSource.resume()
                    suspended = false
                }

                startTimer(numCells: numCells, horizontal: horizontal)

            case Character("q").asciiValue!:
                timerSource.cancel()
                inputSource.cancel()

                rawterm.Cursor.cursor_show()
                rawterm.exit_alt_screen()
                rawterm.disable_raw_mode()
                exit(0)

            case Character("c").asciiValue!:
                drawCaption(horizontal: horizontal)

            case Character(" ").asciiValue!:
                if k.getMod() == rawterm.Mod.Space {
                    (suspended ? timerSource.resume() : timerSource.suspend())
                    suspended = !suspended
                }
            default: break
        }
    }

    static func drawDigits(time: Double, numCells: Array<rawterm.Pos>, horizontal: Int32) {
        let mins = Int(time / 60)
        let secs = Int(time.truncatingRemainder(dividingBy: 60))
        assert(mins < 60) // TODO: handle hours as well

        let displayNums = [
            (mins < 10 ? 0 : Int(mins/10)),
            mins % 10,
            10,
            (secs < 10 ? 0 : Int(secs/10)),
            secs % 10
        ]

        let backFiveDownOne = "\u{1B}[6D\u{1B}[B"
        if wiggleMode { wiggleCount += 1 }
        let frameWiggleCount = wiggleCount
        let previousOffset: Int32 = (frameWiggleCount == 1 ? -wiggleOffset : wiggleOffset)
        for (idx, (cell, display)) in zip(numCells, displayNums).enumerated() {

            if (wiggleMode) {
                let wasWiggled = idx < lastWiggleCount
                let isWiggled = idx < frameWiggleCount
                let oldVertical = (wasWiggled ? (cell.vertical + previousOffset) : cell.vertical)
                let newVertical = (isWiggled ? (cell.vertical + wiggleOffset) : cell.vertical)

                if oldVertical != newVertical {
                    let clearLines = digits[display].split(whereSeparator: \.isNewline)
                    for (lineOffset, line) in clearLines.enumerated() {
                        cur.move(oldVertical + Int32(lineOffset), cell.horizontal)
                        print(String(repeating: " ", count: line.count), terminator: "")
                    }
                }

                if isWiggled {
                    cur.move(newVertical, cell.horizontal)
                } else {
                    cur.move(cell)
                }
            } else {
                cur.move(cell)
            }

            let digit = digits[display]
            let digit_lines = digit.split(whereSeparator: \.isNewline)
            let replacement = backFiveDownOne.replacing("6", with: String(digit_lines[0].count))
            print(digit.replacing("\n", with: replacement))
        }

        if wiggleMode {
            lastWiggleCount = frameWiggleCount
        }

        if wiggleMode && wiggleCount == 5 { 
            wiggleCount = 0 
            wiggleOffset = (wiggleOffset == -1 ? 1 : -1)
        }

        drawCaption(horizontal: horizontal)
    }

    static func readCaption() -> String {
        let filePath = FileManager.default.currentDirectoryPath + "/caption.txt"
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            return content.trimmingCharacters(in: .whitespaces)
        } catch {
            return ""
        }
    }

    static func drawCaption(horizontal: Int32) {
        let captionLine: Int32 = 10

        let newCaption = readCaption()
        // We don't need to redraw if nothing has changed
        if newCaption != caption {
            caption = newCaption
        }

        // Clear previous line
        cur.move(captionLine, 2)
        print(String(repeating: " ", count: Int(horizontal - 4)))

        if caption.length > 0 {
            let half = Int32(caption.count / 2)
            cur.move(rawterm.Pos(captionLine, (horizontal / 2) - half))
            print(caption)
        }
    }
}
