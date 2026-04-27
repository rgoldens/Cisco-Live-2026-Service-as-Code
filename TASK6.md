← [Task 5](TASK5.md) | [Lab Guide](LAB-GUIDE.md) | [Git Primer](Git-Primer.md)

---

# Task 6: Push Your Completed Work to GitHub

## Objective

Save your completed lab work by committing your changes and pushing them to
GitHub on your student branch. This is the final step in the Infrastructure as
Code workflow — your network configuration changes are now version-controlled
and stored in a central repository.

> **New to Git?** If you haven't read it already, the [Git Primer](Git-Primer.md)
> explains the concepts behind the commands in this task.

---

## What You Changed

Over the course of Tasks 1–5, you edited several files — filling in TODO
placeholders with real values and deploying them to the network. Here's a
summary of what you modified:

| File | What You Changed |
|------|-----------------|
| `ce-access-vlan.yml` | Task 1 — VLAN IDs and names for n9k-ce01 and n9k-ce02 |
| `igp-pe-ce.yml` | Task 2 — IS-IS configuration for NX-OS and IOS-XE devices |
| `inter-as-option-a.yml` | Task 3 — BGP VPN, XRd config, and cross-routes |
| `task4-terraform/*.tf` | Task 4 — Terraform variables for IOS-XR via gNMI |
| `task5-terraform/*.tf` | Task 5 — Terraform variables for IOS-XE via RESTCONF |

> **Note:** You may have modified additional files during the lab. The commands
> below will show you exactly what changed — Git tracks everything.

---

## Step 1: Review Your Changes

Before committing, see what Git thinks has changed. Run:

```bash
cd ~
git status
```

This shows two categories:

- **Modified files** — files that existed in the repo and you edited (your playbooks
  and Terraform configs)
- **Untracked files** — new files created during the lab (like `terraform.tfstate`)
  that Git hasn't seen before

> **Tip:** Red filenames mean the file has changes that haven't been staged yet.
> After you run `git add`, they turn green.

---

## Step 2: Stage Your Changed Files

Tell Git which files to include in your commit. Stage all the playbooks and
Terraform files you modified:

```bash
git add ce-access-vlan.yml igp-pe-ce.yml inter-as-option-a.yml
```

> **Why not `git add .` (add everything)?** In a real workflow, you should be
> deliberate about what you commit. Adding everything can accidentally include
> temporary files, state files with sensitive data, or other artifacts that
> don't belong in version control. Listing files explicitly is a good habit.

Verify what's staged:

```bash
git status
```

You should see your files listed under **"Changes to be committed"** in green.

---

## Step 3: Commit Your Changes

Create a commit — a snapshot of your staged changes with a message describing
what you did:

```bash
git commit -m "Completed Tasks 1-5: VLAN, IS-IS, BGP VPN, Terraform IOS-XR and IOS-XE"
```

> **What makes a good commit message?** Describe *what* changed and *why* in
> one line. Future you (or your teammate) should be able to read the message
> and understand the change without opening the files.

---

## Step 4: Push to GitHub

Upload your branch to the remote repository on GitHub:

```bash
git push origin student-XX
```

Replace `XX` with your pod/seat number — the same branch name you created in
the [Lab Access](LAB-ACCESS.md) setup.

> **First push?** Git may prompt you for credentials. Use the shared GitHub
> username and token provided by your proctor.

Expected output:

<pre>
Enumerating objects: 8, done.
Counting objects: 100% (8/8), done.
Delta compression using up to 4 threads
Compressing objects: 100% (5/5), done.
Writing objects: 100% (5/5), 1.23 KiB | 1.23 MiB/s, done.
Total 5 (delta 3), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
To https://github.com/rgoldens/Cisco-Live-2026-Service-as-Code.git
 * [new branch]      student-XX -> student-XX
</pre>

---

## Step 5: Verify on GitHub

Open a browser and navigate to the repository:

**https://github.com/rgoldens/Cisco-Live-2026-Service-as-Code**

1. Click the **branch dropdown** (it says `main` by default)
2. Find your branch (`student-XX`) in the list
3. Click on it — you should see your modified files with the changes you made

You can click on any file to see the exact values you filled in. This is your
completed lab work, stored permanently in version control.

---

## Checkpoint

- [ ] `git status` showed your modified files
- [ ] `git add` staged the playbooks you changed
- [ ] `git commit` created a snapshot with a descriptive message
- [ ] `git push` uploaded your branch to GitHub
- [ ] Your branch is visible on GitHub with your changes

---

## What You Just Did

You completed the full Infrastructure as Code lifecycle:

1. **Pulled code from a central repo** (git clone)
2. **Edited configuration as code** (filled in YAML/HCL variables)
3. **Deployed to live infrastructure** (ansible-playbook / terraform apply)
4. **Verified the deployment worked** (ping tests, show commands)
5. **Pushed your changes back to the repo** (git commit & push)

In a production environment, step 3 would typically be automated — a CI/CD
pipeline (like GitHub Actions) would detect your push and deploy the changes
automatically. The manual deployment you did in this lab is the same work that
pipeline would do, just triggered by hand instead of by a git push.

**Congratulations — you've completed the lab!**

---
