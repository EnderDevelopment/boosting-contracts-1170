CREATE TABLE IF NOT EXISTS boosting_contracts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    vehicle_model VARCHAR(50) NOT NULL,
    start_location VARCHAR(100) NOT NULL,
    end_location VARCHAR(100) NOT NULL,
    status ENUM('available', 'accepted', 'completed') NOT NULL DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (player_id) REFERENCES users(identifier)
);

CREATE TABLE IF NOT EXISTS boosting_contract_cooldowns (
    player_id INT NOT NULL,
    last_contract TIMESTAMP NOT NULL,
    PRIMARY KEY (player_id),
    FOREIGN KEY (player_id) REFERENCES users(identifier)
);