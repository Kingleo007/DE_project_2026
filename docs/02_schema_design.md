# OLX Used Goods Marketplace Database — Schema Design

## 1. Database Overview
The OLX marketplace database needs to manage users, advertisements, categories, offers, chats, favourites, reports, ratings, and boost packages.
The main objective is to maintain organised data, enforce relationships between tables, and support efficient searching, communication, and marketplace operations.

Tables will be created inside the PostgreSQL schema `olx`.

## 2. Tables

### 2.1 Overview
The database contains 11 relational tables. The schema uses primary keys, foreign keys, unique constraints, NOT NULL constraints, and CHECK constraints to maintain data integrity.

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

### 2.2 Data Dictionary
The following tables describe each column, its PostgreSQL type, its proposed constraints, and why the column is required.

### 1. Cities
Stores the cities in which advertisements and users are located.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| city_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each city and is referenced by users and listings. |
| city_name | VARCHAR(100) | NOT NULL | Stores the city name used for location-based browsing and reporting. |
| state | VARCHAR(100) | NOT NULL | Stores the state in which the city is located. |

### 2. Categories
Stores product categories and subcategories.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| category_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each category. |
| category_name | VARCHAR(100) | NOT NULL | Stores the category name used to classify listings. |
| parent_id | INTEGER | NULL allowed, FOREIGN KEY REFERENCES categories(category_id) | Links a subcategory to its parent category. It is NULL for a top-level category. |

### 3. Boost Packages
Stores available advertisement promotion packages.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| package_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each boost package. |
| package_name | VARCHAR(100) | NOT NULL | Stores the package name shown to users. |
| price | NUMERIC(10,2) | NOT NULL, CHECK (price >= 0) | Stores the package price accurately using a decimal type and prevents negative prices. |
| duration_days | INTEGER | NOT NULL, CHECK (duration_days > 0) | Stores how long the boost lasts and prevents zero or negative durations. |

### 4. Users
Stores information about marketplace users. A user can act as both a buyer and a seller.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| user_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each marketplace user and is referenced by activity tables. |
| full_name | VARCHAR(150) | NOT NULL | Stores the user's name for account and marketplace display. |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | Stores the mobile number used for login and contact; it must be present and unique. |
| email | VARCHAR(255) | UNIQUE, NULL allowed | Stores an optional email address. It may be empty when a user has not supplied one. |
| city_id | INTEGER | FOREIGN KEY REFERENCES cities(city_id), NOT NULL | Identifies the user's city and links it to the cities table. |
| phone_verified | BOOLEAN | NOT NULL | Records whether the user's phone number has been verified. |
| is_banned | BOOLEAN | NOT NULL | Records whether the account is banned. |
| joined_at | TIMESTAMPTZ | NOT NULL | Stores the account creation time, including its time-zone offset. |

### 5. Listings
Stores advertisements posted by sellers.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| listing_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each advertisement. |
| seller_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the user who posted the advertisement. |
| category_id | INTEGER | FOREIGN KEY REFERENCES categories(category_id), NOT NULL | Identifies the category to which the advertisement belongs. |
| title | VARCHAR(255) | NOT NULL | Stores the advertisement title used in search results and listing pages. |
| description | TEXT | NULL allowed | Stores additional details about the item. It can be empty if the seller does not provide a description. |
| price | NUMERIC(12,2) | NOT NULL, CHECK (price >= 0) | Stores the asking price accurately and prevents negative prices. |
| is_negotiable | BOOLEAN | NOT NULL | Records whether the seller is willing to negotiate the asking price. |
| item_condition | VARCHAR(20) | NOT NULL, CHECK (item_condition IN ('FAIR', 'GOOD', 'LIKE_NEW', 'NEW')) | Stores the item's condition using the allowed condition values. |
| attributes | JSONB | NOT NULL | Stores category-specific details, such as car fuel type or phone storage, without requiring separate columns for every category. |
| city_id | INTEGER | FOREIGN KEY REFERENCES cities(city_id), NOT NULL | Identifies the city in which the advertisement is located. |
| locality | VARCHAR(150) | NOT NULL | Stores the local area or neighbourhood for more specific location information. |
| latitude | NUMERIC(9,6) | NOT NULL, CHECK (latitude BETWEEN -90 AND 90) | Stores the geographic latitude and prevents values outside the valid range. |
| longitude | NUMERIC(9,6) | NOT NULL, CHECK (longitude BETWEEN -180 AND 180) | Stores the geographic longitude and prevents values outside the valid range. |
| image_count | INTEGER | NOT NULL, CHECK (image_count >= 0) | Stores the number of images attached to the advertisement and prevents negative counts. |
| view_count | INTEGER | NOT NULL, CHECK (view_count >= 0) | Stores the number of views. It is a maintained counter used for marketplace statistics. |
| boost_package_id | INTEGER | NULL allowed, FOREIGN KEY REFERENCES boost_packages(package_id) | Identifies the purchased boost package. It is NULL when the advertisement has not been boosted. |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACTIVE', 'EXPIRED', 'REMOVED', 'SOLD')) | Records the current advertisement status using allowed values. |
| posted_at | TIMESTAMPTZ | NOT NULL | Stores when the advertisement was posted, including its time-zone offset. |
| expires_at | TIMESTAMPTZ | NOT NULL | Stores when the advertisement is due to expire. |
| sold_at | TIMESTAMPTZ | NULL allowed | Stores when the item was sold. It is NULL when the advertisement has not been sold. |

