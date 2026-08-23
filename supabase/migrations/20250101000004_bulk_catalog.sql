-- ============================================================
-- QuickKart - bada catalog (migration 5)
--
-- Har category ke liye 25 brands x 25 items x 8 variants = 5000 SKUs,
-- 6 categories = 30,000 products. Rows database ke andar hi CROSS JOIN
-- se bante hain, isliye migration file chhoti rehti hai.
--
-- Images: har category ke apne existing verified photos round-robin
-- assign hoti hain (dekhein migration 4).
-- ============================================================
-- NOTE: price ko jaan-bujhkar ek alag CTE (priced) mein compute kiya gaya hai.
-- Agar cross join lateral (select round(... random() ...)) use karein to Postgres
-- us uncorrelated subquery ko SIRF EK BAAR evaluate karta hai, aur poori category
-- ke saare products ka price same aa jaata hai.

-- @@SPLIT@@ grocery: 25 x 25 x 8 = 5000
with imgs as (select array_agg(image_url order by id) as urls from products where image_url is not null and category_id = 'grocery'),
gen as (select b.brand, i.item, u.unit, row_number() over () as rn
  from unnest(array['Amul','Britannia','Tata','Aashirvaad','Fortune','Nestle','Parle','Mother Dairy','Patanjali','MTR','Haldiram''s','Saffola','Everest','MDH','Dabur','Kissan','Maggi','Bikano','Catch','Del Monte','Nandini','Sunfeast','Bingo','Real','Tropicana']::text[]) as b(brand)
  cross join unnest(array['Milk','Butter','Cheese Slices','Curd','Paneer','Atta','Basmati Rice','Sugar','Salt','Green Tea','Instant Coffee','Biscuits','Bread','Noodles','Ketchup','Mixed Fruit Jam','Honey','Cow Ghee','Mustard Oil','Refined Oil','Besan','Poha','Dalia','Sooji','Maida']::text[]) as i(item)
  cross join unnest(array['100 g','200 g','500 g','1 kg','5 kg','200 ml','500 ml','1 L']::text[]) as u(unit)),
priced as (select g.brand || ' ' || g.item as name, g.unit, g.rn,
  round(20 + random() * 580) as price from gen g)
insert into products (name, unit, category_id, price, mrp, icon, image_url, is_active, stock)
select p.name, p.unit, 'grocery', p.price,
  round(p.price * (1.08 + random() * 0.30)), '🛒',
  case when im.urls is null then null else im.urls[1 + (p.rn % array_length(im.urls, 1))] end,
  true, (50 + floor(random() * 200))::int
from priced p
left join imgs im on true;

-- @@SPLIT@@ electronics: 25 x 25 x 8 = 5000
with imgs as (select array_agg(image_url order by id) as urls from products where image_url is not null and category_id = 'electronics'),
gen as (select b.brand, i.item, u.unit, row_number() over () as rn
  from unnest(array['boAt','JBL','Sony','Samsung','Realme','Mi','OnePlus','Noise','Portronics','Ambrane','Zebronics','Philips','Havells','Syska','Wipro','Anker','Boult','Fire-Boltt','pTron','Lenovo','HP','Logitech','Intex','iBall','Croma']::text[]) as b(brand)
  cross join unnest(array['Wireless Earbuds','Bluetooth Speaker','Power Bank','USB-C Cable','Fast Charger','Neckband','Smart Watch','Headphones','Wireless Mouse','Keyboard','Webcam','Trimmer','Hair Dryer','Steam Iron','Electric Kettle','Mixer Grinder','Table Fan','LED Bulb','Extension Board','Car Charger','Memory Card','Pen Drive','Laptop Sleeve','Phone Case','Screen Guard']::text[]) as i(item)
  cross join unnest(array['1 unit','2 units','Pack of 3','Small','Medium','Large','Combo Pack','Value Pack']::text[]) as u(unit)),
priced as (select g.brand || ' ' || g.item as name, g.unit, g.rn,
  round(199 + random() * 4800) as price from gen g)
