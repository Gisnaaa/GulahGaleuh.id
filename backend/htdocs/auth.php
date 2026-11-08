<?php
// Endpoint auth: POST /auth/register, POST /auth/login, GET /auth/me
// Dipanggil dari index.php untuk semua path yang diawali /auth

header('Content-Type: application/json');

function out(int $code, array $data): void
{
    http_response_code($code);
    echo json_encode($data);
    exit;
}

function publicUser(array $u): array
{
    return ['id' => (int) $u['id'], 'username' => $u['username'], 'name' => $u['name']];
}

function issueToken(PDO $pdo, int $userId): string
{
    $token = bin2hex(random_bytes(32));
    $pdo->prepare('UPDATE users SET token_hash = ? WHERE id = ?')
        ->execute([hash('sha256', $token), $userId]);
    return $token;
}

function bearerToken(): ?string
{
    $header = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? '';
    if ($header === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) {
            if (strtolower($k) === 'authorization') {
                $header = $v;
                break;
            }
        }
    }
    return preg_match('/^Bearer\s+(.+)$/i', $header, $m) ? $m[1] : null;
}

try {
    // Variabel ini diisi oleh docker-compose.yaml (service php)
    $host = getenv('DB_HOST') ?: 'mysql';
    $port = getenv('DB_PORT') ?: '3306';
    $db   = getenv('DB_DATABASE') ?: 'app';
    $user = getenv('DB_USERNAME') ?: 'app';
    $pass = getenv('DB_PASSWORD') ?: 'app_secret';

    $pdo = new PDO(
        "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $pdo->exec('CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        name VARCHAR(100) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        token_hash CHAR(64) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )');

    $path   = rtrim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');
    $method = $_SERVER['REQUEST_METHOD'];
    $in     = json_decode(file_get_contents('php://input'), true) ?? [];

    // ---------- REGISTER ----------
    if ($method === 'POST' && str_ends_with($path, '/auth/register')) {
        $username = trim($in['username'] ?? '');
        $name     = trim($in['name'] ?? '');
        $password = $in['password'] ?? '';

        if (strlen($username) < 3) out(422, ['message' => 'Username minimal 3 karakter']);
        if ($name === '')          out(422, ['message' => 'Nama wajib diisi']);
        if (strlen($password) < 6) out(422, ['message' => 'Password minimal 6 karakter']);

        $st = $pdo->prepare('SELECT id FROM users WHERE username = ?');
        $st->execute([$username]);
        if ($st->fetch()) out(409, ['message' => 'Username sudah dipakai']);

        $pdo->prepare('INSERT INTO users (username, name, password_hash) VALUES (?, ?, ?)')
            ->execute([$username, $name, password_hash($password, PASSWORD_DEFAULT)]);
        $id = (int) $pdo->lastInsertId();

        $token = issueToken($pdo, $id);
        out(201, [
            'token' => $token,
            'user'  => ['id' => $id, 'username' => $username, 'name' => $name],
        ]);
    }

    // ---------- LOGIN ----------
    if ($method === 'POST' && str_ends_with($path, '/auth/login')) {
        $username = trim($in['username'] ?? '');
        $password = $in['password'] ?? '';

        $st = $pdo->prepare('SELECT * FROM users WHERE username = ?');
        $st->execute([$username]);
        $u = $st->fetch(PDO::FETCH_ASSOC);

        if (!$u || !password_verify($password, $u['password_hash'])) {
            out(401, ['message' => 'Username atau password salah']);
        }

        $token = issueToken($pdo, (int) $u['id']);
        out(200, ['token' => $token, 'user' => publicUser($u)]);
    }

    // ---------- ME (cek token) ----------
    if ($method === 'GET' && str_ends_with($path, '/auth/me')) {
        $token = bearerToken();
        if ($token === null) out(401, ['message' => 'Token tidak ada']);

        $st = $pdo->prepare('SELECT * FROM users WHERE token_hash = ?');
        $st->execute([hash('sha256', $token)]);
        $u = $st->fetch(PDO::FETCH_ASSOC);
        if (!$u) out(401, ['message' => 'Token tidak valid']);

        out(200, ['user' => publicUser($u)]);
    }

    out(404, ['message' => 'Endpoint tidak ditemukan']);
} catch (Throwable $e) {
    error_log('auth.php: ' . $e->getMessage());
    out(500, ['message' => 'Kesalahan server: ' . $e->getMessage()]);
}