### 6. Chat Threads
Stores conversations related to advertisements.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| thread_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each conversation. |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Identifies the advertisement about which the conversation is taking place. |
| buyer_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the buyer who started the conversation. |
| created_at | TIMESTAMPTZ | NOT NULL | Stores when the conversation was created. |

### 7. Chat Messages
Stores individual messages inside chat conversations.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| message_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each message. |
| thread_id | INTEGER | FOREIGN KEY REFERENCES chat_threads(thread_id), NOT NULL | Identifies the conversation to which the message belongs. |
| sender_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the user who sent the message. |
| body | TEXT | NOT NULL | Stores the message content. |
| sent_at | TIMESTAMPTZ | NOT NULL | Stores when the message was sent. |
| is_read | BOOLEAN | NOT NULL | Records whether the message has been read. |

### 8. Offers
Stores offers made by buyers for advertisements.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| offer_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each offer. |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Identifies the advertisement for which the offer was made. |
| buyer_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the buyer who made the offer. |
| offer_price | NUMERIC(12,2) | NOT NULL, CHECK (offer_price >= 0) | Stores the buyer's offered amount accurately and prevents negative values. |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACCEPTED', 'COUNTERED', 'PENDING', 'REJECTED')) | Records the current offer status using allowed values. |
| created_at | TIMESTAMPTZ | NOT NULL | Stores when the offer was created. |
| responded_at | TIMESTAMPTZ | NULL allowed | Stores when the seller responded. It is NULL while no response has been recorded. |

### 9. Favourites
Stores advertisements saved by users.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| user_id | INTEGER | PRIMARY KEY, FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the user who saved the advertisement and forms part of the composite primary key. |
| listing_id | INTEGER | PRIMARY KEY, FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Identifies the saved advertisement and forms part of the composite primary key. |
| saved_at | TIMESTAMPTZ | NOT NULL | Stores when the user saved the advertisement. |

### 10. Reports
Stores reports submitted against advertisements.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| report_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each report. |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Identifies the advertisement being reported. |
| reporter_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the user who submitted the report. |
| reason | VARCHAR(30) | NOT NULL, CHECK (reason IN ('ALREADY_SOLD', 'FRAUD', 'OFFENSIVE', 'SPAM', 'WRONG_CATEGORY')) | Stores the reason for the report using allowed values. |
| created_at | TIMESTAMPTZ | NOT NULL | Stores when the report was submitted. |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACTIONED', 'DISMISSED', 'OPEN')) | Records the moderation status of the report. |

### 11. Seller Ratings
Stores ratings and feedback given to sellers.

| Column | PostgreSQL Type | Constraints | Why |
|---|---|---|---|
| rating_id | INTEGER | PRIMARY KEY, NOT NULL | Uniquely identifies each seller rating. |
| seller_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the seller receiving the rating. |
| rater_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Identifies the user who submitted the rating. |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Identifies the advertisement associated with the rating. |
| stars | SMALLINT | NOT NULL, CHECK (stars BETWEEN 1 AND 5) | Stores the rating score and restricts it to the valid 1–5 range. |
| comment | TEXT | NULL allowed | Stores optional written feedback. It can be NULL when the user gives only a star rating. |
| created_at | TIMESTAMPTZ | NOT NULL | Stores when the rating was submitted. |

