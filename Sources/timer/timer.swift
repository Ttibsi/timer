import CRawterm;

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
        let dims = rawterm.get_term_size();
        print("Hello, world!")
        print("dims = \(dims)")
    }
}
