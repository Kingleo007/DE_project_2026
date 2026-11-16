# ER Diagram
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