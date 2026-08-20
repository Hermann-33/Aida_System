-- Refresh AIDA Cafe product photography with distinct, unbranded, free Unsplash images.
-- All delivered URLs request a 1200x1200 center crop for consistent mobile/dashboard rendering.
-- Stable catalogue SKUs are used deliberately; no generated IDs are hardcoded.

update public.catalogue_items as i
set image_url = p.image_url
from (values
  -- Salted Caramel Latte — https://unsplash.com/photos/yS2s4DRtRLM
  ('CF-SCL','https://images.unsplash.com/photo-1756132540577-0a8da3e0f0f6?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Latte — https://unsplash.com/photos/rhgVuPbOZOc
  ('CF-LAT','https://images.unsplash.com/photo-1760687510681-2f0cdd1f1ebb?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Americano — https://unsplash.com/photos/QCNrhxfWOaA
  ('CF-AME','https://images.unsplash.com/photo-1777911651607-8765f95be546?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Cappuccino — https://unsplash.com/photos/kSlL887znkE
  ('CF-CAP','https://images.unsplash.com/photo-1503481766315-7a586b20f66d?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Mocha — https://unsplash.com/photos/Edmcnx3LLsM
  ('CF-MOC','https://images.unsplash.com/photo-1533651441215-d01c13c8c4ad?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Iced Coffee — https://unsplash.com/photos/M2_AEEkjd2A
  ('IC-COF','https://images.unsplash.com/photo-1749105862018-7a28495a2638?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Iced Latte — https://unsplash.com/photos/XBvz9mFAOlM
  ('IC-LAT','https://images.unsplash.com/photo-1783244653100-ad25e5452166?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Matcha Latte — https://unsplash.com/photos/Oog-4Ox0rv8
  ('IC-MAT','https://images.unsplash.com/photo-1751563721808-3b81940b88f7?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Chocolate Ice — https://unsplash.com/photos/tulyqJ6d5RA
  ('IC-CHO','https://images.unsplash.com/photo-1765827620772-3129b91847b2?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Sandwich — https://unsplash.com/photos/zoO6plqINwc
  ('FD-SAN','https://images.unsplash.com/photo-1728777187168-0714ecbf5e69?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Butter Croissant — https://unsplash.com/photos/TKSD0gfkmzU
  ('FD-CRO','https://images.unsplash.com/photo-1755880040259-72569249d7f3?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Muffin — https://unsplash.com/photos/y7uR3FAbONA
  ('FD-MUF','https://images.unsplash.com/photo-1632498762310-50e4473bce92?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200'),
  -- Chicken Wrap — https://unsplash.com/photos/MdkUEKFfkTM
  ('FD-WRP','https://images.unsplash.com/photo-1632660346941-023cc64e1252?auto=format&fit=crop&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=85&w=1200&h=1200')
) as p(sku,image_url)
where i.sku = p.sku
  and i.kind = 'product'
  and i.image_url is distinct from p.image_url;
