# Localization

Tinycast ships English and Korean. The language is a setting, not a relaunch: **Settings › General ›
Language** offers System / English / 한국어, and every window redraws in place.

## How a string is resolved

| Path | Used by | Reaches the catalog because |
| --- | --- | --- |
| `Text("…")`, `Button("…")`, `.help("…")` | most views | the parameter is a `LocalizedStringKey`, which Xcode extracts on its own |
| `Text(LocalizedStringKey(someString))` | a title a component takes as `String` | **it does not** — the key is added to the catalog by hand |
| `AppLanguage.localized(_:)` | AppKit, which has no environment to read | the same: added by hand |

The second row is why a component like `SettingsRow` still takes `String`: the same value is a search
target as well as a label, and `SettingsSearchCatalog` matches it textually. Wrapping it at the render
point localizes all 78 rows without changing a single call site — but the extractor never sees those
literals, so they live in the catalog as `"extractionState": "manual"`, which is what keeps
`xcstringstool sync` from dropping them.

**An unmatched key falls back to itself.** That is what lets a runtime name — an app, a note, a
clipboard entry — pass through `Text(LocalizedStringKey(_:))` untouched.

## The locale reaches a window through its root

`View.appLocale(_:)` sets `\.locale`, and every hosted root applies it. A stored value would freeze at
panel-build time, so the modifier reads `AppSettings` and re-reads under Observation — the same shape
`InterfaceMetricsScope` uses. A panel rebuilt on every show takes the resolved `Locale` instead, the
way it already takes `metrics`.

Adding a window means applying it there too, or that window stays in the system language.

`String(localized:locale:)` is **not** a way to do this: its `locale` formats the result, it does not
choose a table. `AppLanguage.localized(_:)` resolves through `ko.lproj` directly, and is the only
correct path outside SwiftUI.

## Adding or changing a string

```sh
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Debug \
    -derivedDataPath build/DerivedData SWIFT_EMIT_LOC_STRINGS=YES build
xcrun xcstringstool sync Tinycast/Resources/Localizable.xcstrings \
    $(find build/DerivedData -name '*.stringsdata' | sed 's/^/--stringsdata /')
```

That merges every extracted literal into `Localizable.xcstrings`; fill the `ko` value in. A string
reached through `LocalizedStringKey(_:)` or `AppLanguage.localized(_:)` is added to the catalog by
hand with `"extractionState": "manual"`.

## What is not translated

- **Anything the Mac names**: app names, file names, input sources, emoji names, currency names,
  time zones. These are data, and Finder does not translate them either.
- **Format-only and technical strings** — `%@: %@`, URLs, `npx`, shell arguments.
- **Extension content.** `Features/Extensions/` renders untrusted third-party strings; translating
  them is not ours to do.
- **Window titles**, which `titleVisibility = .hidden` never draws.
