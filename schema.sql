CREATE TABLE IF NOT EXISTS `billing_invoices` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_type` ENUM('personal', 'job', 'b2b') NOT NULL,
    `sender_identifier` VARCHAR(64) NOT NULL,
    `sender_name` VARCHAR(100) NOT NULL,
    `sender_job` VARCHAR(50) DEFAULT NULL,
    `sender_society` VARCHAR(64) DEFAULT NULL,
    `recipient_identifier` VARCHAR(64) DEFAULT NULL,
    `recipient_name` VARCHAR(100) DEFAULT NULL,
    `recipient_society` VARCHAR(64) DEFAULT NULL,
    `title` VARCHAR(80) NOT NULL,
    `subtotal` INT UNSIGNED NOT NULL,
    `discount_percent` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `total` INT UNSIGNED NOT NULL,
    `due_date` DATE DEFAULT NULL,
    `attachments` JSON DEFAULT NULL,
    `status` ENUM('pending', 'processing', 'paid', 'cancelled') NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    `cancelled_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_billing_sender` (`sender_identifier`, `created_at`),
    KEY `idx_billing_recipient` (`recipient_identifier`, `status`, `created_at`),
    KEY `idx_billing_sender_society` (`sender_society`, `status`, `created_at`),
    KEY `idx_billing_recipient_society` (`recipient_society`, `status`, `created_at`),
    KEY `idx_billing_status_due` (`status`, `due_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `billing_templates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job_name` VARCHAR(50) NOT NULL,
    `created_by` VARCHAR(64) NOT NULL,
    `name` VARCHAR(48) NOT NULL,
    `title` VARCHAR(80) NOT NULL,
    `subtotal` INT UNSIGNED NOT NULL,
    `discount_percent` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `attachments` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_billing_template_job_name` (`job_name`, `name`),
    KEY `idx_billing_template_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `billing_commissions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_id` BIGINT UNSIGNED NOT NULL,
    `society` VARCHAR(64) NOT NULL,
    `employee_identifier` VARCHAR(64) NOT NULL,
    `employee_name` VARCHAR(100) NOT NULL,
    `amount` INT UNSIGNED NOT NULL,
    `status` ENUM('available', 'processing', 'paid') NOT NULL DEFAULT 'available',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_billing_commission_invoice` (`invoice_id`),
    KEY `idx_billing_commission_society` (`society`, `status`, `created_at`),
    KEY `idx_billing_commission_employee` (`employee_identifier`, `status`),
    CONSTRAINT `fk_billing_commission_invoice`
        FOREIGN KEY (`invoice_id`) REFERENCES `billing_invoices` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `billing_society_transfers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_id` BIGINT UNSIGNED NOT NULL,
    `debtor_society` VARCHAR(64) NOT NULL,
    `creditor_society` VARCHAR(64) NOT NULL,
    `amount` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_billing_society_transfer_invoice` (`invoice_id`),
    KEY `idx_billing_society_debtor` (`debtor_society`, `created_at`),
    KEY `idx_billing_society_creditor` (`creditor_society`, `created_at`),
    CONSTRAINT `fk_billing_society_transfer_invoice`
        FOREIGN KEY (`invoice_id`) REFERENCES `billing_invoices` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `billing_settings` (
    `setting_key` VARCHAR(48) NOT NULL,
    `setting_value` JSON NOT NULL,
    `updated_by` VARCHAR(64) NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
