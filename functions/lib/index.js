"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.resetPasswordWithOtp = exports.requestPasswordResetOtp = exports.verifyEmailOtp = exports.requestEmailOtp = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const bcrypt = __importStar(require("bcryptjs"));
const nodemailer = __importStar(require("nodemailer"));
admin.initializeApp();
const db = admin.firestore();
/** ==== Parámetros para OTP de verificación de email ==== */
const OTP_EXP_MINUTES = 10;
const RESEND_COOLDOWN_SECONDS = 60;
const MAX_ATTEMPTS = 5;
/** ==== Parámetros para OTP de restablecimiento de contraseña ==== */
const RESET_OTP_EXP_MINUTES = 10;
const RESET_RESEND_COOLDOWN_SECONDS = 60;
const RESET_MAX_ATTEMPTS = 5;
// Env vars: set con:
// firebase functions:config:set smtp.host="..." smtp.port="587" smtp.user="apikey" smtp.pass="..." smtp.from="Nombre <no-reply@dominio.com>"
const transporter = nodemailer.createTransport({
    host: String(process.env.SMTP_HOST || (functions.config().smtp && functions.config().smtp.host)),
    port: Number(process.env.SMTP_PORT || (functions.config().smtp && functions.config().smtp.port) || 587),
    secure: false, // STARTTLS en 587
    auth: {
        user: String(process.env.SMTP_USER || (functions.config().smtp && functions.config().smtp.user)),
        pass: String(process.env.SMTP_PASS || (functions.config().smtp && functions.config().smtp.pass)),
    },
});
function randomOtp4() {
    return Math.floor(1000 + Math.random() * 9000).toString();
}
/* =========================================================
 * OTP de verificación de correo (usuario autenticado)
 * =======================================================*/
exports.requestEmailOtp = functions.https.onCall(async (data, context) => {
    const { uid } = context.auth ?? {};
    const { email } = data;
    if (!uid)
        throw new functions.https.HttpsError("unauthenticated", "Inicia sesión.");
    if (!email)
        throw new functions.https.HttpsError("invalid-argument", "Falta email.");
    const user = await admin.auth().getUser(uid);
    if (user.email?.toLowerCase() !== String(email).toLowerCase()) {
        throw new functions.https.HttpsError("permission-denied", "Email no coincide con el usuario.");
    }
    const ref = db.collection("email_otps").doc(uid);
    const now = admin.firestore.Timestamp.now();
    const doc = await ref.get();
    if (doc.exists) {
        const d = doc.data();
        const last = d.lastSentAt;
        if (last && now.seconds - last.seconds < RESEND_COOLDOWN_SECONDS) {
            throw new functions.https.HttpsError("resource-exhausted", "Espera antes de reenviar el código.");
        }
    }
    const otp = randomOtp4();
    const codeHash = await bcrypt.hash(otp, 10);
    const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + OTP_EXP_MINUTES * 60 * 1000));
    await ref.set({
        email: email.toLowerCase(),
        codeHash,
        expiresAt,
        attempts: 0,
        lastSentAt: now,
    }, { merge: true });
    await transporter.sendMail({
        from: String(process.env.SMTP_FROM || (functions.config().smtp && functions.config().smtp.from)),
        to: email,
        subject: "Tu código de verificación",
        text: `Tu código de verificación es: ${otp}. Expira en ${OTP_EXP_MINUTES} minutos.`,
        html: `<p>Tu código de verificación es:</p>
           <p style="font-size:24px; font-weight:bold; letter-spacing:4px;">${otp}</p>
           <p>Expira en ${OTP_EXP_MINUTES} minutos.</p>`,
    });
    return { ok: true, expiresInMinutes: OTP_EXP_MINUTES };
});
exports.verifyEmailOtp = functions.https.onCall(async (data, context) => {
    const { uid } = context.auth ?? {};
    const { email, code } = data;
    if (!uid)
        throw new functions.https.HttpsError("unauthenticated", "Inicia sesión.");
    if (!email || !code)
        throw new functions.https.HttpsError("invalid-argument", "Faltan datos.");
    const ref = db.collection("email_otps").doc(uid);
    const doc = await ref.get();
    if (!doc.exists) {
        throw new functions.https.HttpsError("failed-precondition", "No hay código activo.");
    }
    const d = doc.data();
    if (d.email.toLowerCase() != email.toLowerCase()) {
        throw new functions.https.HttpsError("permission-denied", "Email no coincide.");
    }
    const now = admin.firestore.Timestamp.now();
    if (now.seconds > d.expiresAt.seconds) {
        throw new functions.https.HttpsError("deadline-exceeded", "Código expirado.");
    }
    const attempts = d.attempts ?? 0;
    if (attempts >= MAX_ATTEMPTS) {
        throw new functions.https.HttpsError("resource-exhausted", "Demasiados intentos.");
    }
    const ok = await bcrypt.compare(code, d.codeHash);
    if (!ok) {
        await ref.update({ attempts: attempts + 1 });
        throw new functions.https.HttpsError("invalid-argument", "Código incorrecto.");
    }
    // Marca verificado en Auth
    await admin.auth().updateUser(uid, { emailVerified: true });
    // Opcional: sincroniza también Firestore de tu perfil de usuario
    await db.collection("users").doc(uid).set({ emailVerified: true }, { merge: true });
    await ref.delete();
    return { ok: true };
});
/* =========================================================
 * "Olvidé mi contraseña" con OTP (NO requiere autenticación)
 * =======================================================*/
