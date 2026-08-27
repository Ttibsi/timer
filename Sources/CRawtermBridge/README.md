# Cxx <> Swift interop

This directory acts as a bridge. The bridge.h file contains overloads for/new 
methods that are needed from the c++ side to be able to use rawterm from swift.
I've encapsulated these so it's easier to see from the swift code. 

NOTES:
----
* std::spans aren't easy to work with, and span overloads are coming in Swift 6.4
according to: https://github.com/swiftlang/swift/pull/88928
* swift can't instanciate templates on functions or methods, including constructors,
which will make working with the c++ stdlib difficult