## 3. Primary Keys

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

The `favourites` table has a composite primary key (uses two or more columns together to uniquely identify a row), allowing one user to save multiple listings and multiple users to save the same listing. The combination prevents the same user from saving the same listing more than once.

## 4. Relationships

| Parent table | Child table | Relationship |
|---|---|---|
| cities | users | One-to-Many |
| cities | listings | One-to-Many |
| categories | listings | One-to-Many |
| categories | categories | One-to-Many (self-referencing parent/subcategory) |
| boost_packages | listings | One-to-Many; a listing may have no package |
| users | listings | One-to-Many |
| listings | chat_threads | One-to-Many |
| users | chat_threads | One-to-Many (as buyer) |
| chat_threads | chat_messages | One-to-Many |
| users | chat_messages | One-to-Many (as sender) |
| listings | offers | One-to-Many |
| users | offers | One-to-Many (as buyer) |
| users | favourites | One-to-Many |
| listings | favourites | One-to-Many |
| listings | reports | One-to-Many |
| users | reports | One-to-Many (as reporter) |
| users | seller_ratings (`seller_id`) | One-to-Many (as rated seller) |
| users | seller_ratings (`rater_id`) | One-to-Many (as rating author) |
| listings | seller_ratings | One-to-Many |

The `favourites` table resolves the many-to-many relationship between users and listings: one user can favourite many listings, and one listing can be favourited by many users.

## 5. ER Diagram

**Notation used**
- **Rectangles** represent entities.
- **Diamonds** represent relationships.
- **Ovals** represent attributes.
- Primary-key attributes are underlined.
- Cardinalities are written beside the relationship lines as `1`, `0..1`, or `0..N`.
- Foreign-key columns are represented by relationships rather than repeated as ordinary attributes. The FK columns still exist in the relational tables generated from this conceptual model.

---

## A. Core Marketplace

