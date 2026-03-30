# Instructor Setup and Deployment Guide

**Status:** Everything is ready. This guide tells you what to verify before students arrive.

---

## 📋 Before Students Arrive (30 minutes total)

### ✅ Prerequisites Checklist

- [ ] Lab environment is running (10 devices in ContainerLab)
- [ ] SSH access to all devices works
- [ ] Ansible is installed on your control machine
- [ ] You have access to `/tmp/Cisco-Live-2026-Service-as-Code/lab-exercises/`

---

## 🚀 Step 1: Run the One-Time Infrastructure Verification (5 minutes)

**This is the most important step.** Run this ONCE before students arrive:

```bash
cd /tmp/Cisco-Live-2026-Service-as-Code/lab-exercises
./INSTRUCTOR_SETUP.sh
```

**What it does:**
- ✅ Tests SSH to all 6 network devices
- ✅ Verifies ansible.cfg SSH options are correct
- ✅ Tests Ansible connectivity
- ✅ Validates playbook syntax
- ✅ Reports: All ready ✓ or lists what needs fixing

**Expected output:**
```
✓ Testing CSR-PE01... ✓ OK
✓ Testing CSR-PE02... ✓ OK
✓ Testing N9K-CE01... ✓ OK
✓ Testing N9K-CE02... ✓ OK
✓ Testing XRd-P01... ✓ OK
✓ Testing XRd-P02... ✓ OK
...
✓ ALL CHECKS PASSED
Lab infrastructure is ready for students!
```

**If anything fails:**
- It will tell you exactly what failed
- Fix that specific issue (usually SSH or device reachability)
- Run the script again until it passes

---

## 📣 Step 2: Give Students the Right Materials (2 minutes)

**Direct students to:**
- 📖 [README_STUDENTS.md](README_STUDENTS.md) — Their quickstart guide
- 📖 [Task1/README.md](Task1/README.md) — Task 1 instructions
- 📖 [Task2/README.md](Task2/README.md) — Task 2 instructions

**Do NOT give students:**
- ❌ PRE-LAB-CHECKLIST.md (instructor-only)
- ❌ SSH_SETUP_GUIDE.md (instructor-only)
- ❌ INSTRUCTOR_SETUP.sh (instructor-only)
- ❌ COMPLETE_VALIDATION_REPORT.md (reference, not needed for students)
- ❌ FULL_STUDENT_TEST.md (reference, not needed for students)

---

## 🎓 Step 3: Students Execute Tasks (40 minutes)

Students simply run three playbooks in order:

```bash
cd /tmp/Cisco-Live-2026-Service-as-Code/lab-exercises

# Task 1 (~15 min)
ansible-playbook -i inventory/hosts.yml Task1/playbooks/01_task1_vlans.yml

# Task 2a (~10 min)
ansible-playbook -i inventory/hosts.yml Task2/playbooks/01_deploy_isis_csr.yml

# Task 2b (~10 min)
ansible-playbook -i inventory/hosts.yml Task2/playbooks/02_deploy_isis_nxos.yml
```

Students should see all green checkmarks. That's success.

---

## 🔧 Troubleshooting (If Students Report Errors)

### Students see: `Connection refused` or `Timeout`

**Cause:** Device unreachable  
**Fix:** 
1. Run `./INSTRUCTOR_SETUP.sh` again to verify your infrastructure
2. Check if the device is powered on
3. Check if SSH port is open: `nmap -p 22 172.20.20.20`

### Students see: `Permission denied (publickey)`

**Cause:** SSH credentials wrong  
**Fix:**
1. Verify credentials in `inventory/hosts.yml` match device config
2. Test manually: `ssh admin@172.20.20.20`
3. Check `~/.ssh/` permissions (should be 700)

### Students see: `No module named ansible`

**Cause:** Ansible not installed on student's machine  
**Fix:** Install Ansible on student's control machine

### Students see: `failed=1` (red error in playbook)

