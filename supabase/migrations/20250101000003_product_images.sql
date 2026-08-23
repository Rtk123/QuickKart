-- ============================================================
-- QuickKart - real product images (migration 4)
--
-- Ab product cards emoji ki jagah asli photo dikhate hain (Blinkit jaisa).
-- Saari images Wikimedia Commons se hain (freely licensed) aur unka CDN
-- CORS allow karta hai, isliye Flutter web par bhi load hoti hain.
--
-- icon column hataya nahi gaya hai - image load na ho paaye to UI
-- usi emoji par fallback karta hai (dekhein widgets/product_card.dart).
-- ============================================================

update products as p set image_url = v.url
from (values
  ('Fresh Tomatoes', 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tomato_je.jpg/500px-Tomato_je.jpg'),
  ('Amul Milk', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Glass_of_Milk_%2833657535532%29.jpg/500px-Glass_of_Milk_%2833657535532%29.jpg'),
  ('Basmati Rice', 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Khyma_and_Basmati_rice.jpg/500px-Khyma_and_Basmati_rice.jpg'),
  ('Mustard Oil', 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Mustard_Oil_%26_Seeds_-_Kolkata_2003-10-31_00537.JPG/500px-Mustard_Oil_%26_Seeds_-_Kolkata_2003-10-31_00537.JPG'),
  ('Potatoes', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Patates.jpg/500px-Patates.jpg'),
  ('Bread', 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Korb_mit_Br%C3%B6tchen.JPG/500px-Korb_mit_Br%C3%B6tchen.JPG'),
  ('Wireless Earbuds', 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/ActiveSound_wireless_earbuds_by_Hykker_%28POJM200483%29.jpg/500px-ActiveSound_wireless_earbuds_by_Hykker_%28POJM200483%29.jpg'),
  ('Power Bank 10000mAh', 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/SAMSUNG_BATTERY_PACK_%28POWER_BANK%29_EB-P4520.jpg/500px-SAMSUNG_BATTERY_PACK_%28POWER_BANK%29_EB-P4520.jpg'),
  ('USB-C Charging Cable', 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/USB-C_plug%2C_focus_stacked.jpg/500px-USB-C_plug%2C_focus_stacked.jpg'),
  ('Bluetooth Speaker', 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/JBL_Flip_3_bluetooth_speaker_%28DSCF2653%29.jpg/500px-JBL_Flip_3_bluetooth_speaker_%28DSCF2653%29.jpg'),
  ('Cotton Kurta (Men)', 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Kurta_traditional_front_sandalwood_buttons.jpg/500px-Kurta_traditional_front_sandalwood_buttons.jpg'),
  ('Women''s Saree', 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Woman_in_Green_Saree%2C_Yamai_Temple%2C_Aundh%2C_Maharashtra.jpg/500px-Woman_in_Green_Saree%2C_Yamai_Temple%2C_Aundh%2C_Maharashtra.jpg'),
  ('Sneakers', 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/Air_Jordan_1_Banned.jpg/500px-Air_Jordan_1_Banned.jpg'),
  ('Non-stick Tawa', 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Tava.JPG/500px-Tava.JPG'),
  ('LED Bulb 9W', 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Led-lampa.jpg/500px-Led-lampa.jpg'),
  ('Cotton Bedsheet', 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Prze%C5%9Bcierad%C5%82o.jpg/500px-Prze%C5%9Bcierad%C5%82o.jpg'),
  ('Shampoo', 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Metric_shampoo_bottle.jpg/500px-Metric_shampoo_bottle.jpg'),
  ('Baby Diapers', 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Disposablediaper.JPG/500px-Disposablediaper.JPG'),
  ('Baby Wipes', 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Erfrischungstuch.jpg/500px-Erfrischungstuch.jpg')
) as v(name, url)
where p.name = v.name;

-- Note: 'Face Wash' ke liye Wikimedia Commons par koi theek image nahi mili,
-- isliye uska image_url NULL hai aur woh emoji fallback dikhata hai.