```mermaid
flowchart LR
    CITIES[ CITIES ]
    USERS[ USERS ]
    CATEGORIES[ CATEGORIES ]
    BOOST_PACKAGES[ BOOST_PACKAGES ]
    LISTINGS[ LISTINGS ]

    R_USER_CITY{ lives in }
    R_LISTING_CITY{ located in }
    R_CLASSIFIES{ classified as }
    R_PARENT{ parent of }
    R_BOOST{ has boost package }
    R_POSTS{ posts }

    CITIES ---|1| R_USER_CITY
    R_USER_CITY ---|0..N| USERS

    CITIES ---|1| R_LISTING_CITY
    R_LISTING_CITY ---|0..N| LISTINGS

    CATEGORIES ---|1| R_CLASSIFIES
    R_CLASSIFIES ---|0..N| LISTINGS

    CATEGORIES ---|0..1 parent| R_PARENT
    R_PARENT ---|0..N children| CATEGORIES

    BOOST_PACKAGES ---|0..N| R_BOOST
    R_BOOST ---|0..1| LISTINGS

    USERS ---|0..N| R_POSTS
    R_POSTS ---|1| LISTINGS

    CITIES --- A_CITY_ID(["<u>city_id</u> : int"])
    CITIES --- A_CITY_NAME(["city_name : varchar"])
    CITIES --- A_CITY_STATE(["state : varchar"])

    USERS --- A_USER_ID(["<u>user_id</u> : int"])
    USERS --- A_FULL_NAME(["full_name : varchar"])
    USERS --- A_PHONE(["phone : varchar (unique)"])
    USERS --- A_EMAIL(["email : varchar (unique)"])
    USERS --- A_PHONE_VERIFIED(["phone_verified : boolean"])
    USERS --- A_IS_BANNED(["is_banned : boolean"])
    USERS --- A_JOINED_AT(["joined_at : timestamptz"])

    CATEGORIES --- A_CATEGORY_ID(["<u>category_id</u> : int"])
    CATEGORIES --- A_CATEGORY_NAME(["category_name : varchar"])

    BOOST_PACKAGES --- A_PACKAGE_ID(["<u>package_id</u> : int"])
    BOOST_PACKAGES --- A_PACKAGE_NAME(["package_name : varchar"])
    BOOST_PACKAGES --- A_PACKAGE_PRICE(["price : numeric"])
    BOOST_PACKAGES --- A_DURATION(["duration_days : int"])

    LISTINGS --- A_LISTING_ID(["<u>listing_id</u> : int"])
    LISTINGS --- A_TITLE(["title : varchar"])
    LISTINGS --- A_DESCRIPTION(["description : text"])
    LISTINGS --- A_PRICE(["price : numeric"])
    LISTINGS --- A_NEGOTIABLE(["is_negotiable : boolean"])
    LISTINGS --- A_CONDITION(["item_condition : varchar"])
    LISTINGS --- A_ATTRIBUTES(["attributes : jsonb"])
    LISTINGS --- A_LOCALITY(["locality : varchar"])
    LISTINGS --- A_LATITUDE(["latitude : numeric"])
    LISTINGS --- A_LONGITUDE(["longitude : numeric"])
    LISTINGS --- A_IMAGE_COUNT(["image_count : int"])
    LISTINGS --- A_VIEW_COUNT(["view_count : int"])
    LISTINGS --- A_STATUS(["status : varchar"])
    LISTINGS --- A_POSTED_AT(["posted_at : timestamptz"])
    LISTINGS --- A_EXPIRES_AT(["expires_at : timestamptz"])
    LISTINGS --- A_SOLD_AT(["sold_at : timestamptz"])

    classDef entity fill:#ffffff,stroke:#222222,stroke-width:2px,color:#111111;
    classDef relationship fill:#fff4cc,stroke:#222222,stroke-width:1.5px,color:#111111;
    classDef attribute fill:#eaf3ff,stroke:#222222,stroke-width:1px,color:#111111;
    class CITIES,USERS,CATEGORIES,BOOST_PACKAGES,LISTINGS entity;
    class R_USER_CITY,R_LISTING_CITY,R_CLASSIFIES,R_PARENT,R_BOOST,R_POSTS relationship;
    class A_CITY_ID,A_CITY_NAME,A_CITY_STATE,A_USER_ID,A_FULL_NAME,A_PHONE,A_EMAIL,A_PHONE_VERIFIED,A_IS_BANNED,A_JOINED_AT,A_CATEGORY_ID,A_CATEGORY_NAME,A_PACKAGE_ID,A_PACKAGE_NAME,A_PACKAGE_PRICE,A_DURATION,A_LISTING_ID,A_TITLE,A_DESCRIPTION,A_PRICE,A_NEGOTIABLE,A_CONDITION,A_ATTRIBUTES,A_LOCALITY,A_LATITUDE,A_LONGITUDE,A_IMAGE_COUNT,A_VIEW_COUNT,A_STATUS,A_POSTED_AT,A_EXPIRES_AT,A_SOLD_AT attribute;
```

**Core relationship meaning**
- Every user belongs to exactly one city; a city can have zero or many users.
- Every listing belongs to exactly one city and one category; each city/category can be associated with zero or many listings.
- A category can have zero or one parent category. A parent category can have zero or many child categories.
- A listing can have zero or one boost package. A boost package can be used by zero or many listings.
- Every listing is posted by exactly one user; a user can post zero or many listings.

---

## B. Chat System

