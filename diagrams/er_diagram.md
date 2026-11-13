# ER Diagrams

## Diagram 1: Core Marketplace
Shows users, cities, categories, listings and boost packages.

```mermaid
erDiagram
    CITIES ||--o{ USERS : "user location"
    CITIES ||--o{ LISTINGS : "listing location"
    CATEGORIES ||--o{ LISTINGS : "classifies"
    CATEGORIES o|--o{ CATEGORIES : "parent category"
    BOOST_PACKAGES o|--o{ LISTINGS : "optional boost"
    USERS ||--o{ LISTINGS : "posts"

    CITIES {
        int city_id PK
        varchar city_name
        varchar state
    }

    USERS {
        int user_id PK
        varchar full_name
        varchar phone UK
        varchar email UK
        int city_id FK
        boolean phone_verified
        boolean is_banned
        timestamptz joined_at
    }

    CATEGORIES {
        int category_id PK
        varchar category_name
        int parent_id FK
    }

    BOOST_PACKAGES {
        int package_id PK
        varchar package_name
        numeric price
        int duration_days
    }

    LISTINGS {
        int listing_id PK
        int seller_id FK
        int category_id FK
        varchar title
        text description
        numeric price
        boolean is_negotiable
        varchar item_condition
        jsonb attributes
        int city_id FK
        varchar locality
        numeric latitude
        numeric longitude
        int image_count
        int view_count
        int boost_package_id FK
        varchar status
        timestamptz posted_at
        timestamptz expires_at
        timestamptz sold_at
    }
```

## Diagram 2: Chat System
Shows buyers starting conversations about listings and users exchanging messages.

```mermaid
erDiagram
    USERS ||--o{ CHAT_THREADS : "buyer opens"
    LISTINGS ||--o{ CHAT_THREADS : "discussed in"
    CHAT_THREADS ||--o{ CHAT_MESSAGES : "contains"
    USERS ||--o{ CHAT_MESSAGES : "sends"

    USERS {
        int user_id PK
    }

    LISTINGS {
        int listing_id PK
        int seller_id FK
    }

    CHAT_THREADS {
        int thread_id PK
        int listing_id FK
        int buyer_id FK
        timestamptz created_at
    }

    CHAT_MESSAGES {
        int message_id PK
        int thread_id FK
        int sender_id FK
        text body
        timestamptz sent_at
        boolean is_read
    }
```

## Diagram 3: Offers and Favourites
Shows offers made by buyers and listings saved by users.

```mermaid
erDiagram
    USERS ||--o{ OFFERS : "makes"
    LISTINGS ||--o{ OFFERS : "receives"
    USERS ||--o{ FAVOURITES : "saves"
    LISTINGS ||--o{ FAVOURITES : "is saved"

    USERS {
        int user_id PK
    }

    LISTINGS {
        int listing_id PK
    }

    OFFERS {
        int offer_id PK
        int listing_id FK
        int buyer_id FK
        numeric offer_price
        varchar status
        timestamptz created_at
        timestamptz responded_at
    }

    FAVOURITES {
        int user_id PK, FK
        int listing_id PK, FK
        timestamptz saved_at
    }
```

## Diagram 4: Reports and Seller Ratings
Shows users reporting listings and giving ratings to sellers.

```mermaid
erDiagram
    USERS ||--o{ REPORTS : "reports"
    LISTINGS ||--o{ REPORTS : "is reported"
    USERS ||--o{ SELLER_RATINGS : "receives rating"
    USERS ||--o{ SELLER_RATINGS : "gives rating"
    LISTINGS ||--o{ SELLER_RATINGS : "rated listing"

    USERS {
        int user_id PK
    }

    LISTINGS {
        int listing_id PK
        int seller_id FK
    }

    REPORTS {
        int report_id PK
        int listing_id FK
        int reporter_id FK
        varchar reason
        timestamptz created_at
        varchar status
    }

    SELLER_RATINGS {
        int rating_id PK
        int seller_id FK
        int rater_id FK
        int listing_id FK
        smallint stars
        text comment
        timestamptz created_at
    }
```
