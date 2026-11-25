# Working on cleanpaste

cleanpaste is a macOS login agent that strips tracking parameters from a URL the moment it
is copied. Almost every change to this repo is "add a tracking parameter". That takes two
data edits and one command.

## Adding a tracking parameter

1. **Find where it belongs in `Sources/Rules.swift`.** That file is the complete list of
   what gets stripped. Names are lowercase.

   | The parameter is... | Add it to |
   |---|---|
   | A tracker on every site, with a name nothing else would use (`fbclid`) | `globalParams` |
   | A family sharing a prefix (`utm_source`, `utm_medium`) | `globalPrefixes` |
   | A tracker only on one site, or a short or generic name (`s`, `t`, `ref`, `a`) | that site's entry in `siteRules`, or a new entry |
   | A generic name that only tracks for certain values (`ref=chatgpt.com`) | the value goes in `referrerValues` |

   When unsure, use a site rule. A parameter wrongly added to `globalParams` breaks links
   on sites that use the same name for something real.

2. **Add test cases to `Tests/cases.txt`:**
   - a `strip` line with a real-looking URL and what it must become;
   - a `keep` line for a look-alike that must survive (the same name on another site, or a
     functional parameter on the same site).

3. **Run `./test.sh`.** It must end with `rule tests passed`.

Do not change `Sources/Cleaner.swift`, `Sources/RuleTypes.swift` or `Sources/main.swift`
to add a rule. If a tracker cannot be expressed in `Rules.swift`, say so instead of
special-casing it.

## Site rules

```swift
SiteRule(hosts: [.domain("x.com"), .domain("twitter.com")],
         params: ["s", "t", "a", "cxt"]),
```

- `.domain("x.com")` matches x.com and every subdomain.
- `.brand("amazon")` matches any subdomain and any country suffix (`www.amazon.co.uk`).
- `.brandRoot("google")` matches only the bare or `www` host, not `docs.google.com`.
- Optional fields: `prefixes` (name prefixes), `stripRefSegments` (drop `/ref=...` path
  segments), `unwrapRedirect` (replace a redirect page with its destination).

Check for an existing entry for the site before adding a new one.

## What not to strip

Leave anything the page needs to show the same content: ids, search queries, page
numbers, language, timestamps, variant selectors, gift or unlock codes. If you cannot tell
whether a parameter is functional, leave it and say so.

## Layout

| Path | What it is |
|---|---|
| `Sources/Rules.swift` | The rules. Data only. |
| `Sources/RuleTypes.swift` | Types the rules are written in. |
| `Sources/Cleaner.swift` | Applies the rules to one URL string. |
| `Sources/main.swift` | Watches the clipboard and rewrites it. |
| `Tests/cases.txt` | Rule test cases. |
| `Tests/run.swift` | Runs the cases. |

## Commands

- `./test.sh`: runs every case in `Tests/cases.txt`. Takes a few seconds and touches
  nothing outside `build/`.
- `./install.sh`: inside a checkout, builds from source and reloads the login agent so
  rule changes take effect. This changes the user's machine, so run it only when asked.
  It refuses to run if cleanpaste is installed through Homebrew.
- `./install.sh --uninstall`: stop the agent and remove it.
- `./release.sh <version>`: publish a release. Maintainer only; see below.

The clipboard watcher in `Sources/main.swift` has no automated test. If you change it,
say so and ask the user to copy a tracked URL and paste it.

## Trying a rule change on this Mac

Check how cleanpaste is installed with `brew services list | grep cleanpaste`.

- **Installed with curl, or not installed:** run `./install.sh`.
- **Installed with Homebrew:** `./install.sh` refuses, so two watchers never run at once.
  Swap temporarily:
  1. `brew services stop cleanpaste && ./install.sh`
  2. Ask the user to copy the URL and paste it.
  3. Switch back: `./install.sh --uninstall && brew services start cleanpaste`

To make the change permanent for everyone, commit it and release it (below). Homebrew
users then run `brew upgrade cleanpaste`.

## Releasing

Rule changes reach users only through a release.

1. Commit the change on `main`.
2. Run `./release.sh <version>`, bumping the last number for rule changes (`0.1.0` to
   `0.1.1`).

The script runs the tests, builds a universal binary for macOS 12 and later, tags the
commit, creates the GitHub release and updates `Formula/cleanpaste.rb` in
`filip-pilar/homebrew-tap`. Users then update with `brew upgrade cleanpaste` or by
running the curl installer again. Publishing is visible to everyone, so do it only when
the user asks.

## Constraints

- No network access, no logging, no files written at runtime.
- The clipboard is rewritten only when its whole text is one http(s) URL. Copies marked
  concealed or transient by password managers are never read.
- Kept parameters must stay byte-for-byte identical. Never round-trip through
  `URLComponents`.
