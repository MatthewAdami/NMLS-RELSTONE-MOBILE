const express = require('express');
const mongoose = require('mongoose');
const nodemailer = require('nodemailer');

const router = express.Router();

function getString(value) {
  return value == null ? '' : String(value);
}

function isValidEmail(email) {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

function escapeHtml(str) {
  return String(str)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

router.post('/contact', async (req, res) => {
  try {
    const db = mongoose.connection.db;
    if (!db) throw new Error('Database connection is not initialized');

    const name = getString(req.body?.name).trim();
    const email = getString(req.body?.email).trim().toLowerCase();
    const subject = getString(req.body?.subject).trim() || 'General Inquiry';
    const message = getString(req.body?.message).trim();

    if (!email || !isValidEmail(email)) {
      return res.status(400).json({ message: 'Invalid email address' });
    }
    if (!message) {
      return res.status(400).json({ message: 'Message is required' });
    }
    if (message.length > 5000) {
      return res.status(400).json({ message: 'Message is too long' });
    }

    // Store the request so we have an audit trail (and for future admin workflows).
    await db.collection('support_requests').insertOne({
      name,
      email,
      subject,
      message,
      createdAt: new Date(),
    });

    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = Number(process.env.SMTP_PORT || 587);
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;
    const smtpFrom = process.env.SMTP_FROM;
    const smtpSecure = String(process.env.SMTP_SECURE || 'false').toLowerCase() === 'true';

    if (!smtpHost || !smtpUser || !smtpPass || !smtpFrom) {
      // Still accept the request so local dev/testing works even if SMTP isn't configured.
      // When deployed properly (Option A), SMTP will be configured and the email will be sent.
      return res.status(200).json({
        message:
          'Message received! If email sending is enabled on this server, you will receive a confirmation email shortly.',
      });
    }

    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpSecure,
      auth: { user: smtpUser, pass: smtpPass },
    });

    const safeName = name || 'there';
    const emailSubject = `Relstone Support - ${subject}`;

    const normalizedMessage = message.replaceAll('\r\n', '\n');

    const emailText = `Hi ${safeName},\n\nThanks for reaching out to Relstone support.\n\nSubject: ${subject}\n\nMessage:\n${normalizedMessage}\n\nWe will review your request and get back to you.\n\nBest regards,\nRelstone Support Team\n`;

    const emailHtml = `
<!doctype html>
<html>
  <body style="margin:0;padding:0;font-family:Arial,sans-serif;color:#111827;line-height:1.5;">
    <div style="max-width:720px;margin:0 auto;padding:24px;">
      <h2 style="margin:0 0 12px 0;font-size:20px;">Hi ${escapeHtml(safeName)},</h2>
      <p style="margin:0 0 16px 0;font-size:14px;">
        Thanks for reaching out to <b>Relstone</b> support.
      </p>

      <div style="border:1px solid #e5e7eb;border-radius:12px;padding:16px;background:#ffffff;">
        <table style="border-collapse:collapse;width:100%;font-size:14px;">
          <tr>
            <td style="padding:4px 12px 4px 0;width:110px;color:#374151;font-weight:700;">Subject</td>
            <td style="padding:4px 0 4px 0;color:#111827;">${escapeHtml(subject)}</td>
          </tr>
          <tr>
            <td style="padding:12px 12px 4px 0;vertical-align:top;color:#374151;font-weight:700;">Message</td>
            <td style="padding:12px 0 4px 0;color:#111827;white-space:pre-wrap;word-break:break-word;">${escapeHtml(
              normalizedMessage,
            )}</td>
          </tr>
        </table>
      </div>

      <p style="margin:16px 0 0 0;font-size:14px;">
        We will review your request and get back to you.
      </p>

      <p style="margin:14px 0 0 0;font-size:14px;">
        Best regards,<br/>
        <b>Relstone Support Team</b>
      </p>
    </div>
  </body>
</html>
    `;

    await transporter.sendMail({
      from: smtpFrom,
      to: email, // student/user receives the email directly
      replyTo: smtpFrom,
      subject: emailSubject,
      text: emailText,
      html: emailHtml,
    });

    return res.status(200).json({ message: 'Message sent! Please check your email.' });
  } catch (error) {
    console.error('Contact support error:', error);
    const isGmailAuthError =
      error?.code === 'EAUTH' ||
      String(error?.response || '').toLowerCase().includes('badcredentials');

    if (isGmailAuthError) {
      return res.status(500).json({
        message:
          'Gmail rejected SMTP credentials. Use a Gmail App Password (Google > Security > App passwords) for SMTP_PASS.',
      });
    }

    return res.status(500).json({ message: 'Server error sending support message' });
  }
});

module.exports = router;

