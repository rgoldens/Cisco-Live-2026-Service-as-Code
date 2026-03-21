# Instructor Slides & Script — 15 Minutes

## Delivery Overview
- **Total time:** 15 minutes (no demos, no interactive polls)
- **Audience:** 30 students (beginner-level, no from-scratch coding)
- **Goal:** Context + excitement, then jump into hands-on labs
- **Assume:** Students have read TOPOLOGY_NOTES.md and HYBRID_APPROACH.md beforehand

---

## Script (Read Aloud — ~15 Minutes)

### **SLIDE 1: Title (30 seconds)**
```
Cisco Live 2026
Service as Code Lab
Infrastructure as Code Fundamentals
30 Attendees, 4 Hours, 1 Topology
```

**What you say:**
"Good morning, everyone. Welcome to Service as Code — a hands-on lab where you'll learn 
how network engineers actually do their jobs in 2026. Not manually typing commands on 
30 devices. Not hope-driven networking. Code-driven networking.

Today you're going to build a realistic network service from scratch using the tools 
that Netflix, Amazon, and Google use at scale: Infrastructure as Code."

---

### **SLIDE 2: The Problem (2 minutes)**
```
Traditional Network Operations
┌─────────────────────────────┐
│ Monday 3 AM (on-call)       │
│ Network down. Customer lost.│
│                             │
│ Question: What changed?      │
│ Answer: Nobody knows         │
└─────────────────────────────┘
```

**What you say:**
"Here's a real scenario. It's Monday morning, 3 AM. Your network is down. A customer 
is losing revenue. You check the configs on your router, and something looks different 
than you remember.

Question: What changed? 
Answer: Nobody knows. Because someone made a manual change 6 months ago to fix an 
emergency. They didn't document it. They didn't tell anyone. It's still there, waiting 
to break things.

This happens at every company. Manual changes, undocumented, untracked, uncontrolled. 
And when things break, it takes hours to even understand what happened.

This is the problem we're solving today."

---

### **SLIDE 3: The Solution (2 minutes)**
```
Infrastructure as Code (IaC)
┌──────────────────────────────────┐
│ Service Definition (YAML)         │
│ ↓                                │
│ Automation (Ansible/Terraform)   │
│ ↓                                │
│ Network Configuration (Real)     │
│ ↓                                │
│ Source Control (Git)             │
└──────────────────────────────────┘
```

**What you say:**
"Instead of clicking, instead of SSHing to devices and typing commands, we define 
what we want as code. In this case, YAML: simple, human-readable, version-controlled.

This code says: 'I want Customer A to have a VPN with route-target 65000:100, 
interface GigabitEthernet3, IP 192.168.100.1.' 

Then Ansible reads that code and makes it happen. No manual commands. No mistakes. 
Same configuration, every time, on every device.

And here's the key part: it's in Git. Your network configuration has a full audit 
trail. Who changed what, when, and why. You can roll back. You can compare versions. 
You can code review it before it even touches a device.

When that Monday 3 AM emergency happens, you can instantly see what changed, who 
changed it, and undo it with one command."

---

### **SLIDE 4: Today's Architecture (2 minutes)**
```
LTRATO-1001 Topology
             P-Routers (IOS-XR)
            /              \
           /                \
       PE Routers          PE Routers
      (IOS-XE)            (IOS-XE)
         |                   |
         |                   |
      CE Switches         CE Switches
       (NX-OS)             (NX-OS)
         |                   |
      Clients    ←→    Clients
```

**What you say:**
"This is your topology. It's a small service provider network with a core (those are 
route reflectors), provider edge routers, customer edge switches, and test clients.

10 nodes, all running in Docker containers, all pre-configured with the underlay 
(the foundation). Your job is to provision the overlay — the customer services.

You're going to use Ansible to provision real L3VPN and EVPN services on real devices. 
Not simulations. Not fake configs. Real bird-in-hand networking.

Then you're going to use Terraform to show what happens when someone makes an 
unauthorized change — because in production, that always happens. And Terraform will 
detect it and automatically fix it. That's the power of IaC."

---

### **SLIDE 5: Your 4-Hour Journey (2 minutes)**
```
Time          What You'll Do
────────────────────────────────
0:00-0:15     These slides (you're doing it now)
0:15-0:30     Deploy topology (containerlab)
0:30-1:00     Verify everything works
1:00-2:00     Provision CustomerA + CustomerB L3VPN (Ansible)
2:00-3:30     Test, validate, and troubleshoot
3:30-4:00     Terraform drift detection (see how it catches unauthorized changes)
```

