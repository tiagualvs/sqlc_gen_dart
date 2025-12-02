CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuidv7 (),
    name VARCHAR(255) NOT NULL,
    username VARCHAR(32) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT uuidv7 (),
    name VARCHAR(255),
    type VARCHAR(32) NOT NULL CHECK (
        type IN ('private', 'group', 'channel')
    ) DEFAULT 'private',
    user_id UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS participants (
    user_id UUID NOT NULL REFERENCES users (id),
    chat_id UUID NOT NULL REFERENCES chats (id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, chat_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuidv7 (),
    chat_id UUID NOT NULL REFERENCES chats (id),
    user_id UUID NOT NULL REFERENCES users (id),
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
);