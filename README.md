# NekoMusic

A cross-platform music player built with Flutter and Flask.

## Features

- Search and play music
- Audio streaming with full player controls
- Create and manage playlists
- Download songs for offline listening
- Dark/Light theme
- Audio quality settings
- Recently played history

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter (Android, iOS, Web) |
| Backend | Python Flask |
| Audio | just_audio |
| Storage | Hive |
| State | Provider |

## Setup

### Backend

```bash
cd backend
pip install -r requirements.txt
python app.py
```

### Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

### Web Build

```bash
cd flutter_app
flutter build web
```

## Configuration

Set your API credentials in `backend/config.py` or via environment variables:

```bash
export API_BASE_URL="https://your-api-url.com/api"
export API_KEY="your-api-key"
```

## Project Structure

```
nekocMusic/
├── backend/           # Flask API proxy
│   ├── app.py
│   ├── config.py
│   ├── requirements.txt
│   └── services/
└── flutter_app/       # Flutter cross-platform app
    ├── lib/
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   ├── theme/
    │   └── widgets/
    └── pubspec.yaml
```