**What you say:**
"Here's your day. Fifteen minutes of me talking — that's it. Then 225 minutes of 
you building and learning.

You'll start by deploying the topology. That takes 15-20 minutes. While containers 
are booting, you'll verify connectivity.

Then you'll run Ansible playbooks that provision two customer VPNs. You'll see the 
configs render right before your eyes. You'll SSH to devices and verify they worked.

Then you'll do something that most IaC labs don't do: you'll make unauthorized changes 
to a device. Breaking things intentionally. Then Terraform will catch it and fix it 
automatically. You'll understand why IaC is non-negotiable in production.

Any questions during the day, raise your hand. We're here to help."

---

### **SLIDE 6: Why This Matters (1.5 minutes)**
```
Career Impact
┌──────────────────────────────┐
│ IaC Engineer: $150K+/year    │
│ Network Automation: $120K+   │
│ DevOps: $140K+               │
│                              │
│ Hiring shortage: 40K+ jobs   │
└──────────────────────────────┘
```

**What you say:**
"One more thing before we start. These skills are valuable. Really valuable.

Companies are desperately hiring people who understand infrastructure as code. 
Salaries for IaC engineers are 150K plus annually. DevOps roles go to engineers 
who can code their infrastructure.

The traditional 'network operator' role is disappearing. The future is engineers 
who treat infrastructure like software: version controlled, tested, automated, reliable.

In 4 hours today, you're going to learn what those engineers know. You're going to 
graduate from this lab and understand how to do your job in 2026.

Let's get started."

---

### **SLIDE 7: Final Slide (1 minute)**
```
Let's Build

Exercise 1: Deploy Topology
Exercise 2: Provision CustomerA
Exercise 3: Provision CustomerB
Exercise 4: Validate & Test
Exercise 5+: Terraform & Drift Detection

Documentation: docs/HANDS-ON_EXERCISES.md
Instructor Support: Ask anytime
```

**What you say:**
"Alright. Open your lab environment. Read the first exercise in the lab guide. 
I'll be here to help you through every step.

Let's build something cool."

---

## Delivery Tips

### **Before You Start**
- [ ] Test your internet connection and Cisco Live presentation laptop
- [ ] Have your repo cloned and ready to show one screenshot (optional)
- [ ] Confirm all 30 students have their lab environment open
- [ ] Display HANDS-ON_EXERCISES.md on screen or have students open it on their machines

### **During the Presentation**
- **No live typing.** Stick to slides.
- **No hands-on demos.** Those will happen during exercises with full support.
- **Make eye contact.** Engage with the audience.
- **Pace:** Aim for exactly 15 minutes. Time yourself in rehearsal.
- **Enthusiasm:** This is the tone-setting moment. Convey excitement about IaC, not lecturing.

### **After Slide 7 (T = 15:00)**
- Immediately transition to "Everyone open docs/HANDS-ON_EXERCISES.md Exercise 1"
- Stay available for questions
- Monitor progress but don't jump in unless asked
- Students should be independent and self-paced

---

## Common Questions You Might Get (During or After)

**Q: "Will this work on our production network?"**
A: "That's a great question, and the answer is yes — but only after lots of testing. 
This is exactly how Netflix, Amazon, and Cisco themselves deploy infrastructure. You 
start with a test network (like you have today), verify it works, then apply the 
patterns to production."

**Q: "What if Ansible or Terraform breaks?"**
A: "It happens. That's why we have HANDS-ON_EXERCISES.md with step-by-step 
instructions. Every exercise has troubleshooting tips. And I'm here to help."

**Q: "Can I use this at my company?"**
A: "Absolutely. The patterns you learn today are portable. Swap out the Cisco commands 
for your vendor, and the same workflow applies. Ansible works with Juniper, Arista, 
Aruba, etc. Same principles."

---

## Slide Deck (Simple Alternative)

If you prefer plain text or want to use a slide tool, here's the minimal version:

1. **Title:** Service as Code Lab
2. **Problem:** Manual changes, uncontrolled, break things
3. **Solution:** Code, automation, version control
4. **Topology:** 10 nodes, L3VPN, EVPN
5. **Timeline:** 0-15min slides, 15-240min exercises
6. **Careers:** IaC engineers earning $150K+
7. **Action:** Open HANDS-ON_EXERCISES.md, Exercise 1

That's it. Simple. Clear. 15 minutes.

