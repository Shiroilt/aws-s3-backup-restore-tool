# 🗄️ AWS S3 Backup & Restore Tool (Beginner Friendly)

A complete **backup + restore system** using AWS S3, designed for **non-technical users**.

---

# 🚀 📌 Real-Life Scenario (Why this project?)

Imagine this:

* You want to **format your laptop / reinstall OS**
* You are afraid of **losing important data**
* External drives are:

  * Slow ❌
  * Can fail ❌
  * Not always available ❌

---

# 💡 Solution

This project gives you:

### 🔹 Backup Script

Uploads your files to
👉 Amazon S3

### 🔹 Restore Script

Restores all files back after formatting

---

# 🧠 How It Works

```text
Your System
   ↓
Backup Script
   ↓
AWS S3 (Cloud Storage)
   ↓
Restore Script
   ↓
New System (After Format)
```

---

# 📦 Project Structure

```bash
backup_to_s3.sh
restore_from_s3.sh
README.md
```

---

# ⚙️ Prerequisites (MUST)

Before using:

### 1. AWS Account

Create here: https://aws.amazon.com

---

### 2. Create S3 Bucket

Go to AWS → S3 → Create bucket

Example:

```text
backupmakepc
```

---

### 3. Create IAM User

Go to:
👉 AWS IAM

Steps:

* Create User
* Enable **Programmatic Access**
* Attach S3 permissions

---

### 4. Get Credentials

You will get:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

---

# 🧪 STEP 1 — BACKUP YOUR DATA

---

## 🔹 Step 1: Open Terminal

---

## 🔹 Step 2: Set AWS Credentials

```bash
export AWS_ACCESS_KEY_ID=YOUR_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET
export AWS_DEFAULT_REGION=us-east-1
```

---

## 🔹 Step 3: Give Permission to Script

```bash
chmod +x backup_to_s3.sh
```

---

## 🔹 Step 4: Run Script

```bash
./backup_to_s3.sh
```

👉 OR (safe way)

```bash
bash backup_to_s3.sh
```

---

## 🔹 Step 5: Enter Folder Paths

Example:

```text
~/Documents
~/Downloads
done
```

---

## ✅ Backup Result

Files uploaded to:

```text
s3://backupmakepc/pc-backup/TIMESTAMP/
```

---

# 💣 STEP 2 — FORMAT SYSTEM

---

## 🔹 If using EC2

Go to:
👉 Amazon EC2

Steps:

* Select instance
* Click:

```text
Instance state → Terminate instance
```

---

## 🔹 If local PC

Format normally

---

# 🔄 STEP 3 — RESTORE DATA

---

## 🔹 Step 1: Open new system terminal

---

## 🔹 Step 2: Set credentials again

```bash
export AWS_ACCESS_KEY_ID=YOUR_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET
export AWS_DEFAULT_REGION=us-east-1
```

---

## 🔹 Step 3: Give permission

```bash
chmod +x restore_from_s3.sh
```

---

## 🔹 Step 4: Run restore (IMPORTANT)

```bash
sudo -E bash restore_from_s3.sh
```

---

## ✅ Restore Result

Files restored to original paths like:

```text
/home/user/Documents
/home/user/Downloads
```

---

# ⚠️ COMMON ERRORS & SOLUTIONS

---

## ❌ Error 1: AWS CLI not found

```text
Package 'awscli' has no installation candidate
```

✅ Fix:

* Script auto-installs AWS CLI

---

## ❌ Error 2: Access Denied

```text
AccessDenied
```

✅ Fix:

* Check IAM permissions
* Check bucket name

---

## ❌ Error 3: Invalid Access Key

```text
InvalidAccessKeyId
```

✅ Fix:

* Re-enter credentials

---

## ❌ Error 4: Syntax error near `do`

```text
syntax error near unexpected token 'do'
```

✅ Fix:

```bash
sed -i 's/\r$//' backup_to_s3.sh
```

---

## ❌ Error 5: Nothing restored

✅ Fix:

* Check S3 bucket manually
* Verify region

---

## ❌ Error 6: Credentials lost in sudo

✅ Fix:

```bash
sudo -E bash restore_from_s3.sh
```

---

# 🔒 SECURITY (IMPORTANT)

❌ Never do:

* Store keys in script
* Upload keys to GitHub

✅ Always:

* Use environment variables
* Rotate keys regularly

---

# 🎯 USE CASES

* 💻 PC formatting
* 🔄 System migration
* ☁️ Cloud backup
* 🧪 Testing environments
* 🆘 Disaster recovery

---

# 🚀 FUTURE IMPROVEMENTS

* Zip compression (faster upload)
* GUI tool
* Scheduled backups
* Multi-user support

---

# 👨‍💻 AUTHOR

Built as a practical cloud & DevOps learning project.

---

# ⭐ SUPPORT

If you like this project:

* Star ⭐ repo
* Share with others

---

# 🎉 FINAL NOTE

This is a **simple but powerful real-world backup system**
used in cloud engineering practices.
