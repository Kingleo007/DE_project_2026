# Schema Design

## Database Overview
The OLX marketplace database needs to manage users, advertisements, categories, offers, chats, favourites, reports, ratings, and boost packages.
The main objective is to maintain organised data, enforce relationships between tables, and support efficient searching, communication, and marketplace operations.

Tables will be created inside the PostgreSQL schema `olx`.

# Tables

## Overview
The database contains 11 relational tabLES. The schema uses primary keys, foreign keys, unique constraints, NOT NULL constraints, and CHECK constraints to maintain data integrity.

The database contains the following 11 tables:

1. `cities`
2. `categories`
3. `boost_packages`
4. `users`
5. `listings`
6. `chat_threads`
7. `chat_messages`
8. `offers`
9. `favourites`
10. `reports`
11. `seller_ratings`


### 1. Cities
Stores the cities in which advertisements are located.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| city_id | INTEGER | PRIMARY KEY, NOT NULL |
| city_name | VARCHAR(100) | NOT NULL |
| state | VARCHAR(100) | NOT NULL |

### 2. Categories
Stores product categories and subcategories.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| category_id | INTEGER | PRIMARY KEY, NOT NULL |
| category_name | VARCHAR(100) | NOT NULL |
| parent_id | INTEGER | NULL allowed, FOREIGN KEY REFERENCES categories(category_id) |

### 3. Boost Packages
Stores available advertisement promotion packages.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| package_id | INTEGER | PRIMARY KEY, NOT NULL |
| package_name | VARCHAR(100) | NOT NULL |
| price | NUMERIC(10,2) | NOT NULL, CHECK (price >= 0) |
| duration_days | INTEGER | NOT NULL, CHECK (duration_days > 0) |

### 4. Users
Stores information about marketplace users. A user can act as both a buyer and a seller.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| user_id | INTEGER | PRIMARY KEY, NOT NULL |
| full_name | VARCHAR(150) | NOT NULL |
| phone | VARCHAR(20) | UNIQUE, NOT NULL |
| email | VARCHAR(255) | UNIQUE, NULL allowed |
| city_id | INTEGER | FOREIGN KEY REFERENCES cities(city_id), NOT NULL |
| phone_verified | BOOLEAN | NOT NULL |
| is_banned | BOOLEAN | NOT NULL |
| joined_at | TIMESTAMPTZ | NOT NULL |

### 5. Listings
Stores advertisements posted by sellers.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| listing_id | INTEGER | PRIMARY KEY, NOT NULL |
| seller_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| category_id | INTEGER | FOREIGN KEY REFERENCES categories(category_id), NOT NULL |
| title | VARCHAR(255) | NOT NULL |
| description | TEXT | NULL allowed |
| price | NUMERIC(12,2) | NOT NULL, CHECK (price >= 0) |
| is_negotiable | BOOLEAN | NOT NULL |
| item_condition | VARCHAR(20) | NOT NULL, CHECK (item_condition IN ('FAIR', 'GOOD', 'LIKE_NEW', 'NEW')) |
| attributes | JSONB | NOT NULL |
| city_id | INTEGER | FOREIGN KEY REFERENCES cities(city_id), NOT NULL |
| locality | VARCHAR(150) | NOT NULL |
| latitude | NUMERIC(9,6) | NOT NULL, CHECK (latitude BETWEEN -90 AND 90) |
| longitude | NUMERIC(9,6) | NOT NULL, CHECK (longitude BETWEEN -180 AND 180) |
| image_count | INTEGER | NOT NULL, CHECK (image_count >= 0) |
| view_count | INTEGER | NOT NULL, CHECK (view_count >= 0) |
| boost_package_id | INTEGER | NULL allowed, FOREIGN KEY REFERENCES boost_packages(package_id) |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACTIVE', 'EXPIRED', 'REMOVED', 'SOLD')) |
| posted_at | TIMESTAMPTZ | NOT NULL |
| expires_at | TIMESTAMPTZ | NOT NULL |
| sold_at | TIMESTAMPTZ | NULL allowed |

### 6. Chat Threads
Stores conversations related to advertisements.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| thread_id | INTEGER | PRIMARY KEY, NOT NULL |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL |
| buyer_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| created_at | TIMESTAMPTZ | NOT NULL |

