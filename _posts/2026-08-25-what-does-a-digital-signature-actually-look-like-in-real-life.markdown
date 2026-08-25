---
layout: post
title: What does a digital signature actually look like in real life?
date: 2026-08-25 12:00:00 +0200
description: A glass box and two keys — one that only locks, one that only opens. One page, one diagram, no jargon, and a signed PDF you can click and check.
img: digital-signature-glass-box.webp
fig-caption: The same note delivered twice — in Marko's open glass box and in his locked one.
tags: [Digital Signature, PKI, Security, Explainer]
---

You've seen the stamp at the bottom of a signed PDF. But what *is* it — a picture, a seal, a password?

Imagine building it out of real things. Here is everything you need: a glass box, a key that only locks, and a key that only opens. One page, one diagram, no jargon — and at the end, a PDF that is itself signed, so you can click the stamp and check the story against the real thing.

**The one-page version:** [download the signed PDF](/assets/pdf/what-does-a-digital-signature-actually-look-like-in-real-life-signed.pdf) *(also on [Google Drive](https://drive.google.com/file/d/1QSGh-Io1zGbamb4VmqYB4JAdKZY1wncO/view?usp=sharing))*.

## The glass box and the two keys

Picture a glass box. Everyone can read the note inside — the glass hides nothing. The glass cannot be broken and the box sits in a safe place, so the only way in is a key.

There are two different keys, and each does exactly one thing:

- The **locking key** can only lock. Marko has the only copy and never shares it.
- The **opening key** can only open. It is copied and handed to everyone.

That is the whole model. Now follow one note — "Pay the supplier — Marko" — from Marko to his colleague Boris, twice.

![The same note delivered in Marko's open glass box (column A) and in his locked glass box (column B), four steps each](/assets/img/digital-signature-glass-box-diagram.webp)

## Column A: delivered in Marko's open glass box

**1 · Write and put in.** Someone writes "Pay the supplier — Marko" and drops it into the glass box. No key is involved. The box stays open.

**2 · On the way.** Shelf, e-mail, download — anyone can read the note, and anyone can replace it with their own. Afterwards the box looks exactly the same.

**3 · Boris receives.** An open box. He can read the note and he can grab it — but there is nothing to open, so nothing to check. Swapped on the way? No way to tell.

**4 · What Boris knows.** No evidence. The note vouches only for itself. Not a lie — silence. Reading it is free; acting on it is a guess. This is an unsigned document, and it is where phishing lives.

## Column B: delivered in Marko's locked glass box

**1 · Write, put in — and lock.** Marko writes the note, puts it in the glass box and turns the locking key — the only copy. Sealed, not hidden: the glass still shows everything.

**2 · On the way.** Anyone can still read the note through the glass. Nobody can change it: take it out, and you cannot lock the box again without Marko's key.

**3 · Boris tries the opening key.** Every colleague was given a copy. It can only open, never lock. The box opens, or it doesn't.

**4 · What Boris knows.**

- ✓ **Opens** — Marko's, untouched, safe to take out. Marko wrote it, nobody changed it — and cannot deny it.
- ✗ **Won't open** — not Marko's, or tampered. Read it if you like. Leave it in the box. Do not act on it.

> **Every signed document you receive is column B. Every unsigned document is column A.**

For the curious: the locking key is what engineers call the *private key*, and locking is *signing*. The opening key is the *public key*, and opening is *verifying*.

## Read the stamp on the real thing

Download the signed PDF ([from this site](/assets/pdf/what-does-a-digital-signature-actually-look-like-in-real-life-signed.pdf) or [from Google Drive](https://drive.google.com/file/d/1QSGh-Io1zGbamb4VmqYB4JAdKZY1wncO/view?usp=sharing)), open it in a PDF reader that checks signatures — a browser only shows the picture — and click the stamp. A panel opens. Compare it with column B:

- ✓ **"Signature valid"** — the box opened: locked by the author, not one character changed since.
- **"Signed by: МАРКО МИЛИЋ 5317655384309001"** — the name on the opening key, as the registry wrote it (Cyrillic, plus the key's number).
- ⚠ **"Issuer unknown"** — your device has never met the registry that labelled this key (EID RS Sign, the Serbian eID authority). The lock is fine; the label is what your device cannot vouch for. Import the registry's root certificate and the yellow goes away. That is a story for the next page.
- ✗ **Change one letter and reopen** — the tick disappears. The box won't open. I tried it: one letter, invisible on the page, and the reader reports "digest mismatch".
- **"Format not supported"** — neither ✓ nor ✗. An old reader that never tried the key. Use a newer one.

## What the lock proves

- **Who wrote it** — the box was locked with a key that exists in one copy, and only the owner has it. Nobody else could have locked it.
- **Nothing changed** — one altered comma and the box won't open.
- **They can't deny it** — "someone else must have locked it" is not available as an excuse; there is no one else.

## What it does not do

- **Hide anything** — the box is glass; a signed document is not a secret one.
- **Judge the note** — it proves the author, not that the instruction is wise.

## One habit to take away

When a document arrives, ask one question: *was this box locked — and did it open with the right key?* Your phone asks it for every app update. Your browser asks it for every padlock. For the PDFs in your inbox, you have to click the stamp yourself.

---

![The one-page PDF](/assets/img/digital-signature-glass-box-page.webp)

*The one-page PDF version of this article is digitally signed with a qualified electronic signature (eUprava "Potpis u klaudu"). [Download it](/assets/pdf/what-does-a-digital-signature-actually-look-like-in-real-life-signed.pdf) and click the stamp.*
