# Problem Understanding

# Overview

## What is OLX?
OLX is an online marketplace where people can buy and sell second-hand or used products directly with other people.

## Our Task
Rebuild OLX’s database schema using the provided CSV files and measure query performance.
Optimize the slow queries. Maybe test database scalability with larger datasets.


# 2. Business Problems

## P1. Browse and Search
Buyers experience slow browsing and searching when applying filters such as price, car details, product category and location.
Requirement: The database should retrieve items quickly based as per buyer’s filters.
Stakeholder: Buyers
Classification: Customer-facing / Real-time

## P2. Ads Management
Sellers need to create, update, and manage their advertisements, including changing prices, updating descriptions, and marking items as sold or inactive.
Requirement: Load advertisements page, display them, create advertisements, and update them efficiently.
Stakeholder: Sellers
Classification: Customer-facing / Real-time

## P3. Chat Inbox
Takes too long to load the list of conversations, The unread message count takes too long to update or display, messages take too long to send or appear in the conversation.
Requirement: Load chat , display unread message counts, and send messages faster.
Stakeholder: Buyers and Sellers
Classification: Customer-facing / Real-time

## P4. Moderation
Report queues are slow, spam bursts are hard to detect, duplicate ads are hard to find.
Requirement: Faster identification of reported advertisements, spam activity, and duplicate ads is needed.
Stakeholder: Trust & Safety / Moderation 
Classification: Customer-facing / Real-time

## P5. Boost Package Analysis
Boost purchases are hard to track, unused boosts are hard to track, and revenue is difficult to calculate.
Requirement: Identify boost packages that have never been purchased and support monetisation decisions.
Stakeholder: Monetisation Team
Classification: Reporting / Analytics

## P6. Category Insights
Category insights take too long to load. Category managers struggle to find the right price for products, see how long items take to sell, check how often offers are accepted, and track how quickly sellers respond.
Requirement: Calculate average selling prices, time taken to sell, offer acceptance rates, and seller response times for each category.
Stakeholder: Category Managers
Classification: Reporting / Analytics

## P7. Growth Report
Growth reports take too long to generate, reminders and nightly database tasks are slow, and the database needs to handle 20× more advertisements in the future.
Requirement: Generate growth reports, process reminder, nightly tasks quicker and prepare database to handle 20× data growth.
Stakeholder: Growth / Platform Team
Classification: Reporting / Analytics and Batch Processing


# 3. Assumptions

1. Every advertisement belongs to one seller and one category 
2. A user can buy and sell products.
3. One seller can post multiple advertisements.
4. Users can save advertisements to their favourites, report them too if needed.
5. Buyers and sellers can chat about an advertisement and one chat can have many messages.
6. Sellers can mark their advertisements as sold.
7. Users can buy boost packages to promote their advertisements (optional).
8. Buyers can rate sellers after a purchase.


# 4. Conclusion
The OLX marketplace database needs to manage users, advertisements, categories, offers, chats, reports, ratings, and boost packages.
Our main goal is to build a database that makes searching, buying, selling, and communication faster and easier. It should also help the platform manage reports, understand category performance, track revenue, and handle future data growth.