insert into products (name, unit, category_id, price, mrp, icon, image_url, is_active, stock)
select p.name, p.unit, 'electronics', p.price,
  round(p.price * (1.08 + random() * 0.30)), '🔌',
  case when im.urls is null then null else im.urls[1 + (p.rn % array_length(im.urls, 1))] end,
  true, (50 + floor(random() * 200))::int
from priced p
left join imgs im on true;

-- @@SPLIT@@ fashion: 25 x 25 x 8 = 5000
with imgs as (select array_agg(image_url order by id) as urls from products where image_url is not null and category_id = 'fashion'),
gen as (select b.brand, i.item, u.unit, row_number() over () as rn
  from unnest(array['Levi''s','Peter England','Allen Solly','Van Heusen','Louis Philippe','Wrangler','Pepe Jeans','US Polo','Jockey','Fabindia','W for Woman','Biba','Global Desi','Manyavar','Raymond','Arrow','Flying Machine','Roadster','HRX','Puma','Adidas','Nike','Reebok','Woodland','Bata']::text[]) as b(brand)
  cross join unnest(array['Cotton Kurta','Silk Saree','Cotton Saree','T-Shirt','Polo T-Shirt','Formal Shirt','Casual Shirt','Denim Jeans','Chinos','Track Pants','Shorts','Kurti','Leggings','Dupatta','Blazer','Sweatshirt','Hoodie','Jacket','Socks','Innerwear','Sneakers','Formal Shoes','Sandals','Flip Flops','Belt']::text[]) as i(item)
  cross join unnest(array['S','M','L','XL','XXL','Free Size','Pack of 2','Pack of 3']::text[]) as u(unit)),
priced as (select g.brand || ' ' || g.item as name, g.unit, g.rn,
  round(199 + random() * 2800) as price from gen g)
insert into products (name, unit, category_id, price, mrp, icon, image_url, is_active, stock)
select p.name, p.unit, 'fashion', p.price,
  round(p.price * (1.08 + random() * 0.30)), '👗',
  case when im.urls is null then null else im.urls[1 + (p.rn % array_length(im.urls, 1))] end,
  true, (50 + floor(random() * 200))::int
from priced p
left join imgs im on true;

-- @@SPLIT@@ home: 25 x 25 x 8 = 5000
with imgs as (select array_agg(image_url order by id) as urls from products where image_url is not null and category_id = 'home'),
gen as (select b.brand, i.item, u.unit, row_number() over () as rn
  from unnest(array['Prestige','Hawkins','Pigeon','Cello','Milton','Borosil','Tupperware','Butterfly','Vinod','Wonderchef','Bombay Dyeing','Portico','Spaces','Solimo','Amazon Basics','Godrej','Nilkamal','Wakefit','Sleepwell','Kurlon','Eureka Forbes','Scotch-Brite','Vim','Harpic','Lizol']::text[]) as b(brand)
  cross join unnest(array['Non-stick Tawa','Pressure Cooker','Frying Pan','Kadai','Steel Container Set','Water Bottle','Casserole','Dinner Set','Chopping Board','Knife Set','Bedsheet','Pillow Cover','Blanket','Curtain','Door Mat','Bath Towel','Storage Box','Laundry Basket','Broom','Floor Mop','Dustbin','Floor Cleaner','Dishwash Gel','Toilet Cleaner','Room Freshener']::text[]) as i(item)
  cross join unnest(array['1 unit','Set of 2','Set of 4','Set of 6','500 ml','1 L','Single Bed','Double Bed']::text[]) as u(unit)),
priced as (select g.brand || ' ' || g.item as name, g.unit, g.rn,
  round(99 + random() * 2400) as price from gen g)
insert into products (name, unit, category_id, price, mrp, icon, image_url, is_active, stock)
select p.name, p.unit, 'home', p.price,
  round(p.price * (1.08 + random() * 0.30)), '🏠',
  case when im.urls is null then null else im.urls[1 + (p.rn % array_length(im.urls, 1))] end,
  true, (50 + floor(random() * 200))::int
