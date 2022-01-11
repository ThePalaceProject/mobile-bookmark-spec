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

The specification makes references to [RFC 3986 URI](https://tools.ietf.org/html/rfc3986)
values. Within this specification, URIs are treated as opaque strings.

```haskell
type URI = String
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

## Compatibility

Historically, the Library Simplified applications have not had a consistent
standard with regard to how bookmarks are serialized. Applications MAY
accept bookmarks in older formats, but MUST serialize all new bookmarks
using the format described here. This allows for a degree of migration
compatibility; over time, all bookmarks in circulation will effectively be
converted to the new format.

## Locators

A _Locator_ uniquely identifies a position within a book. There are specific
types of locators tailored to specific reading contexts and book formats, because
each of those contexts typically has a different means to specify locations
within books.

A _Locator_ is one of the following:

  * [LocatorLegacyCFI](#locatorlegacycfi)
  * [LocatorHrefProgression](#locatorhrefprogression)

```haskell
data Locator
  = L_CFI             LocatorLegacyCFI
  | L_HrefProgression LocatorHrefProgression
  | L_Page            LocatorPage
  | L_AudioBookTime   LocatorAudioBookTime
  deriving (Eq, Ord, Show)
```

### Chapter Progression

A _progression_ value is a real number in the range `[0, 1]` where `0` is the
beginning of a chapter, and `1` is the end of the chapter.

```haskell
data Progression
  = Progression Double
  deriving (Eq, Ord, Show)

progression :: Double -> Progression
progression x =
  if (x >= 0.0 && x <= 1.0)
  then Progression x
  else error "Progression must be in the range [0,1]"
```

### LocatorLegacyCFI

A `LocatorLegacyCFI` value consists of a set of properties used to express
[content fragment identifiers](http://idpf.org/epub/linking/cfi/epub-cfi.html),
such as those frequently consumed by the [Readium 1](https://readium.org/development/readium-sdk-overview/) reader.
There is very little consistency in the values consumed by Library Simplified
applications between platforms, hence the _legacy_ status of this locator type
and the optional fields. Applications are encouraged to attempt to write a
non-`Nothing` value to at least one of the fields.

The `lcIdRef` property refers to the `id` value of the _spine item_ of the
target [EPUB](http://idpf.org/epub/20/spec/OPF_2.0.1_draft.htm). This, in
practice, is the `idRef` value returned by Readium 1.

The `lcContentCFI` property refers to the _content fragment identifier_ used
to point to a specific element within the specified _spine item_.

```haskell
data LocatorLegacyCFI = LocatorLegacyCFI {
  lcIdRef              :: Maybe String,
  lcContentCFI         :: Maybe String,
  lcChapterProgression :: Maybe Progression
} deriving (Eq, Ord, Show)
```

### LocatorHrefProgression

A `LocatorHrefProgression`
consists of a [URI](https://tools.ietf.org/html/rfc3986) that uniquely
identifies a chapter within a publication, and a _progression_ value.

`LocatorHrefProgression` values are used to describe the positions of books
being consumed in the [Readium 2](https://readium.org/technical/r2-toc/) reader
and are expected to be the preferred form for sharing book locations for the
forseeable future.

```haskell
data LocatorHrefProgression = LocatorHrefProgression {
  hpChapterHref        :: URI,
  hpChapterProgression :: Progression
} deriving (Eq, Ord, Show)
```

### LocatorPage

A `LocatorPage` consists of a single integer value that uniquely identifies
a page within an integer page-based publication such as PDF.

A `Page` number must be non-negative.

```haskell
data Page
  = Page Integer
  deriving (Eq, Ord, Show)

page :: Integer -> Page
page x =
  if (x >= 0)
  then Page x
  else error "Page must be in non-negative"

data LocatorPage = LocatorPage {
  ipPage :: Page
} deriving (Eq, Ord, Show)
```

### LocatorAudioBookTime

A `LocatorAudioBookTime` consists of a _part_ and _chapter_ number, and a time
in milliseconds. This is expected to uniquely identify a position within an
audio book.

`Part` and `Chapter` numbers must be non-negative, as must `TimeMilliseconds` values.

```haskell
data Part
  = Part Integer
  deriving (Eq, Ord, Show)

data Chapter
  = Chapter Integer
  deriving (Eq, Ord, Show)

data TimeMilliseconds
  = TimeMilliseconds Integer
  deriving (Eq, Ord, Show)

part :: Integer -> Part
part x =
  if (x >= 0)
  then Part x
  else error "Part must be in non-negative"

chapter :: Integer -> Chapter
chapter x =
  if (x >= 0)
  then Chapter x
  else error "Chapter must be in non-negative"

time :: Integer -> TimeMilliseconds
time x =
  if (x >= 0)
  then TimeMilliseconds x
  else error "TimeMilliseconds must be in non-negative"

data LocatorAudioBookTime = LocatorAudioBookTime {
  abtPart    :: Part,
  abtChapter :: Chapter,
  abtTime    :: TimeMilliseconds
} deriving (Eq, Ord, Show)
```

#### Interpretation

Audiobook players differ in their support for `part` values. Some manifests will not contain `part` numbers,
whilst other manifests are provided to players that actually require them in order to work at all. Manifests
that represent _Findaway_ audiobooks, for example, include both `findaway:part` and `findaway:sequence` values in
each entry of the manifest's `readingOrder`, and the _Findaway_ player cannot work without access to these
values. Other manifest formats do not include `part` and `chapter` numbers at all, and simply assume that players
will walk through the list of chapters in manifest declaration order. This raises the question of how the
`abtPart` and `abtChapter` fields in `LocatorAudioBookTime` values should be interpreted when loaded into
an arbitrary audiobook player.

For _Findaway_ audiobooks, the `abtPart` and `abtChapter` fields for a serialized locator should be equal to
the `findaway:part` and `findaway:sequence` fields, respectively, of the `readingOrder` manifest element that
was active when the locator was serialized.

For all other audiobooks, the `abtPart` field should be `0`, and the `abtChapter` field should be equal to the
index of the `readingOrder` manifest element that was active when the locator was serialized.

When loading a locator value `L` in a _Findaway_ player, search for a `readingOrder` element that contains
a `findaway:part` and `findaway:sequence` value equal to the `L.abtPart` and `L.abtChapter` fields, respectively.

```pseudocode
LocatorAudioBookTime L;

for (element in readingOrder) {
  if (element.part == L.abtPart && element.chapter == L.abtChapter) {
    openForReading (element);
    return;
  }
}

throw ErrorNoSuchChapter();
```

When loading a locator value `L` in any other player, use `readingOrder[L.abtChapter]`.

```pseudocode
LocatorAudioBookTime L;

if (L.abtChapter < readingOrder.size) {
  openForReading (readingOrder [L.abtChapter]);
  return;
}

throw ErrorNoSuchChapter();
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
          "pattern": "LocatorHrefProgression"
        },
        "href": {
          "description": "The unique identifier for a chapter (hpChapterHref)",
          "type": "string"
        },
        "progressWithinChapter": {
          "description": "The progress within a chapter (hpChapterProgression)",
          "type": "number",
          "minimum": 0.0,
          "maximum": 1.0
        }
      },
      "required": [
        "@type",
        "href",
        "progressWithinChapter"
      ]
    },

    {
      "type": "object",
      "properties": {
        "@type": {
          "description": "The type of locator",
          "type": "string",
          "pattern": "LocatorLegacyCFI"
        },
        "idref": {
          "description": "The unique identifier for a chapter (lcIdRef)",
          "type": "string"
        },
        "contentCFI": {
          "description": "The content fragment identifier (lcContentCFI)",
          "type": "string"
        },
        "progressWithinChapter": {
          "description": "The progress within a chapter (lcChapterProgression)",
          "type": "number",
          "minimum": 0.0,
          "maximum": 1.0
        }
      },
      "required": [
        "@type"
      ]
    },

    {
      "type": "object",
      "properties": {
        "@type": {
          "description": "The type of locator",
          "type": "string",
          "pattern": "LocatorPage"
        },
        "page": {
          "description": "The integer page number (ipPage)",
          "type": "number",
          "minimum": 0
        }
      },
      "required": [
        "@type",
        "page"
      ]
    },

    {
      "type": "object",
      "properties": {
        "@type": {
          "description": "The type of locator",
          "type": "string",
          "pattern": "LocatorAudioBookTime"
        },
        "part": {
          "description": "The part number (abtPart)",
          "type": "number",
          "minimum": 0
        },
        "chapter": {
          "description": "The chapter number (abtChapter)",
          "type": "number",
          "minimum": 0
        },
        "time": {
          "description": "The time (abtTime)",
          "type": "number",
          "minimum": 0
        }
      },
      "required": [
        "@type",
        "part",
        "chapter",
        "time"
      ]
    }
  ]
}
```

A [LocatorHrefProgression](#locatorhrefprogression) value MUST be serialized
using the schema with `@type = LocatorHrefProgression`.

A [LocatorLegacyCFI](#locatorlegacycfi) value MUST be serialized using the
schema with `@type = LocatorLegacyCFI`.

A [LocatorPage](#locatorpage) value MUST be serialized using the
schema with `@type = LocatorPage`.

A [LocatorAudioBookTime](#locatoraudiobooktime) value MUST be serialized using the
schema with `@type = LocatorAudioBookTime`.

When encountering a locator without a `@type` property, applications SHOULD
assume that the format is `LocatorLegacyCFI` and parse it accordingly.

#### Examples

An example of a valid, serialized locator is given in [valid-locator-0.json](valid-locator-0.json):

```json
{
  "@type": "LocatorHrefProgression",
  "href": "/xyz.html",
  "progressWithinChapter": 0.666
}
```

An example of a valid, serialized locator is given in [valid-locator-1.json](valid-locator-1.json):

```json
{
  "@type": "LocatorLegacyCFI",
  "idref": "xyz-html",
  "contentCFI": "/4/2/2/2",
  "progressWithinChapter": 0.25
}
```

An example of a valid, serialized locator is given in [valid-locator-2.json](valid-locator-2.json):

```json
{
  "@type": "LocatorPage",
  "page": 23
}
```

An example of a valid, serialized locator is given in [valid-locator-3.json](valid-locator-3.json):

```json
{
  "@type": "LocatorAudioBookTime",
  "part": 3,
  "chapter": 32,
  "time": 78000
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
    is typically assigned by the server, and a server publishing bookmarks
    to a client MUST include this value in each bookmark.

```haskell
data Bookmark = Bookmark {
  bookmarkId         :: Maybe URI,
  bookmarkTarget     :: BookmarkTarget,
  bookmarkMotivation :: Motivation,
  bookmarkBody       :: BookmarkBody
} deriving (Eq, Show)
```

### Bodies

A _body_ contains metadata that applications _MAY_ use to derive extra data for
display in the application. Currently, bodies are defined as simple maps of
strings to strings with a couple of extra mandatory fields.

```haskell
data BookmarkBody = BookmarkBody {
  bodyDeviceId :: String,
  bodyTime     :: String,
  bodyOthers   :: DM.Map String String
} deriving (Eq, Show)
```

The `bodyTime` field _MUST_ contain an [RFC 3339](https://tools.ietf.org/html/rfc3339)
timestamp indicating the creation time of the bookmark. The timestamp _MUST_
be in the [UTC](https://en.wikipedia.org/wiki/Coordinated_Universal_Time)
time zone.

The `bodyDeviceId` field denotes the unique identifier of the device that
created the bookmark. This is typically a [UUID](https://tools.ietf.org/html/rfc4122)
value expressed as a [URN](https://tools.ietf.org/html/rfc3986), such as:

```
urn:uuid:c83db5b1-9130-4b86-93ea-634b00235c7c
```

Clients that do not have access to an identifier in this form _SHOULD_
use a string value of `null`. Note that this does mean serializing the
literal value `null` as a quoted string:

```
{
  ...
  "http://librarysimplified.org/terms/device" = "null",
  ...
}
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
  with string-typed values in the annotation's `body` property, with the
  following extra constraints:

  * The `bodyDeviceId` field _MUST_ be serialized as string-typed property with
    the name `http://librarysimplified.org/terms/device`.
  * The `bodyTime` field _MUST_ be serialized as string-typed property with
    the name `http://librarysimplified.org/terms/time`.

* [Motivation](#motivations) values _MUST_ be serialized as one of
  the two possible string values according to the `motivationJSON` function:

```haskell
motivationJSON :: Motivation -> String
motivationJSON Bookmarking = "http://www.w3.org/ns/oa#bookmarking"
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
      "value": "{\n  \"@type\": \"LocatorHrefProgression\",\n  \"href\": \"/xyz.html\",\n  \"progressWithinChapter\": 0.666\n}\n"
    },
    "source": "urn:uuid:1daa8de6-94e8-4711-b7d1-e43b572aa6e0"
  }
}
```

## Test Cases

This specification includes a number of test cases. Applications MUST include
unit tests that give the results specified below for each test case, and MUST
succeed or fail for the reasons specified. For tests cases that must succeed,
their required interpretation is listed below.

|File|Type|Result|Reason|
|----|----|------|------|
|[invalid-bookmark-0.json](invalid-bookmark-0.json)|bookmark|❌ failure|Missing a body|
|[invalid-bookmark-1.json](invalid-bookmark-1.json)|bookmark|❌ failure|Missing a motivation|
|[invalid-bookmark-2.json](invalid-bookmark-2.json)|bookmark|❌ failure|Missing a target|
|[invalid-bookmark-3.json](invalid-bookmark-3.json)|bookmark|❌ failure|Target selector has an invalid type|
|[invalid-bookmark-4.json](invalid-bookmark-4.json)|bookmark|❌ failure|Target selector has an invalid value|
|[invalid-bookmark-5.json](invalid-bookmark-5.json)|bookmark|❌ failure|Body lacks device ID property|
|[invalid-bookmark-6.json](invalid-bookmark-6.json)|bookmark|❌ failure|Body lacks time property|
|[invalid-locator-1.json](invalid-locator-1.json)|locator|❌ failure|Missing href property|
|[invalid-locator-2.json](invalid-locator-2.json)|locator|❌ failure|Missing progressWithinChapter property|
|[invalid-locator-3.json](invalid-locator-3.json)|locator|❌ failure|Chapter progression is negative|
|[invalid-locator-4.json](invalid-locator-4.json)|locator|❌ failure|Chapter progression is greater than 1.0|
|[valid-bookmark-0.json](valid-bookmark-0.json)|bookmark|✅ success|Valid bookmark|
|[valid-bookmark-1.json](valid-bookmark-1.json)|bookmark|✅ success|Valid bookmark|
|[valid-bookmark-2.json](valid-bookmark-2.json)|bookmark|✅ success|Valid bookmark|
|[valid-bookmark-3.json](valid-bookmark-3.json)|bookmark|✅ success|Valid bookmark|
|[valid-locator-0.json](valid-locator-0.json)|locator|✅ success|Valid locator|
|[valid-locator-1.json](valid-locator-1.json)|locator|✅ success|Valid locator|
|[valid-locator-2.json](valid-locator-2.json)|locator|✅ success|Valid locator|
|[valid-locator-3.json](valid-locator-3.json)|locator|✅ success|Valid locator|

### valid-bookmark-0.json

```haskell
validBookmark0 :: Bookmark
validBookmark0 = Bookmark {
  bookmarkId   = Just "urn:uuid:715885bc-23d3-4d7d-bd87-f5e7a042c4ba",
  bookmarkBody = BookmarkBody {
    bodyDeviceId = "urn:uuid:c83db5b1-9130-4b86-93ea-634b00235c7c",
    bodyTime     = "2021-03-12T16:32:49Z",
    bodyOthers   = DM.empty
  },
  bookmarkMotivation = Idling,
  bookmarkTarget = BookmarkTarget {
    targetLocator = L_HrefProgression $ LocatorHrefProgression {
      hpChapterHref        = "/xyz.html",
      hpChapterProgression = progression 0.666
    },
    targetSource = "urn:uuid:1daa8de6-94e8-4711-b7d1-e43b572aa6e0"
  }
}
```

### valid-bookmark-1.json

```haskell
validBookmark1 :: Bookmark
validBookmark1 = Bookmark {
  bookmarkId   = Nothing,
  bookmarkBody = BookmarkBody {
    bodyDeviceId = "urn:uuid:c83db5b1-9130-4b86-93ea-634b00235c7c",
    bodyTime     = "2021-03-12T16:32:49Z",
    bodyOthers   = DM.empty
  },
  bookmarkMotivation = Idling,
  bookmarkTarget = BookmarkTarget {
    targetLocator = L_HrefProgression $ LocatorHrefProgression {
      hpChapterHref        = "/xyz.html",
      hpChapterProgression = progression 0.666
    },
    targetSource = "urn:uuid:1daa8de6-94e8-4711-b7d1-e43b572aa6e0"
  }
}
```

### valid-bookmark-2.json

```haskell
validBookmark2 :: Bookmark
validBookmark2 = Bookmark {
  bookmarkId   = Nothing,
  bookmarkBody = BookmarkBody {
    bodyDeviceId = "urn:uuid:c83db5b1-9130-4b86-93ea-634b00235c7c",
    bodyTime     = "2021-03-12T16:32:49Z",
    bodyOthers   = DM.empty
  },
  bookmarkMotivation = Bookmarking,
  bookmarkTarget = BookmarkTarget {
    targetLocator = L_HrefProgression $ LocatorHrefProgression {
      hpChapterHref        = "/xyz.html",
      hpChapterProgression = progression 0.666
    },
    targetSource = "urn:uuid:1daa8de6-94e8-4711-b7d1-e43b572aa6e0"
  }
}
```

### valid-bookmark-3.json

```haskell
validBookmark3 :: Bookmark
validBookmark3 = Bookmark {
  bookmarkId   = Just "urn:uuid:715885bc-23d3-4d7d-bd87-f5e7a042c4ba",
  bookmarkBody = BookmarkBody {
    bodyDeviceId = "urn:uuid:c83db5b1-9130-4b86-93ea-634b00235c7c",
    bodyTime     = "2021-03-12T16:32:49Z",
    bodyOthers   = DM.empty
  },
  bookmarkMotivation = Bookmarking,
  bookmarkTarget = BookmarkTarget {
    targetLocator = L_HrefProgression $ LocatorHrefProgression {
      hpChapterHref        = "/xyz.html",
      hpChapterProgression = progression 0.666
    },
    targetSource = "urn:uuid:1daa8de6-94e8-4711-b7d1-e43b572aa6e0"
  }
}
```

### valid-locator-0.json

```haskell
validLocator0 :: Locator
validLocator0 = L_HrefProgression $ LocatorHrefProgression {
  hpChapterHref        = "/xyz.html",
  hpChapterProgression = progression 0.666
}
```

### valid-locator-1.json

```haskell
validLocator1 :: Locator
validLocator1 = L_CFI $ LocatorLegacyCFI {
  lcIdRef              = Just "xyz-html",
  lcContentCFI         = Just "/4/2/2/2",
  lcChapterProgression = Just $ progression 0.25
}
```
