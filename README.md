# Kaomoji Palette for macOS

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Kaomoji%20Palette.png?raw=true 2x">
  <source media="(prefers-color-scheme: light)" srcset="Kaomoji%20Palette~light.png?raw=true 2x">
  <img alt="" src="Kaomoji%20Palette.png?raw=true" width="392">
</picture>


## Features

- Quickly insert kaomoji (^０^)ノ
- Customizable list of kaomoji (⌒‿⌒)
- Available in Danish and English ヽ(°〇°)ﾉ


## Usage

- Open _Kaomoji Palette.app_ and select Enable
- Accept the prompt that appears in System Settings
- Press Shift-Command-Space to show the Kaomoji Palette
- Or, until a fix is found for a Tahoe regression, turn on _System Settings → Keyboard → Input Sources → Edit… → Show Input menu in menu bar_, click the menu bar item, and select _Show Kaomoji_


## Building from Source

Before building, change the bundle identifier to your own and select your Apple Development team under _Signing & Capabilities_ in Xcode. This helps macOS consistently identify the app when granting permissions.