**Cause:** Device configuration issue  
**Fix:**
1. Check device is in correct state: SSH to device manually
2. Review the playbook error message (it's usually descriptive)
3. If playbook is idempotent, running it again may help clean up partial configs
4. Last resort: Reset device and re-run playbook

### "It worked the first time but failed the second time"

**This shouldn't happen** — all playbooks are idempotent. If it does:
1. Check if device state changed (e.g., someone else modified running-config)
2. Try running the playbook again
3. If it still fails, check manual device configuration

---

## 📚 What's Been Pre-Configured for You

**ansible.cfg**
- SSH options pre-configured for CSR legacy algorithm support
- Gathering strategy optimized for speed
- Host key checking disabled for lab environment

**inventory/hosts.yml**
- All device IPs and usernames configured
- SSH options set at both global and group level
- Backup SSH args for edge cases

**Playbooks**
- Task 1: VLAN configuration (well-tested, idempotent)
- Task 2 CSR: ISIS configuration via direct SSH (works around CSR KEX limitations)
- Task 2 N9K: ISIS configuration via standard network_cli (standard Ansible)

**Documentation**
- Student guides have NO SSH/infrastructure references
- Instructor guides contain all troubleshooting info
- Test reports show all playbooks pass

---

## 🎯 Your Instructor Responsibilities

**Before Students Arrive:**
1. ✅ Run `./INSTRUCTOR_SETUP.sh` → Verify everything works
2. ✅ Print or distribute `README_STUDENTS.md`
3. ✅ Test in the lab environment once to be familiar with it
4. ✅ Keep `PRE-LAB-CHECKLIST.md`, `SSH_SETUP_GUIDE.md`, and `INSTRUCTOR_SETUP.sh` handy

**During Class:**
1. ✅ Students follow `README_STUDENTS.md`
2. ✅ Run tasks and see green checkmarks
3. ✅ If issues arise, you have this troubleshooting guide
4. ✅ Keep SSH complexity hidden from students

**Success Metric:**
- All students run 3 playbooks
- All playbooks complete without errors
- All students see green checkmarks
- Students learn Ansible automation, not SSH debugging

---

## 📝 One-Time Setup Checklist

Before your first class with students:

- [ ] Copy lab-exercises to `/tmp/Cisco-Live-2026-Service-as-Code/lab-exercises/`
- [ ] Run `./INSTRUCTOR_SETUP.sh` and verify it passes
- [ ] Review `README_STUDENTS.md` — this is what students will see
- [ ] Have `SSH_SETUP_GUIDE.md` nearby for reference
- [ ] Bookmark the "Troubleshooting" section above
- [ ] Print one copy of `README_STUDENTS.md` per student (or email it)

---

## ✅ Deployment Checklist (Day of Class)

30 minutes before students arrive:

- [ ] Lab environment is running
- [ ] Run `./INSTRUCTOR_SETUP.sh` (should pass in <30 seconds)
- [ ] All checks pass? → Students are ready ✓
- [ ] Any checks fail? → Fix before students arrive

---

## 🎓 Expected Student Experience

**Student perspective:**
1. Receive `README_STUDENTS.md`
2. Run 3 playbooks in sequence
3. See all green checkmarks
4. Learn about Ansible network automation
5. Zero knowledge of SSH, infrastructure, or troubleshooting

**Result:**
- 40 minutes of productive learning
- No frustration with infrastructure issues
- Focus on Ansible skills, not debugging

---

## 📞 Need Help?

**If playbooks fail:**
- Check this troubleshooting section first
- Review `SSH_SETUP_GUIDE.md` for deep-dive technical context
- Review `COMPLETE_VALIDATION_REPORT.md` — previous test results show what should work

**If you get stuck:**
- Re-run `./INSTRUCTOR_SETUP.sh` to validate infrastructure
- Manual SSH test: `ssh admin@172.20.20.20 "show version"`
- Compare your output to `FULL_STUDENT_TEST.md` (previous successful run logs)

---

**You're ready to teach!** 🚀
