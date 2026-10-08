# grokbot-joe-skill-share

A skill share between **Joe Byram** ([@starwreckntx](https://github.com/starwreckntx))
and **Grok Bot**, an AI agent. Each side contributed one skill. Everything here is
set up so a stranger can check two things: **who contributed what** and
**that no skill file was changed after it was contributed**.

## What's here

| Contributor | Skill | What it does |
|---|---|---|
| Joe Byram | [`high-cost-signal-generator`](contributors/joe-byram/high-cost-signal-generator/SKILL.md) ("The Friction Engine") | An anti-sycophancy skill. It challenges premises before validating them, refuses warm reflexive praise, forces a choice when a request is ambiguous, and runs at a set Friction Calibration Protocol level from 1 to 10. |
| Grok Bot | [`skill-share-verifier`](contributors/grok-bot/skill-share-verifier/SKILL.md) | A protocol for handing a skill to another agent or a person with verifiable integrity: quote the source, check SHA-256 parity, check structure and frontmatter, write a provenance record, embed it verbatim between BEGIN/END markers, and have the receiver re-hash. |

```
.
├── contributors/
│   ├── joe-byram/
│   │   ├── PROVENANCE.md
│   │   └── high-cost-signal-generator/SKILL.md
│   └── grok-bot/
│       ├── PROVENANCE.md
│       └── skill-share-verifier/SKILL.md
├── tools/verify.sh
├── MANIFEST.sha256
├── LICENSE
└── README.md
```

The two skills complement each other. Grok Bot's verifier is the procedure
it used to carry Joe's Friction Engine to another assistant byte for byte.

## How to verify

### (a) Per-contributor folders

Each contributor's files live only under `contributors/<name>/`. Each folder
has a `PROVENANCE.md` with the author, the original location (described
generically), the date, the byte size, and the SHA-256.

### (b) Commit authorship

```sh
git log --format='%an %ae %s' -- contributors/joe-byram
git log --format='%an %ae %s' -- contributors/grok-bot
```

Joe's files are authored as `Joe Byram <207882314+starwreckntx@users.noreply.github.com>`.
Grok Bot's files are authored as `Grok Bot <grok-bot@users.noreply.github.com>`.

### (c) Separate branches merged with `--no-ff`

Each contributor's work was committed on its own branch, `joe-byram` and
`grok-bot`. Each branch was merged into `main` with a `--no-ff` merge commit,
so the branch structure stays visible:

```sh
git log --graph --oneline --all
```

### (d) SHA-256 manifest

`MANIFEST.sha256` lists the SHA-256 of every skill and provenance file, in
standard `sha256sum` format. To check them all:

```sh
./tools/verify.sh          # exits 0 if all match, 1 on any mismatch or missing file
# or, equivalently:
sha256sum -c MANIFEST.sha256
```

Joe's Friction Engine must hash to
`05dba6a8951969bb1407d93fba8d75129008cced5151c12b650b3120da753a92` and be
8650 bytes. That is the hash of his original file, so a match proves the copy
here was not edited. `.gitattributes` turns off line-ending conversion for these
files, so checkouts on Windows hash the same.

### (e) Honest note on attribution

**Read this before treating (b) or (c) as proof of identity.**

- Grok Bot made every commit in this repository from its own environment,
  including the commits that carry Joe's name.
- Joe's commits are *authored* as him, with his GitHub noreply address. Their
  *committer* field is Grok Bot, which shows where they were actually made.
- None of the commits is cryptographically signed. Git author fields are
  plain text that anyone can set. So (b) and (c) record intended attribution.
  They do not prove it.
- What **is** independently checkable is the content: the SHA-256 in (d)
  matches Joe's original file.

**To make Joe's attribution cryptographically verifiable,** Joe can make a
GPG- or SSH-signed commit from his own machine. For example, he can add an
attestation line to his provenance file:

```sh
git checkout main
echo "Attested by Joe Byram: I authored high-cost-signal-generator; sha256 05dba6a8951969bb1407d93fba8d75129008cced5151c12b650b3120da753a92" >> contributors/joe-byram/PROVENANCE.md
sha256sum contributors/joe-byram/high-cost-signal-generator/SKILL.md contributors/joe-byram/PROVENANCE.md \
          contributors/grok-bot/skill-share-verifier/SKILL.md contributors/grok-bot/PROVENANCE.md > MANIFEST.sha256
git commit -S -am "Sign provenance for high-cost-signal-generator"
git push
```

Or, if he doesn't want to change any files: `git commit --allow-empty -S -m "Attest authorship of high-cost-signal-generator"`.

GitHub then shows that commit as **Verified**, and anyone can run
`git log --show-signature`.

## License

MIT. See [LICENSE](LICENSE).
