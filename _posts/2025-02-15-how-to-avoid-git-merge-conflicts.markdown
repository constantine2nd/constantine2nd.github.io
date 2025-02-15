---
layout: post
title: How to Avoid Merge Conflicts on Git
date: 2025-02-15 05:28:20 +0100
description: You’ll find this post in your `_posts` directory. Go ahead and edit it and re-build the site to see your changes. # Add post description (optional)
img: merge-conflict.webp # Add image post (optional)
fig-caption: # Add figcaption (optional)
tags: [Git]
---
Git can resolve differences between branches/forks and merge them automatically. Unless, of course, there are conflicting sets of changes. These can be resolved, but we want to avoid Git merge conflicts altogether instead of dealing with them later on.

## The origin of merge conflicts
9Merge conflicts happen when you merge branches/forks that have competing commits, and Git needs your help to decide which changes to incorporate in the final merge. Often, they arise when people make different changes to the same line of the same file, or when one person edits a file and another person deletes the same file. In that case there are competing changes that Git can’t resolve and thus human intervention is required.


## The origin of merge conflicts

Merge conflicts happen when you merge branches/forks that have competing commits, and Git needs your help to decide which changes to incorporate in the final merge. Often, they arise when people make different changes to the same line of the same file, or when one person edits a file and another person deletes the same file. In that case there are competing changes that Git can’t resolve and thus human intervention is required.


## Why we want to avoid Git merge conflicts

In addition to human intervention it also implies reasoning about the code written by other people. This action is error prone and often time consuming. Also, we need to run tests again after merge conflict resolution. The table below shows a few benefits of an automatic merge.Common pitfalls

- Acting as a single user in a multi-user environment:
  - Poor collaboration in the workplace
  - You rarely pull other people’s changes
  - You rarely push your changes
- Always putting changes at the end of a file
- Organising imports
- Beautifying code outside of your changes
- Using large files


## Preventing Git merge conflicts

In order to avoid a merge conflict, all changes must be on different lines, or in different files, which makes the merge simple for computers to resolve. In other words, if a change introduces any ambiguity even at a single line of code an automatic merging is canceled and  the whole process must be finished manually.



## Prevention rules

1. Whenever it is possible, use a new file in preference to an existing one (the only ambiguity could happen if the same name and path of the file exist).
2. Do not always put your changes at the end of a file (decreases the probability of editing the same line of code).
3. Do not organise imports (decreases the probability of editing the same line of code).
4. Do not beautify code outside of your changes (decreases the probability of editing the same line of code).
5. Push and pull changes as often as you can (mitigates the distributed nature of Git).


## Conclusion

Despite this document being written from a developer’s perspective, it should be reasonably clear to non Git users. The concepts it covers can be applied to any version control system that tracks changes in source code.

Although this text does not provide a comprehensive guide on how to avoid merge conflicts, hopefully it can help to reduce the incidence of the dreaded “A merge conflict has occurred” message.
