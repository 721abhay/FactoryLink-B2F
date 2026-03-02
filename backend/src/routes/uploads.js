/**
 * Upload Routes — TRD Section 6: Amazon S3
 * POST /uploads/document  — Upload factory documents (GST, MSME, cheque)
 * POST /uploads/image     — Upload product images, rating photos
 */

const router = require('express').Router();
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const { authenticate } = require('../middleware/auth');

// Configure multer for temporary storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, path.join(__dirname, '../../uploads')),
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, `${uuidv4()}${ext}`);
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
    fileFilter: (req, file, cb) => {
        const allowed = ['.jpg', '.jpeg', '.png', '.pdf', '.webp'];
        const ext = path.extname(file.originalname).toLowerCase();
        if (allowed.includes(ext)) cb(null, true);
        else cb(new Error('Only JPG, PNG, PDF and WebP files are allowed.'));
    },
});

// ─── POST /uploads/document ──────────────────────
router.post('/document', authenticate(), upload.single('file'), async (req, res, next) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file', message: 'Please select a file to upload.' });
        }

        // TODO: Upload to S3 in production
        // const s3Url = await uploadToS3(req.file, 'documents');

        // For now, return local path
        const fileUrl = `/uploads/${req.file.filename}`;

        res.json({
            success: true,
            url: fileUrl,
            filename: req.file.filename,
            size: req.file.size,
            type: req.body.doc_type || 'document',
        });
    } catch (err) { next(err); }
});

// ─── POST /uploads/image ─────────────────────────
router.post('/image', authenticate(), upload.single('image'), async (req, res, next) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file', message: 'Please select an image.' });
        }

        // TODO: Upload to S3 & generate thumbnails
        const fileUrl = `/uploads/${req.file.filename}`;

        res.json({
            success: true,
            url: fileUrl,
            filename: req.file.filename,
            size: req.file.size,
        });
    } catch (err) { next(err); }
});

module.exports = router;
