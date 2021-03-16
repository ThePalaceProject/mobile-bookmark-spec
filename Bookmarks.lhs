Simplified-Bookmarks-Spec
===

## Overview

The contents of this repository define a specification describing the format
of bookmark data shared between clients and server in the Library Simplified
ecosystem. The intention is to declare a common format for bookmarks that 
clients on different platforms (Web, iOS, Android) can use to synchronize
reading positions. The specification is described as executable Literate
Haskell and can be executed and inspected directly using ghci.

```
$ ghci -W -Wall -Werror -pgmL markdown-unlit Bookmarks.lhs
```

## Typographic Conventions

Within this document, commands given at the GHCI prompt are prefixed
with `*Bookmarks>` to indicate that the commands are being executed within
the `Bookmarks` module.

The main specification definitions are given in the [Bookmarks](Bookmarks.lhs) module:

```haskell
{-# LANGUAGE Haskell2010, ExplicitForAll #-}
module Bookmarks where

import qualified Data.Map as DM
```

## Terminology

* User: A human (typically a library patron) using one or more of the 
  Library Simplified applications.

* Client: An application running on a user's device. This can refer to
  native applications such as [SimplyE](https://github.com/NYPL-Simplified/Simplified-iOS),
  or the [web-based interface](https://github.com/NYPL-Simplified/circulation-patron-web).

* Bookmark: A stored position within a publication that can be used to
  navigate to that position at a later date.

## Web Annotations

The base format for bookmark data is the W3C [Web Annotations](https://www.w3.org/annotation/)
format. The bookmark data described in this specification is expressed in terms
of an _annotation_ with a set of strictly-defined required and optional fields.

## Locators

A _Locator_ uniquely identifies a position within a book. A _Locator_
consists of a [URI](https://tools.ietf.org/html/rfc3986) that uniquely
identifies a chapter within a publication, and a _progression_ value. A
_progression_ value is a real number in the range `[0, 1]` where `0` is
the beginning of a chapter, and `1` is the end of the chapter.

```haskell
type URI = String

data Progression
  = Progression Double
  deriving (Eq, Ord, Show)

progression :: Double -> Progression
progression x =
  if (x >= 0.0 && x <= 1.0)
  then Progression x
  else error "Progression must be in the range [0,1]"

data Locator = Locator {
  chapterHref        :: URI,
  chapterProgression :: Progression
} deriving (Eq, Ord, Show)
```

### Serialization

Locators _MUST_ be serialized using the following [JSON schema](locatorSchema.json):

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "urn:org.librarysimplified.bookmarks:locator:1.0",
  "title": "Simplified Bookmark Locator",
  "description": "A bookmark locator",
  "type": "object",
  "oneOf": [
    {
      "type": "object",
      "properties": {
        "@type": {
          "description": "The type of locator",
          "type": "string",
          "pattern": "Locator"
        },
        "idref": {
          "description": "The unique identifier for a chapter (chapterHref)",
          "type": "string"
        },
        "progressWithinChapter": {
          "description": "The progress within a chapter (chapterProgression)",
          "type": "number",
          "minimum": 0.0,
          "maximum": 1.0
        }
      },
      "required": [
        "idref",
        "progressWithinChapter",
        "@type"
      ]
    }
  ]
}
```

An example of a valid, serialized locator is given in [valid-locator-0.json](valid-locator-0.json):

```json
{
  "@type": "Locator",
  "idref": "/xyz.html",
  "progressWithinChapter": 0.5
}
```

## Bookmarks

A _Bookmark_ is a Web Annotation with the following data:

  * A [body](#bodies) containing optional metadata such as the reader's current
    progress through the entire publication.
  * A [motivation](#motivations) indicating the type of bookmark.
  * A [target](#targets) that uniquely identifies the publication, and includes
    a _selector_ that includes a serialized [Locator](#locators).
  * An optional _id_ value that uniquely identifies the bookmark. This
    is typically assigned by the server.

```haskell
data Bookmark = Bookmark {
  bookmarkId         :: Maybe URI,
  bookmarkTarget     :: BookmarkTarget,
  bookmarkMotivation :: Motivation,
  bookmarkBody       :: BookmarkBody
} deriving (Eq, Show)
```

### Bodies

A _body_ contains optional metadata that applications _MAY_ use to derive
extra data for display in the application. Currently, bodies are defined as
simple maps of strings to strings, and clients are free to ignore any and all
included values.

```haskell
type BookmarkBody = DM.Map String String
```

### Targets

A _target_ uniquely identifies a publication, and uses a [Locator](#locators)
to uniquely identify a position within that publication. The value of the
`targetSource` field is typically taken from metadata included in the publication,
or from the OPDS feed that originally delivered the publication.

```haskell
data BookmarkTarget = BookmarkTarget {
  targetLocator :: Locator,
  targetSource  :: String
} deriving (Eq, Show)
```

### Motivations

A _motivation_ is value that simply indicates whether a bookmark was
created explicitly by the user, or created implicitly by the application
each time the user navigates to a new page. Explicitly created bookmarks
are denoted by the _bookmarking_ motivation, whilst implicitly created bookmarks
are denoted by the _idling_ motivation. In practice, there is exactly one
_idling_ bookmark in the user's set of bookmarks at any given time, and
the reading application effectively replaces the current _idling_ bookmark
each time the user turns a page in a given publication.

```haskell
data Motivation
  = Bookmarking
  | Idling
  deriving (Eq, Ord, Show)
```

### JSON Serialization

Bookmarks _MUST_ be serialized as Web Annotation values according to
the following rules:

* [Body](#bodies) values _MUST_ be serialized as string-typed properties
  with string-typed values in the annotation's `body` property.
  
* [Motivation](#motivations) values _MUST_ be serialized as one of
  the two possible string values according to the `motivationJSON` function:
  
```haskell
motivationJSON :: Motivation -> String
motivationJSON Bookmarking = "https://www.w3.org/ns/oa#bookmarking"
motivationJSON Idling      = "http://librarysimplified.org/terms/annotation/idling"
```

* [Target](#targets) values _MUST_ be serialized with:
  * A `selector` property containing an object with:
    * A `type` property equal to `"oa:FragmentSelector"`.
    * A `value` property containing a [Locator](#locators) serialized as a string value.
  * A `source` property with a string value that uniquely identifies the publication.
    
If present, the bookmark's `id` field _MUST_ be serialized as an `id`
property with a string value equal to the `id` field.

The bookmark _SHOULD_ be serialized with a `type` property set to the string
value `"Annotation"`, and a `@context` property set to the string
`"http://www.w3.org/ns/anno.jsonld"`.

An example of a valid bookmark is given in [valid-bookmark-0.json](valid-bookmark-0.json):

```json
{
  "@context": "http://www.w3.org/ns/anno.jsonld",
  "type": "Annotation",
  "id": "urn:uuid:715885bc-23d3-4d7d-bd87-f5e7a042c4ba",

  "body": {
    "http://librarysimplified.org/terms/time": "2021-03-12T16:32:49Z",
    "http://librarysimplified.org/terms/device": "urn:uuid:c83db5b1-9130-4b86-93ea-634b00235c7c"
  },

  "motivation": "http://librarysimplified.org/terms/annotation/idling",

  "target": {
    "selector": {
      "type": "oa:FragmentSelector",
      "value": "{\n  \"@type\": \"Locator\",\n  \"idref\": \"/xyz.html\",\n  \"progressWithinChapter\": 0.5\n}\n"
    },
    "source": "urn:uuid:1daa8de6-94e8-4711-b7d1-e43b572aa6e0"
  }
}
```
