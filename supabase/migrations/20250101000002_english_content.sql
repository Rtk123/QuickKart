-- ============================================================
-- QuickKart — English content + Hindi translations (migration 3)
--
-- App ki default language ab English hai, isliye `name`/`unit` columns
-- English rakhte hain aur Hindi ko `name_hi`/`unit_hi` mein move karte hain.
-- Settings -> Language se user jo chune, app wahi column dikhata hai
-- (Hindi missing ho to English par fallback ho jaata hai).
-- ============================================================

alter table categories add column if not exists name_hi text;
alter table products   add column if not exists name_hi text;
alter table products   add column if not exists unit_hi text;

-- Step 1: abhi jo Hindi values hain, unhe *_hi columns mein safe kar lo.
-- (`where ... is null` isse dobara chalane par bhi safe banata hai.)
update categories set name_hi = name where name_hi is null;
update products   set name_hi = name where name_hi is null;
update products   set unit_hi = unit where unit_hi is null;

-- Step 2: primary columns ko English kar do.
update categories as c set name = v.en
from (values
  ('grocery',     'Grocery'),
  ('electronics', 'Electronics'),
  ('fashion',     'Fashion'),
  ('home',        'Home & Kitchen'),
  ('beauty',      'Beauty'),
  ('baby',        'Baby Care')
) as v(id, en)
where c.id = v.id;

update products as p set name = v.en, unit = v.unit_en
from (values
  ('ताज़ा टमाटर',           'Fresh Tomatoes',       '1 kg'),
  ('अमूल दूध',              'Amul Milk',            '500 ml'),
  ('बासमती चावल',           'Basmati Rice',         '5 kg'),
  ('सरसों तेल',             'Mustard Oil',          '1 L'),
  ('आलू',                   'Potatoes',             '1 kg'),
  ('ब्रेड',                 'Bread',                '400 g'),
  ('वायरलेस ईयरबड्स',       'Wireless Earbuds',     '1 unit'),
  ('पावर बैंक 10000mAh',    'Power Bank 10000mAh',  '1 unit'),
  ('USB-C चार्जिंग केबल',   'USB-C Charging Cable', '1 unit'),
  ('ब्लूटूथ स्पीकर',        'Bluetooth Speaker',    '1 unit'),
  ('कॉटन कुर्ता (पुरुष)',   'Cotton Kurta (Men)',   '1 unit'),
  ('महिलाओं की साड़ी',      'Women''s Saree',       '1 unit'),
  ('स्नीकर्स',              'Sneakers',             '1 pair'),
  ('नॉन-स्टिक तवा',         'Non-stick Tawa',       '1 unit'),
  ('LED बल्ब 9W',           'LED Bulb 9W',          '1 unit'),
  ('कॉटन बेडशीट',           'Cotton Bedsheet',      '1 set'),
  ('फेस वॉश',               'Face Wash',            '100 g'),
  ('शैम्पू',                'Shampoo',              '340 ml'),
  ('बेबी डायपर',            'Baby Diapers',         'Pack of 30'),
  ('बेबी वाइप्स',           'Baby Wipes',           '80 sheets')
) as v(hi, en, unit_en)
where p.name_hi = v.hi;

-- Search dono languages mein kaam kare, isliye name_hi par bhi index.
create index if not exists idx_products_name_hi on products(name_hi);
