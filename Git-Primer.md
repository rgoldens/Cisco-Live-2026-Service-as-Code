[Lab Guide](LAB-GUIDE.md) | [Reference Tables](REFERENCE.md) | [Ansible Primer](Ansible-Primer.md) | [Terraform Primer](Terraform-Primer.md) | [ContainerLab Primer](ContainerLab-Primer.md)

---

## Git Quick Primer

If you're new to Git, take a few minutes to read this section. You'll use Git at
the beginning and end of this lab — cloning the lab files to your server, and
pushing your completed work back to GitHub.

### What is Git?

Git is a **version control system** — it tracks every change you make to a set of
files, who made the change, and when. Instead of saving copies like
`playbook-final-v2-REAL.yml`, Git keeps a complete history of every version in a
single directory.

**Why does this matter for network automation?**

| Without version control | With Git |
|------------------------|----------|
| "Who changed the BGP config last Tuesday?" | `git log` shows every change with timestamps and authors |
| "What did the config look like before it broke?" | `git diff` shows exactly what changed between any two versions |
| "Can we roll back to yesterday's working config?" | `git checkout` restores any previous version instantly |
| Config files emailed between engineers | One shared repository — everyone works from the same source of truth |

In an Infrastructure as Code workflow, your network configuration **lives in Git**,
not on the devices. The devices receive their config from the code. This is the
pattern you'll practice in this lab: edit files in a repo, then deploy them to the
network.

### Key Concepts

| Concept | What It Means |
|---------|--------------|
| **Repository (repo)** | A project folder tracked by Git — contains your files plus their full change history |
| **Clone** | Download a copy of a remote repository to your local machine |
| **Branch** | A parallel version of the repo. You'll work on your own branch (`student-XX`) so your changes don't collide with other students |
| **Stage** | Mark specific files to be included in your next commit (`git add`) |
| **Commit** | Save a snapshot of your staged changes with a message describing what you did |
| **Push** | Upload your commits from your local machine to the remote repository on GitHub |
| **Remote** | The copy of the repo hosted on GitHub (called `origin` by default) |

### The Commands You'll Use

There are only six Git commands you need for this lab:

```bash
# At the start — clone the repo and create your branch
git clone <REPO_URL>          # Download the repo to your server
git checkout -b student-XX    # Create and switch to your own branch

# At the end — save and upload your work
git add <file1> <file2>       # Stage the files you changed
git commit -m "Your message"  # Save a snapshot with a description
git push origin student-XX    # Upload your branch to GitHub
```

### How It Fits Into This Lab

```
┌─────────────┐     clone      ┌─────────────┐    deploy     ┌─────────────┐
│   GitHub     │ ───────────── │  Lab Server  │ ────────────  │  Network    │
│   (remote)   │               │  (edit here) │  ansible /    │  Devices    │
│              │  ◄─────────── │              │  terraform    │             │
└─────────────┘     push       └─────────────┘               └─────────────┘
```

1. **Clone** — You pull the lab repo from GitHub onto your dCloud server
2. **Edit** — You fill in the TODO placeholders in the playbook and Terraform files
3. **Deploy** — You run `ansible-playbook` or `terraform apply` to push config to devices
4. **Commit & Push** — You save your completed work back to GitHub on your student branch

The deploy step happens directly on the server — Git is not involved in deploying
config to devices. Git's job is to track your changes and store them in a central
place. In a production environment, the push-to-deploy step would be automated with
CI/CD pipelines (like GitHub Actions), but that's beyond the scope of this lab.

---