### 7. Chat Messages
Stores individual messages inside chat conversations.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| message_id | INTEGER | PRIMARY KEY, NOT NULL |
| thread_id | INTEGER | FOREIGN KEY REFERENCES chat_threads(thread_id), NOT NULL |
| sender_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| body | TEXT | NOT NULL |
| sent_at | TIMESTAMPTZ | NOT NULL |
| is_read | BOOLEAN | NOT NULL |

### 8. Offers
Stores offers made by buyers for advertisements.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| offer_id | INTEGER | PRIMARY KEY, NOT NULL |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL |
| buyer_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| offer_price | NUMERIC(12,2) | NOT NULL, CHECK (offer_price >= 0) |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACCEPTED', 'COUNTERED', 'PENDING', 'REJECTED')) |
| created_at | TIMESTAMPTZ | NOT NULL |
| responded_at | TIMESTAMPTZ | NULL allowed |

### 9. Favourites
Stores advertisements saved by users.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| user_id | INTEGER | PRIMARY KEY, FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| listing_id | INTEGER | PRIMARY KEY, FOREIGN KEY REFERENCES listings(listing_id), NOT NULL |
| saved_at | TIMESTAMPTZ | NOT NULL |

### 10. Reports
Stores reports submitted against advertisements.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| report_id | INTEGER | PRIMARY KEY, NOT NULL |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL |
| reporter_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| reason | VARCHAR(30) | NOT NULL, CHECK (reason IN ('ALREADY_SOLD', 'FRAUD', 'OFFENSIVE', 'SPAM', 'WRONG_CATEGORY')) |
| created_at | TIMESTAMPTZ | NOT NULL |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACTIONED', 'DISMISSED', 'OPEN')) |

### 11. Seller Ratings
Stores ratings and feedback given to sellers.

| Column | PostgreSQL Type | Constraints |
|---|---|---|
| rating_id | INTEGER | PRIMARY KEY, NOT NULL |
| seller_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| rater_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL |
| stars | SMALLINT | NOT NULL, CHECK (stars BETWEEN 1 AND 5) |
| comment | TEXT | NULL allowed |
| created_at | TIMESTAMPTZ | NOT NULL |


# Primary Keys
| Table | Primary key |
|---|---|
| cities | `city_id` |
| categories | `category_id` |
| boost_packages | `package_id` |
| users | `user_id` |
| listings | `listing_id` |
| chat_threads | `thread_id` |
| chat_messages | `message_id` |
| offers | `offer_id` |
| favourites | `(user_id, listing_id)` |
| reports | `report_id` |
| seller_ratings | `rating_id` |

The `favourites` table has composite primary key (uses two or more columns together to uniquely identify a row) allowing one user can save multiple listings and multiple users can save the same listing.

# Relationships

| Parent table | Child table | Relationship |
|---|---|---|
| cities | users | One-to-Many |
| cities | listings | One-to-Many |
| categories | listings | One-to-Many |
| categories | categories | One-to-Many |
| boost_packages | listings | One-to-Many |
| users | listings | One-to-Many |
| listings | chat_threads | One-to-Many |
| users | chat_threads | One-to-Many |
| chat_threads | chat_messages | One-to-Many |
| users | chat_messages | One-to-Many |
| listings | offers | One-to-Many |
| users | offers | One-to-Many|
| users | favourites | One-to-Many |
| listings | favourites | One-to-Many |
| listings | reports | One-to-Many |
| users | reports | One-to-Many |
| users | seller_ratings(seller_id) | One-to-Many  |
| users | seller_ratings(rater_id)| One-to-Many |
| listings | seller_ratings | One-to-Many |





# Database Constraints
We plan to use the following constraints:

1. Every table must have a primary key.
2. cities.city_name cannot be NULL.
3. categories.category_name cannot be NULL.
4. boost_packages.price must be greater than or equal to zero.
5. boost_packages.duration_days must be greater than zero.
6. listings.price must be greater than or equal to zero.
7. listings.image_count must be greater than or equal to zero.
8. listings.view_count must be greater than or equal to zero.
9. listings.latitude must be between -90 and 90.
10. listings.longitude must be between -180 and 180.
11. offers.offer_price must be greater than zero.
12. seller_ratings.stars must be between 1 and 5.
13. favourites must have a composite primary key on (user_id, listing_id).
14. categories.parent_id must reference an existing category.
15. Foreign keys must reference valid records in their respective parent tables.


# Normalisation 
