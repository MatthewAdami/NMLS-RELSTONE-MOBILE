# nmls_mobile

Flutter mobile app with a Node/Express backend in `backend/`.

## Backend setup (MongoDB Atlas)

1. Copy `backend/.env.example` to `backend/.env`.
2. Set `MONGO_URI` to your Atlas connection string.
3. Start the backend from the workspace root:

```powershell
npm run start:backend
```

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
