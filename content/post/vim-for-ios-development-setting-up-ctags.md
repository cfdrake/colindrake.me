---
title: "Vim for iOS Development: Setting up ctags"
date: 2015-06-25
---

With projects like [cocoa.vim](https://github.com/msanders/cocoa.vim) and [vim-ios](https://github.com/eraserhd/vim-ios), iOS developers have a variety of helpful tools when deciding to build an app in Vim. However, with implementation files, header files, and the numerous set of frameworks we use to build apps, I've always found auto-completion and code navigation to be particularly difficult when writing Objective-C, especially when dealing with larger projects.

To remedy this, I've started using a very old tool, called [ctags](https://en.wikipedia.org/wiki/Ctags). ctags is able to parse source code and index methods, functions, classes, etc. for quick access later. Modern versions of Vim are built with ctags support by default, so this makes for a very easy integration.

Let's get started.

## Setup
Luckily for us, Mac OS X comes with ctags installed by default ...but unfortunately for us, this version (despite what the documentation says) doesn't support Objective-C. We'll have to use [Homebrew](http://brew.sh) to install a newer version. Start by executing the following to install the latest and greatest version of ctags:

```
$ brew install ctags --HEAD
```

Next, let's define a few default flags to always use when running ctags. These can be specified in a `.ctags` file in your home directory:

```
$ cat ~/.ctags
--recurse=yes
--tag-relative=yes
--exclude=.git
```

Finally, we'll set up a bash alias to make our lives easier when running ctags. Unfortunately, ctags assumes all `.m` files are Matlab files, not Objective-C implementation files, so we'll create a new command we can use that will ensure `.m` files are treated in the way that we need. Go ahead and add the following line of code to the `.bash_profile` file in your home directory:

```
alias ctags-objc="ctags --languages=objectivec --langmap=objectivec:.h.m"
```

At this point, we're ready to start processing our code.

## Indexing Your Project
If you've been following along word-for-word so far, you can simply run the following command from your project's root directory to create a local tag index:

```
$ ctags-objc
```

This will create a file called `tags` that Vim is smart enough to read. Now, if you open Vim in this directory, you should be able to start jumping through your project's source code already. Try the following command from within Vim:

```
:tag <ClassFromYourProject>
```

You should be taken directly to the `@interface` declaration for your class.

This is a great start, but oftentimes as iOS developers we find that we need to take a deeper look and check out the headers or documentation for an Apple Framework instead of our own code.

## Indexing System Headers
Let's begin by generating tags for some of the more commonly-used Apple Frameworks. We'll start by opening up the folder containing  all of the iOS and Mac OS X frameworks and peering inside:

```
$ cd /System/Library/Frameworks
$ ls
AGL.framework
AVFoundation.framework
AVKit.framework
Accelerate.framework
Accounts.framework
AddressBook.framework
AppKit.framework
AppKitScripting.framework
AppleScriptKit.framework
AppleScriptObjC.framework
ApplicationServices.framework
AudioToolbox.framework
...
```

Here, every Framework that we can include and link to has a corresponding `*.framework` folder with parseable header files inside. We can use these files to generate a global tag list for all of the Frameworks we use on a daily basis. I'd start with just a few Frameworks - a tag file containing all of them gets pretty slow to search, at least on my system.

By using the `--append` and `-f` flags in ctags, we can output and append tags to a file of our choice. I like to keep the [MapKit](https://developer.apple.com/library/ios/documentation/MapKit/Reference/MapKit_Framework_Reference/), [CoreLocation](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CoreLocation_Framework/), and [Foundation](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/ObjC_classic/index.html#//apple_ref/doc/uid/20001091) frameworks in my database. Anytime you want to add a Framework to your tags database, a command like the following will work:

```
$ cd CoreData.framework/
$ ctags-objc --append -f ~/Documents/global-objc-tags
```

Do this for a couple of your most often-used Frameworks to get a good base.

Next, we'll add tags for [UIKit](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKit_Framework/). The UIKit frameworks are stored on a per-iOS SDK basis deep inside of the `Xcode.app` folder, so we'll need to start by navigating there (make sure to substitute the `8.3` in the next command for the iOS version you want):

```
cd /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.3.sdk/System/Library/Frameworks/UIKit.framework/Headers
```

Now, we can just run the same command as above to append to our global tag list:

```
$ ctags-objc --append -f ~/Documents/global-objc-tags
```

At this point we've got two tag databases ready &mdash; one for our project, and one for the Frameworks we intend to use. Let's jump back over to Vim.

## Vim Configurations
As we saw above, Vim was smart enough to find and automatically take a look at the local `tags` file to process our codebase. However, we need to tell Vim about the global Objective-C tags we just generated. Using an [autocmd](http://vimdoc.sourceforge.net/htmldoc/autocmd.html) will be a great solution to make this database searchable only when we're in an Objective-C file.

Open your `.vimrc` file and add the following:

```
if has("autocmd")
  autocmd BufNewFile,BufRead *.h,*.m set tags+=~/Documents/global-objc-tags
endif
```

Now, we'll be able to automatically search our local and global tag databases for any project that we open.

## Basic Usage
Now that we've built our full tag archive, we can start querying and jumping around our (and Apple's) codebases. The following commands and key combinations will form a good start for poking around.

```
:tag <Class, Method, Protocol, Type...>
```

This command will let you go to the definition of the given tag (try it with an Apple Framework class this time &mdash; `UITableViewDataSource` always has details to the method signatures that I forget). Once you're done, you may use `<c-t>` or `:bd` to leave.

```
:tselect <...>
```

This form is the same as the above `tag` except that if more than one match is found, a menu is presented where you may choose which definition you want to jump to. Additionally, this is a good command to use the `/` search modifier with. For example, to find tags beginning with `NSAss` the `:tselect /NSAss` command may be issued.

```
:tags
```

This command provides a menu of previously-found tags from your current session. Simply type the number of the tag you want to view and press Enter to jump to it again.

```
<c-]>
```

This normal mode command will perform a `:tag` command for the currently selected word. Try putting your cursor within a class name and executing this.

```
<c-x> <c-p>
```

In insert mode, this will provide an autocompletion menu based on tag file contents. The arrow keys navigate the list, `<c-y>` accepts and inserts, and `<c-e>` cancels the prompt.

```
:CtrlPTag
```

Finally, if you're a [ctrlp.vim](https://github.com/kien/ctrlp.vim) user (which you should be!), you can use this command to search tags in realtime. I use this often enough that I've bound it to `<leader>t`.

## Conclusion

You should now have a basic working knowledge of how to generate and view tags for Objective-C projects in Vim. However, there are many, many more commands available to aid in navigating your source with ctags. Give the `:help tags` page a read for more information.

Additionally, it's worth noting that there are a wide variety of user-contributed plugins that can aid your usage of ctags. Check out [TagBar](https://github.com/majutsushi/tagbar) and [EasyTags](https://github.com/xolox/vim-easytags) for viewing and maintaining your tags, respectively.

Shameless plug: If you're a Vim user and iOS developer, you also may enjoy my [vim-carthage](https://github.com/cfdrake/vim-carthage) plugin. Give it a shot!
