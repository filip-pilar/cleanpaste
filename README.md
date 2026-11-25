# clipclean

A tiny macOS background agent that strips tracking parameters from URLs as you copy them.

Copy `https://example.com/article?utm_source=chatgpt.com&id=42&fbclid=abc123` and what
you paste is `https://example.com/article?id=42`.

- Native Swift, about 120 KB, no dependencies.
- No network access, no logging, nothing written to disk.
- Around 0.02 to 0.03% of one CPU core while you use the Mac, less when you are away, and
  about 3 MB of memory.

## Install

Requires macOS with the Xcode command line tools.

```bash
git clone https://github.com/filip-pilar/clipclean.git
```

```bash
cd clipclean && ./install.sh
```

This builds the binary into `~/.local/bin/clipclean` and adds a login agent at
`~/Library/LaunchAgents/local.clipclean.plist`. Remove both with `./uninstall.sh`.

## What it does

- Strips known trackers everywhere: `utm_*`, `fbclid`, `gclid`, `msclkid`, `mc_eid` and
  many more.
- Strips short or generic names only on the sites that use them as trackers, such as `si`
  on YouTube and Spotify or `s`, `t` and `a` on X.
- Strips referrer tags such as `?ref=chatgpt.com` while leaving `?ref=main` alone.
- Trims long Google and Bing search URLs and unwraps Google redirect links.

The full list is one file: [Sources/Rules.swift](Sources/Rules.swift).

## Limits

- A copy is cleaned about 0.1 to 0.25 seconds after you make it. Paste faster than that
  and you get the original. macOS has no clipboard-change event, so this is polling.
- Only a clipboard holding a single URL is rewritten. Text that contains a link is left
  alone, and a cleaned link becomes plain text.
- It works from a list. A tracker it has not seen stays in.
- Shortened links (`t.co`, `bit.ly`) are not resolved, since that needs network requests.
- Copies marked as concealed by password managers are never read.

## Adding a rule

See [AGENTS.md](AGENTS.md). In short: add the name to `Sources/Rules.swift`, add a case to
`Tests/cases.txt`, run `./test.sh --rules`, then `./install.sh`.

## Licence

MIT. See [LICENSE](LICENSE).
