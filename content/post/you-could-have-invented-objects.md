---
title: You Could Have Invented Objects
date: 2016-03-21
---

I&rsquo;ve always been interested in programming languages and paradigms.


Usually, this manifests itself in reading about functional programming, the Lisp
family of languages, compilers, and lately,
[protocol-oriented programming](https://en.wikipedia.org/wiki/Protocol_(object-oriented_programming))
with Swift and Clojure.

However, I recently found myself circling back to a paradigm that most of us take
for granted: object-oriented programming. After reading many articles on the
[c2.com](http://c2.com/cgi/wiki) wiki, I ended up playing around with a
[Pharo](http://pharo.org/) Smalltalk installation on my Mac. While I can&rsquo;t
say that I plan on using Smalltalk for my next project, my curiosity was piqued.

The sheer level of [interaction and introspection](https://www.youtube.com/watch?v=HOuZyOKa91o)
supported by the Pharo object
system/environment was amazing. So naturally, I wondered if I could build a small
home-grown object system myself&hellip; The following is a short exploration in creating a (primitive) object system in Swift.

## Overview

Let's take a step back to CS 101: what are some of the basic, core facets of object oriented programming? [Wikipedia](https://en.wikipedia.org/wiki/Object-oriented_programming)
lists a few:

* Message Passing
* Encapsulation
* Composition/Inheritance/Delegation
* Open Recusion

Now, pretend for a while that `class`, `struct`, `enum`, and friends don&rsquo;t
exist in Swift. What type of (more fundamental) structure is capable of expressing
the above features? How about functions, or closures?

* Message Passing: perform "procedures" dispatching based off of a passed-in message name parameter
* Encapsulation: closures already capture lexical scope
* Composition: isn't this what the functional paradigm is about? 😃
* Inheritance/Delegation: simply call another closure!
* Open Recusion: well&hellip; we'll get there&hellip;

With the above in mind, let's jump in.

## Message Passing

For our purposes, we'll define a `Message` as a `String` and an object as some
type that interprets a `Message` to (possibly) return some value.

```swift
typealias Message = String
typealias Object = (Message) -> Any?
```

Unfortunately, as you can see, we&rsquo;ll be&hellip; sidestepping the type
system for this hacky experiment 😉

Let&rsquo;s start by defining our first "object" that can respond to messages.
Our convention will be as such: messages that are not known by the objects will
return `nil`, and all others will return some value.

```swift
let obj1: Object = { (msg: Message) in
    switch msg {
    case "do-something": return "sure!"
    default: return nil
    }
}
```

Great! Now we have an arbitrary object that can dispatch to code based off of messages.

```swift
obj1("do-something")   // => "sure!"
obj1("do-other-thing") // => nil
```

This buys us the simplest benefit of OOP: the ability to abstract out procedures
packaged with data based off of some known interface.

## Encapsulation

The above code snippets are fine and dandy, but we don't really want to be
defining our own objects ad-hoc all the time: we all know the benefits of using
classes as reusable blueprints for creating objects. Luckily for us, this can
be represented as&hellip; you guess it &ndash; another closure!

For us, a "class" is really just comprised of a constructor function that returns
a new object/instance (another closure, as demonstrated above).

Additionally, closures can capture the lexical environment, so any parameters
passed into our constructor function can act as a sort of read-only instance
variable for our internal object. In a nutshell, we get encapsulation for free.

```swift
// Constructors are uppercase by convention...
let Person = { (firstName fn: String, lastName ln: String) -> Object in
    return { (msg: Message) -> Any? in
        switch msg {
        case "full-name": return "\(fn) \(ln)"
        case "description": return "<Person>"
        default: return nil
        }
    }
}
```

&hellip;and to use it&hellip;

```swift
// Define a person and test out methods...
let p = Person(firstName: "Colin", lastName: "Drake")

p("full-name")   // => "Colin Drake"
p("description") // => "<Person>"
p("address")     // => nil
```

Immutability is nice, but we can also package up mutable state pretty easily.
All it really takes is copying the constructor parameters to a mutable local variable.
Take, for instance, this `Counter` example:

```swift
let Counter = { (initial: Int) -> Object in
    var counter = initial
    return { (msg: Message) in
        switch msg {
        case "count": return counter
        case "increment":
            counter += 1
            return counter
        case "decrement":
            counter -= 1
            return counter
        default: return nil
        }
    }
}
```

## Composition, Inheritance, and Delegation

One of the biggest attractions to OOP is the ability for code reuse. Both object
composition and inheritance allow for this, but in two different ways. Composition
allows us to delegate messages out to another object, and inheritance allows us
to do the same, but specifically to some object we deem a "parent" to the current one.

We'll implement inheritance as a simple delegated call to our known parent, if
the object itself doesn't know how to interpret the message. Most languages and
object systems have this as a built-in to the syntax/model, but we'll keep things
simple and explicit.

```swift
/// Represents possible speeds at which atheletes can run.
enum RunSpeed: String {
    case Slow
    case Fast
}

/// Represents an Athelete, a subclass of Person.
let Athelete = { (firstName fn: String,
                  lastName ln: String,
                  runningSpeed rs: RunSpeed) -> Object in
    // Create a person "super" object to delegate to.
    let superInstance = Person(firstName: fn, lastName: ln)

    return { (msg: Message) -> Any? in
        switch msg {
        // Simple instance method.
        case "how-fast?": return rs
        // Override behavior of a Person.
        case "description": return "<A \(rs.rawValue)-Moving Athelete>"
        // Delegate unknown messages to superclass.
        default: return superInstance(msg)
        }
    }
}
```

And example usage:

```swift
let a = Athelete(firstName: "Colin",
                 lastName: "Drake",
                 runningSpeed: .Slow)

a("how-fast?")   // => RunSpeed.Slow
a("description") // => "<A Slow-Moving Athelete>"
a("full-name")   // => "Colin Drake" (a Person method)
```

## Open Recursion

Within the context of OOP, open recursions refers to the ability to dispatch
methods on yourself. As an object, you want the ability to call one of your own
methods, but you don't want the responsibility of needing to know the
whereabouts of the raw implementation yourself.

This self-referential dispatch is pretty trivial (and IMHO more elegant) in a Lisp-like
language, but we're in the Swift world: a closure recursively calling itself will
raise a compiler error indicating that a value is attempting to use itself in its
own definition.

To get around this, we'll use the [Y-combinator](http://stackoverflow.com/a/94056),
a function that "enables recursion, when you can't refer to the function from
within itself." It's a bit tricky to define, but easy to use.

```swift
// h/t: http://bit.ly/1U2N0HP
func Y<T, R>( f: (T -> R) -> (T -> R) ) -> (T -> R) {
    return { t in f(Y(f))(t) }
}
```

With that mess out of the way, let's try to use it in the OOP context
to recursively call our dispatch function:

```swift
let Cat = { (name n: String, age a: Int) -> Object in
    return Y {
        dispatch in { (msg: Message) -> Any? in
            switch msg {
            case "name": return "\(n) the Cat"
            case "description":
                // Dispatch on ourself.
                let me = dispatch("name")!
                return "<A Feline named \(me)>"
            default: return nil
            }
        }
    }
}

let leo = Cat(name: "Leo", age: 2)

leo("name") // => "Leo the Cat"
leo("description") // => "<A Feline named Leo the Cat>"
```

The value of this is that we don't care if we implemented the method we're
calling, or if it is delegated to a super instance. All of that is abstracted
from us via the call to `dispatch`.

And with that, our simple homegrown object system is complete! However,
I've got one more trick up my sleeve&hellip;

## Goodies

Using metaprogramming to aid in code readability is one of my favorite features of
Ruby. An expressive, powerful example of this is the ability to call a
`find_by_<column>` method on ActiveRecord models in Rails without needing to
define said method. Rails achieves this via the `method_missing` feature in Ruby's
object system.

In Ruby, if a message is
sent to an object, and that object doesn't have an implementation for it, the
`method_missing` method is called instead with the original method name as a parameter. By
default, this raises an exception, but developers have the ability to override
and provide custom behavior. This is where Rails builds and caches customized
database query functions.

It turns out, we can emulate this dynamic nature
pretty easily within our system:

```swift
let SQLBuilder = { (table: String) -> Object in
    return { (msg: Message) in
        let field = msg.stringByReplacingOccurrencesOfString(
            "sort-by-",
            withString: "")

        if field != msg {
            return "SELECT * FROM \(table) ORDER BY \(field)"
        }

        return nil
    }
}

let s = SQLBuilder("user")

s("sort-by-age")  // => "SELECT * FROM user ORDER BY age"
s("sort-by-name") // => "SELECT * FROM user ORDER BY name"
s("group-by-something") // => nil
```

We're missing the robustness of a dynamic `Object` superclass to route things,
but hey, we've got the same results 😉

## Conclusion

In the end, our object system is neither featureful nor expressive.

But to me, the most important takeaway is that given certain fundamental functional
language features, any developer could have come up with and implemented OOP.
At its core, the concepts and _patterns_ of OOP are very simple &ndash; and it's just that.

OOP can be thought of as a set of (helpful!) _patterns_ that can be implemented
on top of a more fundamental, functional paradigm.
We can truly [say](http://people.csail.mit.edu/gregs/ll1-discuss-archive-html/msg03277.html)
that "objects are a poor man's closures".

The code in this article is available as a [gist](https://gist.github.com/cfdrake/2a20fe432547d92b50a8).
