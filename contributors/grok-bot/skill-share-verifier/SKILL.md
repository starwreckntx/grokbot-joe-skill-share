---
name: skill-share-verifier
description: >
  Hand a skill (a SKILL.md or other prompt/instruction file) from one agent to
  another agent, or to a human, so the receiver can prove that what arrived is
  exactly what the author wrote. Covers quoting the source, SHA-256 parity,
  structure and frontmatter checks, a provenance record, verbatim embedding
  between BEGIN/END markers, and a re-hash by the receiver. Use whenever someone
  says "share this skill", "transfer this skill", "port this skill to Gemini /
  ChatGPT / another agent", "verifiable skill share", "prove it wasn't changed",
  or when a skill crosses a trust boundary (between accounts, machines,
  vendors, or people). Never edit the source skill as part of a transfer.
---

# Skill Share Verifier

## Purpose

Skills get copied between agents all the time. They get pasted into chat
windows, rewritten into a new vendor's format, or summarized "for brevity".
Each step can silently change the text. Sometimes a curly quote replaces a
straight one. Sometimes a line ending flips. Sometimes a paraphrase drops the
one sentence that mattered. The receiver ends up running a different skill
than the author wrote, and nobody can tell.

This skill makes a transfer **checkable**. The sender produces a packet that
carries the exact bytes plus enough metadata for anyone to confirm, with one
command, that the bytes are unchanged. Trust moves from "the sender says so"
to "the hash says so".

## Ground rules

1. **The source is read-only.** Never fix typos, reformat, or "improve" the
   source during a transfer. If something is wrong, report it to the author
   and let them change it and re-issue it.
2. **Copy bytes, not text.** Use a file copy (`cp`, a download, a
   byte-exact upload). Do not retype or re-render. Do not round-trip through
   a rich-text editor or a chat box unless the receiver re-hashes afterward.
3. **Adaptation is a wrapper, never an edit.** If the receiver needs a
   different format (for example, a Gemini Gem's instructions box or a
   ChatGPT custom GPT), write a *separate* wrapper that points to or contains
   the untouched original. The original's hash must still verify.
4. **Report, don't redact.** If the skill text contains something that looks
   private (emails, IPs, file paths, client names, keys), stop and tell the
   author. Do not quietly scrub it. Scrubbing creates a new version, and only
   the author can approve a new version.

## The protocol

### Step 1: Quote the source

Identify exactly one source file. Record:

- its location, described generically if the real path is private
  ("author's skills library", not a home-directory path)
- the author
- its last-modified date
- the first and last lines of the file, quoted verbatim

Quoting the first and last lines catches a truncated copy before any
tooling runs.

### Step 2: Hash the source

```sh
sha256sum SKILL.md          # Linux
shasum -a 256 SKILL.md      # macOS
wc -c SKILL.md              # byte size
```

Write down both values. The pair (sha256, byte size) is the skill's
identity for this transfer.

### Step 3: Check structure and frontmatter

Before shipping, confirm the file is a well-formed skill:

- [ ] Starts with a `---` line and has a closing `---` line
- [ ] Frontmatter is valid YAML
- [ ] `name:` is present, lowercase-hyphenated, and matches the folder name
- [ ] `description:` is present and says *when* to use the skill, not just
      what it is
- [ ] Body has at least one heading, and code fences are balanced (an even
      count of ``` lines)
- [ ] Encoding is UTF-8, with no BOM unless the source had one

A quick check:

```sh
head -1 SKILL.md | grep -qx -- '---' && echo "opens ok"
awk 'NR>1 && /^---$/ {print "closes at line " NR; exit}' SKILL.md
grep -c '^```' SKILL.md     # should be even
grep -E '^(name|description):' SKILL.md
```

Record any failures in the provenance file. Do **not** fix them in the
source (see ground rule 1).

### Step 4: Write a provenance record

Create `PROVENANCE.md` next to the copy:

| Field | Example |
|---|---|
| Skill name | `my-skill` |
| Author | Name (and public handle) |
| Original location | Generic description |
| Source last modified | YYYY-MM-DD |
| Byte size | 8650 |
| SHA-256 | 64 hex chars |
| Transferred by | Agent or person who did the copy |
| Structure check | pass / list of findings |

Keep secrets, private paths, personal emails, and client names out of it.

### Step 5: Embed verbatim between markers (for text-only channels)

If the skill has to travel through a channel that only carries text, such as
a chat message, an email body, or a single pasted file, wrap it like this:

```
=== SKILL TRANSFER PACKET ===
name:   my-skill
sha256: <64 hex>
bytes:  <n>
author: <name>
note:   Everything strictly between the BEGIN and END lines below is
        the skill, byte-for-byte. The newline right after BEGIN and the
        newline right before END are delimiters, not content.
-----BEGIN SKILL my-skill-----
<exact file contents>
-----END SKILL my-skill-----
```

Define the delimiter rule explicitly (as in the `note:` line). Otherwise a
receiver can't tell whether a trailing newline belongs to the skill.

To extract on the receiving side:

```sh
awk '/^-----BEGIN SKILL /{f=1;next} /^-----END SKILL /{f=0} f' packet.txt > SKILL.md
```

This keeps every line between the markers, each with its trailing newline.
That matches a source that ends in exactly one newline, which most text
files do. If the hash doesn't match, check the trailing newline first.

### Step 6: Receiver re-hash

The receiver (not the sender) recomputes:

```sh
sha256sum SKILL.md
wc -c SKILL.md
```

and compares both values to the packet header or the provenance record.

- **Match:** the transfer is verified. Say so, and quote the hash.
- **Mismatch:** the transfer has failed. Don't install a "close enough" copy.
  Diff against a fresh extraction (`diff <(xxd a) <(xxd b)` shows invisible
  differences) and re-send.

For repositories, keep a `MANIFEST.sha256` (standard `sha256sum` format) and
a script that re-checks every entry, so anyone can verify everything at
once with one command.

### Step 7: Attribution (optional but recommended)

Hashes prove *what* was sent. They don't prove *who* wrote it. For
authorship:

- commit each contributor's files under their own name and noreply email,
  on their own branch, and merge with `--no-ff` so the branch structure
  survives in history
- best of all, have the author make a GPG- or SSH-**signed** commit (for
  example, re-committing their `PROVENANCE.md`) from their own machine.
  Unsigned author fields can be set by anyone. A signature can't.

Be honest in the README about which of these guarantees you actually have.

## Output checklist

When you finish a transfer, report:

1. Source quote (first and last lines) and generic location
2. SHA-256 and byte size of the source
3. Structure check result
4. Where the provenance record lives
5. The packet or copy location
6. The receiver's re-hash result, or "awaiting receiver re-hash"

## Anti-patterns

**Helpful rewriting.** Swapping in "improved" wording during transfer. The
receiver gets a skill nobody approved.

**Hashing the wrapper.** Publishing the hash of the packet or the adapted
version instead of the original skill. The receiver can't check it against
the author's file.

**Sender-only verification.** The sender hashes both ends and declares
success. Verification only counts when the receiving side recomputes.

**Silent redaction.** Scrubbing private-looking text without telling the
author. The hash changes, and so does the meaning.

**Attribution overclaiming.** Calling a commit "verified by the author" when
it only carries their name in the author field. Say "authored as" unless it
is signed.
