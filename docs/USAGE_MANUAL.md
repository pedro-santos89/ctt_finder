# CTT Finder — Usage Manual

## Overview

CTT Finder is a cross-platform application for locating Portuguese postal service (CTT) stores, access points and mailboxes. It displays results on an interactive map and provides detailed information for each location including address, schedule, services and contact details.

---

## Getting Started

### 1. Welcome Screen

When you launch the app you are greeted by the **Welcome Screen**:

- **Language Toggle** — tap the **EN** / **PT** button in the top-right corner to switch between English and Portuguese. The entire interface updates instantly.
- **"Find Stores & Mailboxes"** button — tap it to proceed to the main map. The filter sheet will open automatically so you can start your first search.

### 2. Filter Sheet

The filter sheet lets you narrow down results before searching:

| Control | Description |
|---------|-------------|
| **Stations / Mailboxes toggles** | Enable or disable CTT stores (red) and/or mailboxes (orange). |
| **District** dropdown | Select a Portuguese district (e.g. Lisboa, Porto, Faro). |
| **Municipality** dropdown | Appears after selecting a district. Pick a specific concelho. |
| **Parish** dropdown | Appears after selecting a municipality. Pick a specific freguesia. |
| **Clear** button | Resets all filters to their default state. |
| **Search** button | Runs the search with the current filters. |

> **Tip:** You can search by district alone — the app will automatically expand the search to cover every municipality and parish within that district.

### 3. Map Screen

After searching, results appear as markers on the map:

- **Red circles** = CTT stores & access points.
- **Orange circles** = Mailboxes.
- **Blue dot** = Your current location (if permission was granted).

#### Search Bar
Type in the search bar at the top to filter the loaded results by name, address, locality, municipality, district or postal code.

#### Floating Action Buttons (right side)
| Button | Action |
|--------|--------|
| **EN / PT** | Toggle language. |
| **My Location** (crosshair icon) | Centre the map on your GPS position. If location has not been acquired yet, it will request it. |
| **Globe** icon | Zoom out to show all of Portugal. |
| **List** icon | Open a scrollable list of all loaded locations. |

#### Location Counter (bottom-left)
Shows how many locations are currently loaded, or a hint to use filters if none have been loaded yet.

#### Location Card
Tap any marker to show a floating preview card at the bottom of the screen. The card displays the name, type, address, schedule and up to three service chips. **Tap the card** to open the full detail screen. Press **×** to dismiss.

### 4. List View

Tap the **list** FAB to open a draggable bottom sheet with all loaded locations in card form. Tap any entry to highlight it on the map.

### 5. Detail Screen

The detail screen provides complete information about a location:

- **Map header** — a non-interactive map centred on the location.
- **Address card** — full address including postal code, locality, municipality and district.
- **Schedule card** *(stations only)* — opening hours with "After 6 PM" and "Weekends" badges when applicable.
- **Last Collection card** *(mailboxes only)* — the last mail-collection time.
- **Phone card** — tap to call.
- **Services card** — coloured chips for each service offered.
- **Coordinates card** — latitude and longitude.
- **Directions** button — opens Google Maps with turn-by-turn directions from your current location.
- **Share** button — copies a shareable text to the snackbar (name + address + Google Maps link).
- **View on CTT website** — opens the official CTT station-search page in the browser.

---

## Tips & Tricks

1. **Offline map tiles are not cached** — an internet connection is required.
2. **GPS** — on desktop platforms the blue dot may not appear if location services are unavailable.
3. **Large searches** — searching an entire district may take a few seconds because the app queries every parish individually.
4. **Zoom** — pinch/scroll to zoom; double-tap to zoom in; the map supports standard OpenStreetMap zoom levels 3–18.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No results appear | Make sure at least one type (stations or mailboxes) is toggled on and a district is selected. |
| Map is blank | Check your internet connection. The map uses OpenStreetMap tiles. |
| Blue dot missing | Grant location permission when prompted, or tap the crosshair FAB. |
| App crashes on startup | Run `flutter clean` then `flutter run` again. |

---

*Developed by **Anima Rasa Prod.***
