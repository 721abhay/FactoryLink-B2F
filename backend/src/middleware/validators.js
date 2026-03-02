/**
 * Joi Validation Schemas — TRD Section 5
 * All API inputs validated and sanitised before processing
 */

const Joi = require('joi');

const schemas = {
    // Auth
    sendOtp: Joi.object({
        phone: Joi.string().pattern(/^[6-9]\d{9}$/).required().messages({
            'string.pattern.base': 'Please enter a valid 10-digit Indian mobile number',
        }),
    }),

    verifyOtp: Joi.object({
        phone: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
        otp: Joi.string().length(6).required(),
        user_type: Joi.string().valid('customer', 'factory').required(),
    }),

    // Customer Registration
    customerRegister: Joi.object({
        name: Joi.string().min(2).max(100).required(),
        address: Joi.string().required(),
        pin_code: Joi.string().pattern(/^\d{6}$/).required(),
        anchor_point_id: Joi.string().uuid().optional(),
    }),

    // Factory Registration — TRD F1
    factoryRegister: Joi.object({
        business_name: Joi.string().min(2).max(200).required(),
        gst_number: Joi.string().pattern(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/).optional(),
        msme_number: Joi.string().max(30).optional(),
        bank_account: Joi.string().max(30).optional(),
        ifsc_code: Joi.string().pattern(/^[A-Z]{4}0[A-Z0-9]{6}$/).optional(),
        product_categories: Joi.array().items(Joi.string()).min(1).required(),
        capacity_per_day: Joi.number().integer().min(1).required(),
        min_order_qty: Joi.number().integer().min(1).default(10),
        address: Joi.string().required(),
        city: Joi.string().required(),
        state: Joi.string().required(),
    }),

    // Product — TRD F2, F3
    addProduct: Joi.object({
        category: Joi.string().required(),
        name: Joi.string().min(2).max(200).required(),
        description: Joi.string().optional(),
        tier1_price: Joi.number().positive().required(),
        tier1_min_qty: Joi.number().integer().min(1).default(10),
        tier2_price: Joi.number().positive().optional(),
        tier2_min_qty: Joi.number().integer().min(1).optional(),
        tier3_price: Joi.number().positive().optional(),
        tier3_min_qty: Joi.number().integer().min(1).optional(),
        mrp: Joi.number().positive().optional(),
        gst_rate: Joi.number().min(0).max(28).default(18),
        unit: Joi.string().default('piece'),
        lead_time_days: Joi.number().integer().min(1).default(7),
        capacity_per_day: Joi.number().integer().min(1).default(100),
    }),

    // Order — TRD C4
    placeOrder: Joi.object({
        product_id: Joi.string().uuid().required(),
        qty: Joi.number().integer().min(1).required(),
        anchor_point_id: Joi.string().uuid().optional(),
    }),

    // Rating — TRD
    submitRating: Joi.object({
        stars: Joi.number().integer().min(1).max(5).required(),
        review: Joi.string().max(500).optional(),
    }),

    // Subscription
    createSubscription: Joi.object({
        product_id: Joi.string().uuid().required(),
        qty: Joi.number().integer().min(1).required(),
        frequency: Joi.string().valid('weekly', 'biweekly', 'monthly').default('monthly'),
        duration_months: Joi.number().integer().min(1).max(12).default(3),
        anchor_point_id: Joi.string().uuid().optional(),
    }),
};

// Validation middleware factory
function validate(schemaName) {
    return (req, res, next) => {
        const schema = schemas[schemaName];
        if (!schema) return next();

        const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
        if (error) {
            error.isJoi = true;
            return next(error);
        }
        req.body = value;
        next();
    };
}

module.exports = { schemas, validate };
