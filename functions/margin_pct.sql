select case when sale_price = 0 then null
            else (sale_price - cost) / sale_price * 100 end
