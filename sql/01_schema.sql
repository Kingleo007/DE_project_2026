-- OLX Used Goods Marketplace
-- Database schema creation
CREATE SCHEMA IF NOT EXISTS olx;
SET search_path TO olx;

-- 1. Cities
CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL
);

-- 2. Categories
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_id INTEGER,
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_id)
        REFERENCES categories (category_id)
        ON DELETE RESTRICT
);

-- 3. Boost packages
CREATE TABLE boost_packages (
    package_id INTEGER PRIMARY KEY,
    package_name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
        CHECK (price >= 0),
    duration_days INTEGER NOT NULL
        CHECK (duration_days > 0)
);

-- 4. Users
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    city_id INTEGER NOT NULL,
    phone_verified BOOLEAN NOT NULL,
    is_banned BOOLEAN NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_users_city
        FOREIGN KEY (city_id)
        REFERENCES cities (city_id)
        ON DELETE RESTRICT
);

-- 5. Listings
CREATE TABLE listings (
    listing_id INTEGER PRIMARY KEY,
    seller_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12, 2) NOT NULL
        CHECK (price >= 0),
    is_negotiable BOOLEAN NOT NULL,
    item_condition VARCHAR(20) NOT NULL
        CHECK (item_condition IN ('FAIR', 'GOOD', 'LIKE_NEW', 'NEW')),
    attributes JSONB NOT NULL,
    city_id INTEGER NOT NULL,
    locality VARCHAR(150) NOT NULL,
    latitude NUMERIC(9, 6) NOT NULL
        CHECK (latitude BETWEEN -90 AND 90),
    longitude NUMERIC(9, 6) NOT NULL
        CHECK (longitude BETWEEN -180 AND 180),
    image_count INTEGER NOT NULL
        CHECK (image_count >= 0),
    view_count INTEGER NOT NULL
        CHECK (view_count >= 0),
    boost_package_id INTEGER,
    status VARCHAR(20) NOT NULL
        CHECK (status IN ('ACTIVE', 'EXPIRED', 'REMOVED', 'SOLD')),
    posted_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    sold_at TIMESTAMPTZ,
    CONSTRAINT fk_listings_seller
        FOREIGN KEY (seller_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_listings_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_listings_city
        FOREIGN KEY (city_id)
        REFERENCES cities (city_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_listings_boost_package
        FOREIGN KEY (boost_package_id)
        REFERENCES boost_packages (package_id)
        ON DELETE SET NULL
);

-- 6. Chat threads
CREATE TABLE chat_threads (
    thread_id INTEGER PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    buyer_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_chat_threads_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings (listing_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_chat_threads_buyer
        FOREIGN KEY (buyer_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT
);

-- 7. Chat messages
CREATE TABLE chat_messages (
    message_id INTEGER PRIMARY KEY,
    thread_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    body TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,
    is_read BOOLEAN NOT NULL,
    CONSTRAINT fk_chat_messages_thread
        FOREIGN KEY (thread_id)
        REFERENCES chat_threads (thread_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_chat_messages_sender
        FOREIGN KEY (sender_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT
);

-- 8. Offers
CREATE TABLE offers (
    offer_id INTEGER PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    buyer_id INTEGER NOT NULL,
    offer_price NUMERIC(12, 2) NOT NULL
        CHECK (offer_price >= 0),
    status VARCHAR(20) NOT NULL
        CHECK (status IN ('ACCEPTED', 'COUNTERED', 'PENDING', 'REJECTED')),
    created_at TIMESTAMPTZ NOT NULL,
    responded_at TIMESTAMPTZ,
    CONSTRAINT fk_offers_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings (listing_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_offers_buyer
        FOREIGN KEY (buyer_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT
);

-- 9. Favourites
CREATE TABLE favourites (
    user_id INTEGER NOT NULL,
    listing_id INTEGER NOT NULL,
    saved_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, listing_id),
    CONSTRAINT fk_favourites_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_favourites_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings (listing_id)
        ON DELETE CASCADE
);

-- 10. Reports
CREATE TABLE reports (
    report_id INTEGER PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    reporter_id INTEGER NOT NULL,
    reason VARCHAR(30) NOT NULL
        CHECK (reason IN ('ALREADY_SOLD', 'FRAUD', 'OFFENSIVE', 'SPAM', 'WRONG_CATEGORY')),
    created_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL
        CHECK (status IN ('ACTIONED', 'DISMISSED', 'OPEN')),
    CONSTRAINT fk_reports_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings (listing_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_reports_reporter
        FOREIGN KEY (reporter_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT
);

-- 11. Seller ratings
CREATE TABLE seller_ratings (
    rating_id INTEGER PRIMARY KEY,
    seller_id INTEGER NOT NULL,
    rater_id INTEGER NOT NULL,
    listing_id INTEGER NOT NULL,
    stars SMALLINT NOT NULL
        CHECK (stars BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_seller_ratings_seller
        FOREIGN KEY (seller_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_seller_ratings_rater
        FOREIGN KEY (rater_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_seller_ratings_listing
        FOREIGN KEY (listing_id)
        REFERENCES listings (listing_id)
        ON DELETE RESTRICT
);


