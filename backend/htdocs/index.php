<?php

declare(strict_types=1);

// --- TANGKAP SEMUA RUTE BERDASARKAN REQUEST PATH ---
$p = rtrim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');

// Jika path diawali dengan /auth, langsung lempar ke auth.php
if (str_starts_with($p, '/auth') || str_ends_with($p, '/auth')) {
    require __DIR__ . '/auth.php';
    exit;
}
// ------------------------------------------------

require_once __DIR__ . '/Rest.php';
require_once __DIR__ . '/Config.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/controller/AuthController.php';
require_once __DIR__ . '/controller/ProductController.php';
require_once __DIR__ . '/routes/api.php';

try {
    $authController = new AuthController();
    $controller = new ProductController(Config::database());
    $controller->initialiseDatabase();
    registerApiRoutes($controller, $authController);
} catch (Throwable $exception) {
    error_log($exception->getMessage());
    $status = $exception->getCode() === 503 ? 503 : 500;
    fail($status === 503 ? 'Database connection failed.' : 'Internal server error.', $status);
}