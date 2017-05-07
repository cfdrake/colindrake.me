---
title: Wrapping a C Library in a Swift Framework
date: 2015-10-05
---

I recently started work on a project where I wanted to wrap up a C library for OS X with a more palatable Swift framework interface. My first thought was to follow what I saw in Apple's [Mix and Match documentation](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html), a guide to integrating C/Objective-C with Swift code.

The guide tells you to create a [Bridging Header](http://www.learnswiftonline.com/getting-started/adding-swift-bridging-header/), a file where you can denote the needed non-Swift dependencies for the compiler to then expose to your Swift code. However, when following this advice with a framework target, Xcode gives you this friendly error:

![](/images/c-library/error.png)

After much searching, poking, and prodding, I came across the [SwiftGo](https://github.com/Zewo/SwiftGo) project, which appeared to have the same setup as I needed. (Kudos to [@loganwright](http://loganwright.io/) from the [iOS Developers Slack](https://ios-developers.io/) for pointing this out!)

I ended up reading the source of SwiftGo and creating an example wrapper project for [progressbar](https://github.com/doches/progressbar), a simple C library to display a progress bar with [ncurses](https://en.wikipedia.org/wiki/Ncurses), as I went along. Check out the final project [here](https://github.com/cfdrake/swift-framework-c-library-example).

Now, let's take a look at how it's set up.

## Creating the Project
First, we'll start out by creating the project. Given that we want to target Mac OS X, we'll want to start out with a **Cocoa Framework** type:

![](/images/c-library/fw.png)

Name the project "Progressbar" and save it somewhere.

## The Wrapped Library
Next, we'll want to pull in the progressbar C library, our only dependency:

    $ cd Progressbar
    $ mkdir Dependencies
    $ git clone git@github.com:doches/progressbar.git

If you take a look at progressbar's code, you'll see it is actually comprised of only a few files:

    $ cd progressbar
    $ ls include/
    progressbar.h statusbar.h
    $ ls lib/
    progressbar.c statusbar.c

To include these in our wrapper library, open a Finder window and drag all of the above files into the existing Xcode project. I created a few Groups in the project to help organize things:

![](/images/c-library/deps.png)

## Module Mapping
We've now got our C library into our Swift project (and Xcode will even compile it all), but we have no way to _call_ it from Swift. To remedy this, we use a **Module Map**.

The [module.map](http://clang.llvm.org/docs/Modules.html#module-maps) file is a Clang-specific file that "describes how a collection of existing headers maps on to the (logical) structure of a module." Luckily for us, these files are simple to create and will allow Clang to do most of the work for us!

Inside of the main source directory (`Progressbar`), create a file called `module.map` with the following contents:

    module Libprogressbar [system] {
      header "Dependencies/progressbar/include/progressbar.h"
      export *
    }

Feel free to drag and drop it into Xcode for easy editing (but note this is not actually necessary).

Next, we need to inform Xcode of the whereabouts of this file. Open up the Project settings for Progressbar, select **Build Settings**, and look for the one titled **Import Paths** under **Swift Compiler - Search Paths**.

Change it the value of this setting to `$(SRCROOT)/Progressbar` and ensure that `non-recursive` is selected. Your `module.map` file should be in the folder displayed by Xcode.

![](/images/c-library/searchpaths.png)

Now we can now simply (in Swift parlance) `import Libprogressbar` and access all of the C functions, macros, etc. underneath it.

## The Wrapper
For this example project, I only ended up writing a minimal wrapper around the original C library for demonstrative purposes. In any case, wrapping a C library like this allows callers to only have to deal with native Swift types, keeping their application layer nice and clean.

The code for our `Progressbar` wrapper is below (any calls to the `Libprogressbar` module are interfacing directly with the C library we included):

```swift
import Foundation
import Libprogressbar

/// Class outputting an animated terminal progress bar.
public final class Progressbar {
    let bar: UnsafeMutablePointer<progressbar>

    public init(text: String, max: UInt) {
        let cstring = (text as NSString).UTF8String
        bar = Libprogressbar.progressbar_new(cstring, max)
    }

    public func increment() {
        Libprogressbar.progressbar_inc(bar)
    }

    public func finish() {
        Libprogressbar.progressbar_finish(bar)
    }
}
```

## Example Usage
With our wrapper defined, we can finally write some simple application code to test our framework:

```swift
import Cocoa
import Progressbar

let max: UInt = 30
let bar = Progressbar(text: "foo", max: max)

for i in 1...max {
    bar.increment()
    sleep(1)
}

bar.finish()

// Example Output:
// foo |==================================   | ETA: 0h00m02s
```

If you're following along with the [Xcode project](https://github.com/cfdrake/swift-framework-c-library-example), check out the Playground file under the `Example` group. If you have the Console Window open (**⌘-Shift-Y**), you should see a progress bar animating over the course of 30 seconds.