from priced p
left join imgs im on true;

-- @@SPLIT@@ beauty: 25 x 25 x 8 = 5000
with imgs as (select array_agg(image_url order by id) as urls from products where image_url is not null and category_id = 'beauty'),
gen as (select b.brand, i.item, u.unit, row_number() over () as rn
  from unnest(array['Lakme','Maybelline','L''Oreal','Nivea','Ponds','Himalaya','Biotique','Mamaearth','Plum','WOW','Garnier','Dove','Sunsilk','Clinic Plus','Head & Shoulders','Pantene','Colgate','Closeup','Sensodyne','Gillette','Park Avenue','Wild Stone','Fogg','Engage','Nykaa']::text[]) as b(brand)
  cross join unnest(array['Face Wash','Face Cream','Sunscreen','Body Lotion','Shampoo','Conditioner','Hair Oil','Hair Serum','Lipstick','Kajal','Eyeliner','Compact Powder','Nail Polish','Toothpaste','Toothbrush','Mouthwash','Deodorant','Perfume','Shaving Cream','Razor','Soap Bar','Body Wash','Talcum Powder','Hand Cream','Lip Balm']::text[]) as i(item)
  cross join unnest(array['50 g','100 g','200 g','50 ml','100 ml','200 ml','400 ml','Pack of 2']::text[]) as u(unit)),
priced as (select g.brand || ' ' || g.item as name, g.unit, g.rn,
  round(49 + random() * 950) as price from gen g)
insert into products (name, unit, category_id, price, mrp, icon, image_url, is_active, stock)
select p.name, p.unit, 'beauty', p.price,
  round(p.price * (1.08 + random() * 0.30)), '💄',
  case when im.urls is null then null else im.urls[1 + (p.rn % array_length(im.urls, 1))] end,
  true, (50 + floor(random() * 200))::int
from priced p
left join imgs im on true;

-- @@SPLIT@@ baby: 25 x 25 x 8 = 5000
with imgs as (select array_agg(image_url order by id) as urls from products where image_url is not null and category_id = 'baby'),
gen as (select b.brand, i.item, u.unit, row_number() over () as rn
  from unnest(array['Pampers','Huggies','MamyPoko','Himalaya Baby','Johnson''s','Mamaearth Baby','Chicco','Sebamed','Mee Mee','LuvLap','Pigeon Baby','Farlin','Nestle Baby','Cerelac','Enfamil','Similac','Dexolac','Babyhug','Firstcry','Supples','Bella Baby','Teddyy','Little''s','R for Rabbit','Morisons']::text[]) as b(brand)
  cross join unnest(array['Diapers','Baby Wipes','Baby Soap','Baby Shampoo','Baby Lotion','Baby Powder','Baby Oil','Rash Cream','Feeding Bottle','Sipper Cup','Bib','Baby Blanket','Baby Towel','Teether','Rattle','Baby Cereal','Formula Milk','Nail Cutter','Hair Brush','Bathing Tub','Changing Mat','Mosquito Patch','Baby Wash','Diaper Pants','Cotton Balls']::text[]) as i(item)
  cross join unnest(array['Pack of 10','Pack of 20','Pack of 30','Pack of 50','100 ml','200 ml','400 g','1 unit']::text[]) as u(unit)),
priced as (select g.brand || ' ' || g.item as name, g.unit, g.rn,
  round(99 + random() * 1400) as price from gen g)
insert into products (name, unit, category_id, price, mrp, icon, image_url, is_active, stock)
select p.name, p.unit, 'baby', p.price,
  round(p.price * (1.08 + random() * 0.30)), '🧸',
  case when im.urls is null then null else im.urls[1 + (p.rn % array_length(im.urls, 1))] end,
  true, (50 + floor(random() * 200))::int
from priced p
left join imgs im on true;
