# TreeSourceView
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Travis](https://img.shields.io/travis/natestedman/TreeSourceView.svg)](https://travis-ci.org/natestedman/TreeSourceView)
[![License](https://img.shields.io/badge/license-Creative%20Commons%20Zero%20v1.0%20Universal-blue.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

Swift µframework providing a "tree source view":

## Usage
Initialize a `TreeSourceView`, and provide a `TreeSourceViewDataSource` and optionally, a `TreeSourceViewDelegate`. These protocols are simple and reminiscent of the equivalents for `UITableView` and `UICollectionView`, so they should be easy to figure out.

`TreeSourceView` uses variable-length `NSIndexPath` values. If you're only familiar with `NSIndexPath` in the fixed-length context of `UITableView` or `UICollectionView`, read the [Apple documentation](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSIndexPath_Class/).

## Documentation
If necessary, install `jazzy`:

    gem install jazzy
   
Then run:

    make docs

To generate HTML documentation in the `Documentation` subdirectory.

## Installation
Add:

    github "natestedman/TreeSourceView"

To your `Cartfile`. Manual installation via submodules will also work. There are no dependencies, besides `UIKit`.