```mermaid
flowchart LR
    USERS[ USERS ]
    LISTINGS[ LISTINGS ]
    CHAT_THREADS[ CHAT_THREADS ]
    CHAT_MESSAGES[ CHAT_MESSAGES ]

    R_BUYER_OPENS{ opens as buyer }
    R_LISTING_CHAT{ discussed in }
    R_CONTAINS{ contains }
    R_SENDS{ sends }

    USERS ---|0..N| R_BUYER_OPENS
    R_BUYER_OPENS ---|1| CHAT_THREADS

    LISTINGS ---|0..N| R_LISTING_CHAT
    R_LISTING_CHAT ---|1| CHAT_THREADS

    CHAT_THREADS ---|1| R_CONTAINS
    R_CONTAINS ---|0..N| CHAT_MESSAGES

    USERS ---|0..N| R_SENDS
    R_SENDS ---|1| CHAT_MESSAGES

    USERS --- A_USER_ID(["<u>user_id</u> : int"])
    LISTINGS --- A_LISTING_ID(["<u>listing_id</u> : int"])

    CHAT_THREADS --- A_THREAD_ID(["<u>thread_id</u> : int"])
    CHAT_THREADS --- A_CREATED_AT(["created_at : timestamptz"])

    CHAT_MESSAGES --- A_MESSAGE_ID(["<u>message_id</u> : int"])
    CHAT_MESSAGES --- A_BODY(["body : text"])
    CHAT_MESSAGES --- A_SENT_AT(["sent_at : timestamptz"])
    CHAT_MESSAGES --- A_IS_READ(["is_read : boolean"])

    classDef entity fill:#ffffff,stroke:#222222,stroke-width:2px,color:#111111;
    classDef relationship fill:#fff4cc,stroke:#222222,stroke-width:1.5px,color:#111111;
    classDef attribute fill:#eaf3ff,stroke:#222222,stroke-width:1px,color:#111111;
    class USERS,LISTINGS,CHAT_THREADS,CHAT_MESSAGES entity;
    class R_BUYER_OPENS,R_LISTING_CHAT,R_CONTAINS,R_SENDS relationship;
    class A_USER_ID,A_LISTING_ID,A_THREAD_ID,A_CREATED_AT,A_MESSAGE_ID,A_BODY,A_SENT_AT,A_IS_READ attribute;
```

**Chat relationship meaning**
- Every chat thread has exactly one buyer; a user can open zero or many threads.
- Every chat thread is about exactly one listing; a listing can have zero or many threads.
- Every message belongs to exactly one thread; a thread can contain zero or many messages.
- Every message is sent by exactly one user; a user can send zero or many messages.

`USERS` and `LISTINGS` are the same entities shown in the Core Marketplace diagram. Their full attributes and the seller-posts-listing relationship are defined there; this chat diagram shows only the identifying keys needed by this part of the model.

---

## C. Offers and Favourites

```mermaid
flowchart LR
    USERS[ USERS ]
    LISTINGS[ LISTINGS ]
    OFFERS[ OFFERS ]

    R_MAKES{ makes }
    R_RECEIVES{ receives }
    R_FAVOURITES{ favourites / saves }

    USERS ---|0..N| R_MAKES
    R_MAKES ---|1| OFFERS

    LISTINGS ---|0..N| R_RECEIVES
    R_RECEIVES ---|1| OFFERS

    USERS ---|0..N| R_FAVOURITES
    R_FAVOURITES ---|0..N| LISTINGS

    USERS --- A_USER_ID(["<u>user_id</u> : int"])
    LISTINGS --- A_LISTING_ID(["<u>listing_id</u> : int"])

    OFFERS --- A_OFFER_ID(["<u>offer_id</u> : int"])
    OFFERS --- A_OFFER_PRICE(["offer_price : numeric"])
    OFFERS --- A_OFFER_STATUS(["status : varchar"])
    OFFERS --- A_OFFER_CREATED(["created_at : timestamptz"])
    OFFERS --- A_OFFER_RESPONDED(["responded_at : timestamptz"])

    R_FAVOURITES --- A_SAVED_AT(["saved_at : timestamptz"])

    classDef entity fill:#ffffff,stroke:#222222,stroke-width:2px,color:#111111;
    classDef relationship fill:#fff4cc,stroke:#222222,stroke-width:1.5px,color:#111111;
    classDef attribute fill:#eaf3ff,stroke:#222222,stroke-width:1px,color:#111111;
    class USERS,LISTINGS,OFFERS entity;
    class R_MAKES,R_RECEIVES,R_FAVOURITES relationship;
    class A_USER_ID,A_LISTING_ID,A_OFFER_ID,A_OFFER_PRICE,A_OFFER_STATUS,A_OFFER_CREATED,A_OFFER_RESPONDED,A_SAVED_AT attribute;
```

**Offers and favourites relationship meaning**
- Every offer is made by exactly one user; a user can make zero or many offers.
- Every offer is for exactly one listing; a listing can receive zero or many offers.
- Users can save zero or many listings, and listings can be saved by zero or many users. Therefore, `FAVOURITES` is an **M:N relationship** in Chen notation.

