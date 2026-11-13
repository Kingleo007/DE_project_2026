-- R19
SELECT l.listing_id, l.title,
       (SELECT count(*) FROM chat_threads t WHERE t.listing_id = l.listing_id) AS chats,
       (SELECT max(m.sent_at) FROM chat_messages m JOIN chat_threads t ON t.thread_id = m.thread_id
         WHERE t.listing_id = l.listing_id) AS last_chat_at
FROM listings l
WHERE l.category_id = 2 AND l.city_id = 1 AND l.status = 'ACTIVE'
ORDER BY chats DESC;