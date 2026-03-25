# nmls_mobile

Flutter mobile app with a Node/Express backend in `server/`.

## Backend setup (MongoDB Atlas)

1. Copy `server/.env.example` to `server/.env`.
2. Set `MONGO_URI` to your Atlas connection string.
3. Configure SMTP (optional for local dev, required for “send email” behavior):
   - SMTP_HOST
   - SMTP_PORT
   - SMTP_USER
   - SMTP_PASS (for Gmail: use a Gmail App Password)
   - SMTP_FROM
4. Start the backend from the workspace root:

```powershell
npm start
```

## Option A: Use Deployed Backend (recommended)
Other developers do NOT need to configure SMTP locally as long as their mobile app calls your deployed backend (where SMTP is configured).

1. Deploy/run the backend somewhere with valid `SMTP_*` and `MONGO_URI` in `server/.env`.
2. Run the mobile app with the deployed API base URL:

```powershell
flutter run -d edge --dart-define=API_BASE_URL=http://YOUR-API-HOST:5000
```

If a developer runs the backend locally without SMTP configured, the contact form request will still be accepted/saved, but no confirmation email will be sent from that local server.

## Atlas + Compass checklist

- Use the same URI in both `backend/.env` and MongoDB Compass.
- URL-encode special password characters (`@`, `:`, `/`, `?`, `#`, `%`).
- In Atlas, verify:
  - `Network Access`: your current public IP is allowed.
  - `Database Access`: the DB user exists and password is correct.
- Prefer a URI with an explicit DB name, for example:

```text
mongodb+srv://<user>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority&appName=<app>
```
