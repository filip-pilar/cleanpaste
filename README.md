# clipclean

**Copy a link, paste a clean one.** A tiny macOS background agent that strips tracking
parameters from URLs the moment you copy them.

```text
you copy    https://example.com/article?utm_source=chatgpt.com&id=42&fbclid=abc123
you paste   https://example.com/article?id=42
```

## Set it up with your agent

Paste this into Claude Code, Codex, Cursor or any coding agent on your Mac:

```text
Set up clipclean on this Mac. It is a small macOS login agent that strips tracking
parameters from URLs when I copy them.

1. Clone https://github.com/filip-pilar/clipclean into a folder where I keep code.
2. Read AGENTS.md and install.sh so you know what will be installed before running anything.
3. Run ./test.sh and confirm it ends with "rule tests passed".
4. Run ./install.sh. It builds the binary into ~/.local/bin/clipclean and adds a login
   agent at ~/Library/LaunchAgents/local.clipclean.plist.
5. Confirm the agent is running with: pgrep -lx clipclean
6. Tell me what was installed and how to remove it (./uninstall.sh).

Then ask me to copy a link with tracking parameters and paste it, to check it works.
```

## Or install it yourself

Needs macOS and the Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/filip-pilar/clipclean.git
```

```bash
cd clipclean && ./install.sh
```

Remove it with `./uninstall.sh`.

## What it cleans

| You copy | You paste |
|---|---|
| `example.com/post?utm_source=newsletter&id=7` | `example.com/post?id=7` |
| `example.com/post?ref=chatgpt.com` | `example.com/post` |
| `youtu.be/dQw4w9WgXcQ?si=abcdef&t=42` | `youtu.be/dQw4w9WgXcQ?t=42` |
| `x.com/someone/status/123?a=AbCdEf` | `x.com/someone/status/123` |
| `amazon.com/Some-Product/dp/B08N5WRWNW/ref=sr_1_3?crid=1&qid=1&th=1` | `amazon.com/Some-Product/dp/B08N5WRWNW?th=1` |
| `google.com/search?q=mac+apps&sca_esv=…&ei=…&ved=…` (20 more) | `google.com/search?q=mac+apps` |
| `google.com/url?…&url=https://example.com/page` | `example.com/page` |

- **Known trackers, everywhere:** `utm_*`, `fbclid`, `gclid`, `msclkid`, `mc_eid` and
  many more.
- **Short or generic names, only where they track:** `si` on YouTube and Spotify; `s`, `t`
  and `a` on X. The same names on other sites are left alone.
- **Referrer tags:** `?ref=chatgpt.com` goes, `?ref=main` stays.

The complete list is one file: [Sources/Rules.swift](Sources/Rules.swift).

## Footprint

- Native Swift, about 120 KB, no dependencies.
- Around 0.02 to 0.03% of one CPU core while you use the Mac, less when you are away.
- About 3 MB of memory.
- No network access, no logging, nothing written to disk.

## Limits

- **There is a short delay.** A copy is cleaned about 0.1 to 0.25 seconds after you make
  it; paste faster and you get the original. macOS has no clipboard-change event, so
  clipclean has to poll.
- **Only a lone URL is rewritten.** Text that merely contains a link is left alone, and a
  cleaned link becomes plain text.
- **It works from a list.** A tracker it has never seen stays in.
- **Short links are not resolved.** `t.co` or `bit.ly` would need network requests.
- **Password-manager copies are never read.**

## Missed a tracker?

Give your agent the URL:

```text
In the clipclean repo, this copied URL kept its tracking parameters: <paste URL>
Follow AGENTS.md to add a rule for it, run ./test.sh, then ./install.sh.
```

The repo is laid out for this: rules are data in one file, test cases are data in another,
and [AGENTS.md](AGENTS.md) is the procedure.

## Licence

MIT. See [LICENSE](LICENSE).
