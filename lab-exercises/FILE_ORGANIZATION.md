# Lab File Organization Guide

**Quick Reference: What to Give to Students vs. Keep as Instructor**

---

## 📖 GIVE TO STUDENTS

**These files are student-friendly and contain NO references to SSH, infrastructure complexity, or troubleshooting:**

- **[README_STUDENTS.md](README_STUDENTS.md)** ⭐ START HERE
  - Simple list of 3 playbooks to run
  - Expected success indicators
  - Links to Task1 and Task2 deep-dive guides

- **[Task1/README.md](Task1/README.md)**
  - Step-by-step guide for VLAN configuration
  - Explains Ansible concepts (inventory, variables, playbooks)
  - No SSH or infrastructure references

- **[Task2/README.md](Task2/README.md)**
  - Step-by-step guide for ISIS configuration
  - Covers CSR and N9K routers
  - No SSH or infrastructure references

---

## 🔐 KEEP AS INSTRUCTOR (Never show to students)

**These contain SSH configuration, troubleshooting, and infrastructure details:**

- **[INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md)** ⭐ READ THIS FIRST
  - What to do before students arrive
  - How to run the pre-flight check
  - Troubleshooting guide
  - Deployment checklist

- **[INSTRUCTOR_SETUP.sh](INSTRUCTOR_SETUP.sh)**
  - One-time infrastructure verification script
  - Run this before students arrive
  - Reports pass/fail for all connectivity checks

- **[PRE-LAB-CHECKLIST.md](PRE-LAB-CHECKLIST.md)** (marked "INSTRUCTOR ONLY")
  - Step-by-step manual SSH tests
  - Why CSR needs legacy KEX algorithms
  - Ansible connectivity verification
  - Use this to debug if INSTRUCTOR_SETUP.sh fails

- **[SSH_SETUP_GUIDE.md](SSH_SETUP_GUIDE.md)**
  - Deep technical explanation of SSH KEX issues
  - How playbooks handle CSR legacy algorithms
  - Why CSR playbook uses direct SSH instead of network_cli
  - Reference material for instructor understanding

- **[COMPLETE_VALIDATION_REPORT.md](COMPLETE_VALIDATION_REPORT.md)**
  - Previous test results (proof everything was tested)
  - Use as reference if things go wrong
  - Confirms all playbooks are production-ready

- **[FULL_STUDENT_TEST.md](FULL_STUDENT_TEST.md)**
  - Raw playbook execution logs
  - Show command outputs from devices
  - Use for comparison if student setup differs

---

## 🔄 STUDENT WORKFLOW

```
Student receives
      ↓
README_STUDENTS.md
      ↓
     Reads "Run these 3 playbooks"
      ↓
    Task 1: VLAN deployment
      ↓
    Task 2a: ISIS on CSR
      ↓
    Task 2b: ISIS on N9K
      ↓
   All green checkmarks = Success ✓
```

**Duration:** ~40 minutes  
**SSH complexity they see:** 0%  
**Learning focus:** 100% Ansible network automation  

---

## 💼 INSTRUCTOR WORKFLOW

### Before Students Arrive

```
Review INSTRUCTOR_GUIDE.md
      ↓
Run INSTRUCTOR_SETUP.sh
      ↓
All checks pass → You're done ✓
      ↓
Give README_STUDENTS.md to students
```

**Duration:** 5 minutes  
**SSH complexity:** Handled in setup script  
**Your focus:** Verify infrastructure works  

### If Students Report Issues

```
Student says: "It failed!"
      ↓
Refer to Troubleshooting in INSTRUCTOR_GUIDE.md
      ↓
Not in guide? Check SSH_SETUP_GUIDE.md for context
      ↓
Still stuck? Refer to FULL_STUDENT_TEST.md for comparison
```

---

## 📁 Complete File Structure

```
lab-exercises/
│
├── 📖 STUDENT MATERIALS (Give to Students)
│   ├── README_STUDENTS.md                     ⭐ Start here
│   ├── Task1/README.md
│   ├── Task2/README.md
│   ├── Task1/playbooks/01_task1_vlans.yml
│   ├── Task2/playbooks/01_deploy_isis_csr.yml
│   └── Task2/playbooks/02_deploy_isis_nxos.yml
│
├── 🔐 INSTRUCTOR MATERIALS (Keep Private)
│   ├── INSTRUCTOR_GUIDE.md                    ⭐ Read first
│   ├── INSTRUCTOR_SETUP.sh
│   ├── PRE-LAB-CHECKLIST.md
│   ├── SSH_SETUP_GUIDE.md
│   ├── COMPLETE_VALIDATION_REPORT.md
│   ├── FULL_STUDENT_TEST.md
│   └── FINAL_PRODUCTION_SUMMARY.md
│
├── 📋 SUPPORTING FILES (Needed but neutral)
│   ├── ansible.cfg
│   ├── inventory/hosts.yml
│   ├── inventory/group_vars/
│   ├── Task1/group_vars/nxos.yml
│   ├── Task2/group_vars/csr.yml
│   └── Task2/group_vars/nxos.yml
│
└── 📜 REFERENCE (You are here)
    └── FILE_ORGANIZATION.md                   This file
```

---

## ✅ Deployment Steps

### For Instructor (Before Class)

1. **Review:** `INSTRUCTOR_GUIDE.md` (5 min)
2. **Run:** `./INSTRUCTOR_SETUP.sh` (2 min)
3. **Share:** `README_STUDENTS.md` with students

### For Students (During Class)

1. **Read:** `README_STUDENTS.md` (5 min)
2. **Run:** 3 playbooks (~35 min)
3. **Verify:** All green checkmarks ✓

### Result

- ✅ Students learn Ansible
- ✅ Infrastructure is transparent
- ✅ No SSH confusion
- ✅ Professional lab experience

---

## 🎯 Key Principle

**Students should NEVER see or think about:**
- SSH algorithms
- KEX negotiation
- Infrastructure complexity
- Troubleshooting procedures
- These files: PRE-LAB-CHECKLIST, SSH_SETUP_GUIDE, INSTRUCTOR_SETUP

**Students should ONLY see:**
- README_STUDENTS.md
- Task1/README.md
- Task2/README.md
- The three playbooks they execute

---

## 📞 Quick Reference

| Question | Answer |
|----------|--------|
| What do I (instructor) read first? | [INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md) |
| What do students read first? | [README_STUDENTS.md](README_STUDENTS.md) |
| How do I verify infrastructure? | Run `./INSTRUCTOR_SETUP.sh` |
| What if something fails? | Check INSTRUCTOR_GUIDE.md troubleshooting section |
| What do students never need to know? | SSH, infrastructure details, troubleshooting |
| Can I show students SSH_SETUP_GUIDE.md? | No, keep it private |
| Should students run INSTRUCTOR_SETUP.sh? | No, you run it before they arrive |

---

**Everything is organized. You're ready to deploy!** 🚀
