-- Replace only the Americano product image with a warmer, professional café photo.
-- Source page: https://unsplash.com/photos/a-cup-of-coffee-CsMHTU_g2Ds
-- Delivered as a 1200x1200 crop to suit both customer-app and dashboard thumbnails/heroes.

update public.catalogue_items
set image_url = 'https://images.unsplash.com/photo-1661989770233-e84b8c46d1f2?auto=format&fit=crop&ixlib=rb-4.1.0&q=85&w=1200&h=1200'
where sku = 'CF-AME'
  and kind = 'product'
  and image_url is distinct from 'https://images.unsplash.com/photo-1661989770233-e84b8c46d1f2?auto=format&fit=crop&ixlib=rb-4.1.0&q=85&w=1200&h=1200';
