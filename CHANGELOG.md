# CHANGELOG

## Unreleased Changes

## 2026-06-10
- Fix: Properly highlight selected day when it occurs in the current month and is not the current day. Previously when
accessing the calendar for the current month, the current date was always highlighted even if the selected day was an earlier
date in the month.
- Enhancement: Close the calendar tray before navigating page to the selected date.
- Enhancement: Improve styling of `passwords#new` and `passwords#edit` pages for consistency.
- Fix: Prevent authenticated users from accessing the Sign-up and Sign-in forms.
- Enhancement: Add a link to the reset password form to user's profile page.
- Fix: Fix inconsistency in header height between /day/* and /profile views.
- Enhancement: Add an Account Management section to the Profile page.

## 2026-06-09 - Initial Release
Changes up to this point constitute the initial stable (ish), public release of the weight-tracker code.  All basic features are expected to be working, based on my own personal use during alpha-development for the past week or so.

### Features:
- User account registrations & login
- Personalized daily calorie goals
- Personalized timezone support
- Day-based calorie & weight-tracking
- Personalized profile page for managing preferences and viewing (admittedly lame, for now) stats
- Day-by-day or Calendar-based date navigation
