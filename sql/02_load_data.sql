-- OLX DATABASE PROJECT - LOAD ALL 11 CSV FILES
-- PostgreSQL / psql
-- open terminal
-- psql -U <username> -d <database_name>

\set ON_ERROR_STOP on

BEGIN;

SET search_path TO olx;

-- 1. Cities
\copy olx.cities (city_id, city_name, state) FROM 'seed_data/cities.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 2. Categories
\copy olx.categories (category_id, category_name, parent_id) FROM 'seed_data/categories.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 3. Boost packages
\copy olx.boost_packages (package_id, package_name, price, duration_days) FROM 'seed_data/boost_packages.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 4. Users
\copy olx.users (user_id, full_name, phone, email, city_id, phone_verified, is_banned, joined_at) FROM 'seed_data/users.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 5. Listings
\copy olx.listings (listing_id, seller_id, category_id, title, description, price, is_negotiable, item_condition, attributes, city_id, locality, latitude, longitude, image_count, view_count, boost_package_id, status, posted_at, expires_at, sold_at) FROM 'seed_data/listings.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 6. Chat threads
\copy olx.chat_threads (thread_id, listing_id, buyer_id, created_at) FROM 'seed_data/chat_threads.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 7. Chat messages
\copy olx.chat_messages (message_id, thread_id, sender_id, body, sent_at, is_read) FROM 'seed_data/chat_messages.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 8. Offers
\copy olx.offers (offer_id, listing_id, buyer_id, offer_price, status, created_at, responded_at) FROM 'seed_data/offers.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 9. Favourites
\copy olx.favourites (user_id, listing_id, saved_at) FROM 'seed_data/favourites.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 10. Reports
\copy olx.reports (report_id, listing_id, reporter_id, reason, created_at, status) FROM 'seed_data/reports.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 11. Seller ratings
\copy olx.seller_ratings (rating_id, seller_id, rater_id, listing_id, stars, comment, created_at) FROM 'seed_data/seller_ratings.csv' WITH (FORMAT CSV, HEADER TRUE);

COMMIT;





-- Easier Lengthier way
-- Just Import them directly using PG admin 4 , as there are only 11 files it is quite easy
-- remember to import non-foreign key ones first


-- To check run (for now this is enough)
SELECT
    schemaname,
    relname AS table_name,
    n_live_tup AS estimated_rows
FROM pg_stat_user_tables
WHERE schemaname = 'olx'
ORDER BY relname;

-- ANALYZE tells PostgreSQL to collect information about
-- the data inside your tables so it can execute future queries more efficiently.
ANALYZE olx.cities;
ANALYZE olx.categories;
ANALYZE olx.boost_packages;
ANALYZE olx.users;
ANALYZE olx.listings;
ANALYZE olx.chat_threads;
ANALYZE olx.chat_messages;
ANALYZE olx.offers;
ANALYZE olx.favourites;
ANALYZE olx.reports;
ANALYZE olx.seller_ratings;