In the relational schema, `FAVOURITES` is the junction table with composite primary key `(user_id, listing_id)`. In the Chen diagram, it is represented as the `favourites / saves` relationship, and `saved_at` is an attribute of that relationship.

---

## D. Reports and Seller Ratings

```mermaid
flowchart LR
    USERS[ USERS ]
    LISTINGS[ LISTINGS ]
    REPORTS[ REPORTS ]
    SELLER_RATINGS[ SELLER_RATINGS ]

    R_REPORTS{ reports }
    R_REPORTED{ is reported }
    R_RECEIVES_RATING{ receives rating }
    R_GIVES_RATING{ gives rating }
    R_RATES_LISTING{ rates listing }

    USERS ---|0..N| R_REPORTS
    R_REPORTS ---|1| REPORTS

    LISTINGS ---|0..N| R_REPORTED
    R_REPORTED ---|1| REPORTS

    USERS ---|0..N| R_RECEIVES_RATING
    R_RECEIVES_RATING ---|1| SELLER_RATINGS

    USERS ---|0..N| R_GIVES_RATING
    R_GIVES_RATING ---|1| SELLER_RATINGS

    LISTINGS ---|0..N| R_RATES_LISTING
    R_RATES_LISTING ---|1| SELLER_RATINGS

    USERS --- A_USER_ID(["<u>user_id</u> : int"])
    LISTINGS --- A_LISTING_ID(["<u>listing_id</u> : int"])

    REPORTS --- A_REPORT_ID(["<u>report_id</u> : int"])
    REPORTS --- A_REASON(["reason : varchar"])
    REPORTS --- A_REPORT_CREATED(["created_at : timestamptz"])
    REPORTS --- A_REPORT_STATUS(["status : varchar"])

    SELLER_RATINGS --- A_RATING_ID(["<u>rating_id</u> : int"])
    SELLER_RATINGS --- A_STARS(["stars : smallint"])
    SELLER_RATINGS --- A_COMMENT(["comment : text"])
    SELLER_RATINGS --- A_RATING_CREATED(["created_at : timestamptz"])

    classDef entity fill:#ffffff,stroke:#222222,stroke-width:2px,color:#111111;
    classDef relationship fill:#fff4cc,stroke:#222222,stroke-width:1.5px,color:#111111;
    classDef attribute fill:#eaf3ff,stroke:#222222,stroke-width:1px,color:#111111;
    class USERS,LISTINGS,REPORTS,SELLER_RATINGS entity;
    class R_REPORTS,R_REPORTED,R_RECEIVES_RATING,R_GIVES_RATING,R_RATES_LISTING relationship;
    class A_USER_ID,A_LISTING_ID,A_REPORT_ID,A_REASON,A_REPORT_CREATED,A_REPORT_STATUS,A_RATING_ID,A_STARS,A_COMMENT,A_RATING_CREATED attribute;
```

**Reports and seller ratings relationship meaning**
- Every report is submitted by exactly one user and concerns exactly one listing. A user can submit zero or many reports, and a listing can receive zero or many reports.
- Every seller rating identifies exactly one seller (the user receiving the rating), exactly one rater (the user giving the rating), and exactly one listing being rated.
- A user can receive zero or many seller ratings and can give zero or many seller ratings. A listing can have zero or many seller ratings.

The two relationships between `USERS` and `SELLER_RATINGS` are separate roles: **receives rating** uses `seller_id`, while **gives rating** uses `rater_id`.

`USERS` and `LISTINGS` are the same entities as in the Core Marketplace diagram. Their full attributes are defined there.

---

# Functional Dependencies (FDs)
A functional dependency `X → Y` means that X determines Y.

| Table | Functional dependency |
|---|---|
| cities | `city_id → city_name, state` |
| categories | `category_id → category_name, parent_id` |
| boost_packages | `package_id → package_name, price, duration_days` |
| users | `user_id → all other user columns` |
| listings | `listing_id → all other listing columns` |
| chat_threads | `thread_id → listing_id, buyer_id, created_at` |
| chat_messages | `message_id → all other message columns` |
| offers | `offer_id → all other offer columns` |
| favourites | `(user_id, listing_id) → saved_at` |
| reports | `report_id → all other report columns` |
| seller_ratings | `rating_id → all other rating columns` |

