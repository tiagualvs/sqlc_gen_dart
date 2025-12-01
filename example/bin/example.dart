import 'package:example/db/sqlc.dart';

void main(List<String> arguments) async {
  final sqlc = Sqlc(SqliteMemory());

  sqlc.database.execute('''CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(32) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255),
    type VARCHAR(32) NOT NULL CHECK (
        type IN ('private', 'group', 'channel')
    ) DEFAULT 'private',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS participants (
    user_id INTEGER NOT NULL REFERENCES users (id),
    chat_id INTEGER NOT NULL REFERENCES chats (id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, chat_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chat_id INTEGER NOT NULL REFERENCES chats (id),
    user_id INTEGER NOT NULL REFERENCES users (id),
    content TEXT NOT NULL,
    type VARCHAR(32) NOT NULL CHECK (
        type IN (
            'text',
            'image',
            'video',
            'file'
        )
    ) DEFAULT 'text',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);''');

  final user = await sqlc.queries.insertUser('Tiago', 'tiagualvs', 'tiago@gmail.com', 'Abc@123');

  print([user.id, user.name, user.username, user.email, user.password, user.createdAt, user.updatedAt]);
}