/**
 * Genera y envía un OTP de 4 dígitos al email si existe el usuario.
 * Guarda el hash y expiración en password_reset_otps/{email}
 */
exports.requestPasswordResetOtp = functions.https.onCall(async (data, context) => {
    const { email } = data;
    if (!email) {
        throw new functions.https.HttpsError("invalid-argument", "Falta email.");
    }
    const normEmail = String(email).trim().toLowerCase();
    // Verifica que exista un usuario con ese email
    let userRecord;
    try {
        userRecord = await admin.auth().getUserByEmail(normEmail);
    }
    catch {
        throw new functions.https.HttpsError("not-found", "No existe usuario con ese email.");
    }
    const ref = db.collection("password_reset_otps").doc(normEmail);
    const now = admin.firestore.Timestamp.now();
    const snap = await ref.get();
    if (snap.exists) {
        const d = snap.data();
        const last = d.lastSentAt;
        if (last && now.seconds - last.seconds < RESET_RESEND_COOLDOWN_SECONDS) {
            throw new functions.https.HttpsError("resource-exhausted", "Espera antes de reenviar el código.");
        }
    }
    const otp = randomOtp4();
    const codeHash = await bcrypt.hash(otp, 10);
    const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + RESET_OTP_EXP_MINUTES * 60 * 1000));
    await ref.set({
        uid: userRecord.uid,
        email: normEmail,
        codeHash,
        expiresAt,
        attempts: 0,
        lastSentAt: now,
    }, { merge: true });
    await transporter.sendMail({
        from: String(process.env.SMTP_FROM || (functions.config().smtp && functions.config().smtp.from)),
        to: normEmail,
        subject: "Código para restablecer tu contraseña",
        text: `Tu código de restablecimiento es: ${otp}. Expira en ${RESET_OTP_EXP_MINUTES} minutos.`,
        html: `<p>Tu código de restablecimiento es:</p>
           <p style="font-size:24px; font-weight:bold; letter-spacing:4px;">${otp}</p>
           <p>Expira en ${RESET_OTP_EXP_MINUTES} minutos.</p>`,
    });
    return { ok: true, expiresInMinutes: RESET_OTP_EXP_MINUTES };
});
/**
 * Valida el OTP y cambia la contraseña del usuario en Firebase Auth.
 * Entrada: email, code (4 dígitos), newPassword
 */
exports.resetPasswordWithOtp = functions.https.onCall(async (data, context) => {
    const { email, code, newPassword } = data;
    if (!email || !code || !newPassword) {
        throw new functions.https.HttpsError("invalid-argument", "Faltan datos.");
    }
    if (typeof newPassword !== "string" || newPassword.length < 6) {
        throw new functions.https.HttpsError("invalid-argument", "La nueva contraseña es inválida (mínimo 6 caracteres).");
    }
    const normEmail = String(email).trim().toLowerCase();
    const ref = db.collection("password_reset_otps").doc(normEmail);
    const snap = await ref.get();
    if (!snap.exists) {
        throw new functions.https.HttpsError("failed-precondition", "No hay código activo.");
    }
    const d = snap.data();
    const now = admin.firestore.Timestamp.now();
    if (now.seconds > d.expiresAt.seconds) {
        throw new functions.https.HttpsError("deadline-exceeded", "Código expirado.");
    }
    const attempts = d.attempts ?? 0;
    if (attempts >= RESET_MAX_ATTEMPTS) {
        throw new functions.https.HttpsError("resource-exhausted", "Demasiados intentos.");
    }
    const ok = await bcrypt.compare(String(code), d.codeHash);
    if (!ok) {
        await ref.update({ attempts: attempts + 1 });
        throw new functions.https.HttpsError("invalid-argument", "Código incorrecto.");
    }
    // Cambiar contraseña en Auth
    const uid = d.uid || (await admin.auth().getUserByEmail(normEmail)).uid;
    await admin.auth().updateUser(uid, { password: newPassword });
    // Limpia el OTP
    await ref.delete();
    return { ok: true };
});
//# sourceMappingURL=index.js.map