# Normal Form Per Table
All tables are expected to be in **3NF**. They are also expected to be in **BCNF** if the listed primary keys (and any confirmed candidate keys) are valid.

| Table | Normal form | Reason |
|---|---|---|
| cities | BCNF | City ID determines the city details. |
| categories | BCNF | Category ID determines the category details. |
| boost_packages | BCNF | Package ID determines package details. |
| users | BCNF | User ID determines user details. |
| listings | BCNF | Listing ID determines listing details. |
| chat_threads | BCNF | Thread ID determines conversation details. |
| chat_messages | BCNF | Message ID determines message details. |
| offers | BCNF | Offer ID determines offer details. |
| favourites | BCNF | The two-column key determines the saved timestamp. |
| reports | BCNF | Report ID determines report details. |
| seller_ratings | BCNF | Rating ID determines rating details. |

This assessment is based on the proposed keys and columns. It should be confirmed if data inspection reveals additional functional dependencies.

# Integrity-Check Results

<!-- Run these checks after loading the data. Record the actual result returned by PostgreSQL. -->
<!-- Need to do -->
| Check | SQL condition | Result |
|---|---|---|
| Listing sold before posting | `sold_at < posted_at` where `sold_at IS NOT NULL` | PENDING |
| Listing expires before posting | `expires_at <= posted_at` | PENDING |
| Buyer chats on own listing | `chat_threads.buyer_id = listings.seller_id` | PENDING |
| Message sent by someone outside the chat | Sender is neither the buyer nor listing seller | PENDING |
| Rating seller differs from listing seller | `seller_ratings.seller_id <> listings.seller_id` | PENDING |
| User rates themselves | `rater_id = seller_id` | PENDING |

<!-- Queries: -->

<!-- ```sql
-- 1. Sold before posted
-- SELECT COUNT(*)
-- FROM olx.listings
-- WHERE sold_at IS NOT NULL AND sold_at < posted_at;

-- -- 2. Expires before or at posted time
-- SELECT COUNT(*)
-- FROM olx.listings
-- WHERE expires_at <= posted_at;

-- -- 3. Buyer chats about their own listing
-- SELECT COUNT(*)
-- FROM olx.chat_threads ct
-- JOIN olx.listings l ON l.listing_id = ct.listing_id
-- WHERE ct.buyer_id = l.seller_id;

-- -- 4. Message sender is not a buyer or seller
-- SELECT COUNT(*)
-- FROM olx.chat_messages cm
-- JOIN olx.chat_threads ct ON ct.thread_id = cm.thread_id
-- JOIN olx.listings l ON l.listing_id = ct.listing_id
-- WHERE cm.sender_id NOT IN (ct.buyer_id, l.seller_id);

-- -- 5. Rating seller does not match listing seller
-- SELECT COUNT(*)
-- FROM olx.seller_ratings sr
-- JOIN olx.listings l ON l.listing_id = sr.listing_id
-- WHERE sr.seller_id <> l.seller_id;

-- -- 6. User rates themselves
-- SELECT COUNT(*)
-- FROM olx.seller_ratings
-- WHERE rater_id = seller_id;
-- ``` -->

# Data Problems Found

| Problem | Details / action |
|---|---|
| `chat_threads` key/type mismatch in an earlier SQL draft | The earlier draft used `id SERIAL` as the primary key and made `thread_id` TEXT. `chat_messages.thread_id` is INTEGER. Use `thread_id INTEGER PRIMARY KEY` in `chat_threads` so the foreign key matches. |
| `offers.offer_price` constraint mismatch | The column definition says `>= 0`, while the constraint list says `> 0`. Check the CSV and use one rule consistently. |
| Possible duplicate chat, report, or rating pairs | The primary keys do not prevent duplicate buyer/listing chats, reporter/listing reports, or rater/listing ratings. Check the data before adding UNIQUE constraints. |
| Possible seller mismatch in ratings | `seller_ratings.seller_id` should match the seller of the related listing. Check this with the integrity query above. |
| Possible invalid chat participants | Basic foreign keys do not ensure that a message sender is the buyer or seller in that conversation. Check this with the integrity query above. |

**Note:** The complete set of 11 CSV files has not been checked. Therefore, the integrity results above are marked PENDING, and no additional data errors or zero-violation results are claimed. Need to test them soon. 
