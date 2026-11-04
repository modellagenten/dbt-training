-- Die Marge kann nie größer sein als der Verkaufspreis (solange die Kosten nicht negativ sind).
select
    order_item_id,
    sale_price,
    item_margin
from {{ ref('fct_order_items') }}
where item_margin > sale_price
