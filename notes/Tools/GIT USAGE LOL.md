# Git Workflow Across Multiple PCs

## 🚀 Setting Up on the New PC

### 1. **Clone Your GitHub Repo to the New PC**

- Open **Git Bash** or **Command Prompt** on your second PC.
- Navigate to the folder where you want to store the repo.

```bash
cd path/to/your/folder
```

- Clone the repo from GitHub:

```bash
git clone https://github.com/yourusername/htb-notes.git
```

This will download the entire repository (your vault) to your second machine.

### 2. **Navigate to the Repo**

Once it's cloned, navigate into the project folder:

```bash
cd htb-notes
```

You should now have the same **HTB notes** folder set up as on your first PC.

---

## 🔄 Synchronizing Changes Between PCs

### 1. **Pull the Latest Changes (Before Starting Work)**

Before you start editing, **always pull the latest changes** from GitHub to make sure your local copy is up-to-date.

```bash
git pull origin main
```

This will fetch any changes that you made from the other PC and update your files locally.

---

### 2. **Make Your Changes and Add New Notes**

Start editing your notes as usual in Obsidian. You can add files, modify notes, or create new folders.

---

## 💾 Committing Changes

### 1. **Stage Your Changes**

After you make edits, it’s time to **stage** them for commit. This tells Git which files should be included in the next commit.

```bash
git add .
```

The `.` means you want to stage all the changes you made in the folder. If you want to stage a specific file, replace `.` with the file path:

```bash
git add path/to/your/file.md
```

### 2. **Commit Your Changes**

Once your changes are staged, commit them with a message:

```bash
git commit -m "Brief description of what you changed"
```

Make sure your commit message is clear. For example:
- "Add new notes for SQL Injection"
- "Update reverse shell section"

---

## 🌐 Pushing Changes to GitHub

### 1. **Push to GitHub**

After committing, **push** your changes to GitHub so the other PC can access them.

```bash
git push origin main
```

This sends your changes to the **main** branch of your GitHub repo.

---

## 🔁 On the Other PC

When you switch to the other machine:

1. **Pull the latest changes** before starting work.

```bash
git pull origin main
```

2. **Add, commit, and push changes** as needed, following the same workflow.

---

## 💡 Git Tips for Multiple PCs

- **Always pull before you start working** on the new PC to avoid merge conflicts.
- **Always commit** your work when you’re done, especially before switching machines.
- **Push frequently** to ensure both PCs have the most up-to-date notes.

---

## 🔄 Example Workflow

1. **On PC1**:  
   - Work on notes → `git add .` → `git commit -m "Updated reverse shell notes"` → `git push origin main`
   
2. **On PC2**:  
   - Run `git pull origin main` → Work on notes → `git add .` → `git commit -m "Fixed typo in tools section"` → `git push origin main`
