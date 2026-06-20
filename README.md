# Wiggy Wash — Sales Scorecard

A digital version of the Wiggy Wash physical tally card. Built with **Flutter**
(same proven stack as DiscGold) and ships as a **Web PWA** so the team can use it
on iPhone, Android, or desktop from one shared URL — no app store, no install.

It works **out of the box, fully offline**, storing data on the device
(localStorage). When you want managers to see every employee's submissions live
across devices, follow the **[Cloud sync](#cloud-sync-cross-device-optional)**
section to switch the single data seam over to Firebase.

---

## What it does

**On first open**, you enter your name and pick **Employee** or **Manager**
(saved to the device).

### Employee — Scorecard

A 1:1 of the paper card:

- Header: your **Name**, a **BA Goal** input, and an auto-calculated **BA Actual**.
- Three rose pill sections, each line item with a **+ / −** tally, running count,
  and live dollar total in a blue box:
  - **Membership Tally** — Full Service Protect ($49), Protect ($29), Shine ($23), Basic ($17)
  - **Single Washes** — Single Protect ($29), Single Shine ($23), Single Basic ($17), Economy ($11)
  - **Shop Sales** — Full Service, Wax Upsell (count only)
- Live **Shift Summary**: total memberships, single washes, shop sales,
  conversion (BA), and grand-total revenue.
- **Submit Shift** saves the card and opens a clean, screenshot-ready recap with
  a **Share to BA chat** button.

> **BA Actual / Conversion** = memberships ÷ (memberships + single washes). With a
> BA Goal of 40%, the recap shows a trophy when the goal is beaten.

### Manager — Team Dashboard

- Live team totals (revenue, memberships, singles, shop, team BA).
- Per-employee cards with badges and an expandable full breakdown.
- **Date picker** to review any day and **Reset day** to clear it.

---

## Run it on your Mac (development)

```bash
cd wiggywash/reference/app
flutter pub get
flutter run -d chrome
```

That launches the PWA in Chrome with hot reload (`r` to reload, `q` to quit).
You can also `flutter run` onto a plugged-in Android phone or iOS simulator —
the same code targets web, Android, and iOS.

## Build the web app

```bash
cd wiggywash/reference/app
flutter build web --release
```

The deployable site lands in `build/web/`.

## Try the production build locally

```bash
cd build/web
python3 -m http.server 8080
# open http://localhost:8080
```

## Add to Home Screen (PWA)

Open the deployed URL on a phone:

- **iPhone (Safari):** Share → *Add to Home Screen*.
- **Android (Chrome):** menu → *Install app* / *Add to Home screen*.

You get a full-screen app with the Wiggy Wash icon and a branded splash screen.

---

## Deploy (free hosting)

Any static host works because the build is just files in `build/web/`.

### Firebase Hosting (matches the spec's free tier)

```bash
npm install -g firebase-tools
firebase login
cd wiggywash/reference/app
firebase init hosting     # public dir: build/web  •  single-page app: Yes
flutter build web --release
firebase deploy --only hosting
```

### Alternatives

- **GitHub Pages:** push `build/web/` to a `gh-pages` branch (set
  `flutter build web --base-href "/<repo>/"`).
- **Netlify / Vercel / Cloudflare Pages:** drag-drop `build/web/` or point the
  build command at `flutter build web --release` with publish dir `build/web`.

---

## Cloud sync (cross-device) — optional

Out of the box, data is per-device (`shared_preferences` / localStorage). This is
perfect for a single device or a quick pilot. To make the manager dashboard
update **live from every employee's phone**, route the one data seam —
`lib/services/store.dart` — through Firestore:

1. **Create a Firebase project** and enable **Firestore** + **Anonymous Auth**.
2. Add packages:
   ```bash
   flutter pub add firebase_core cloud_firestore firebase_auth
   dart pub global activate flutterfire_cli
   flutterfire configure        # generates lib/firebase_options.dart
   ```
3. In `main()` (`lib/main.dart`), before `runApp`:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   await FirebaseAuth.instance.signInAnonymously();
   ```
4. In `lib/services/store.dart`, replace the bodies of `addSubmission`,
   `resetDay`, and submission loading with Firestore calls and a
   `snapshots()` listener that calls `notifyListeners()`. Everything else —
   every screen, model, and total — keeps working unchanged because they only
   talk to `Store`.

Suggested Firestore shape:

```
submissions/{autoId}
  employeeName: string
  baGoal:       number
  counts:       map<string, number>   // line-item id -> count
  submittedAt:  timestamp
```

---

## Project layout

```
app/
  lib/
    models/      scorecard_config (line items), submission, profile
    services/    store.dart  ← single data seam (local now, Firestore later)
    screens/     onboarding, scorecard, summary, manager
    widgets/     tally_row, section pill (theme), brand_header, profile_menu
    theme.dart   colors, radii, AppCard, SectionPill, TextStyles
  web/           index.html (+ splash), manifest.json, icons  ← PWA
  assets/        logo.png
```

## Customizing the card

All line items, prices, and section names live in
`lib/models/scorecard_config.dart`. Add, remove, or reprice an item there and the
whole app — tallies, totals, summary, and manager breakdown — updates with it.
