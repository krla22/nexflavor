#!/usr/bin/env bash
# Seeds a fresh nexFlavor site. Run after: docker compose up -d
set -e
API="http://localhost:8000/api"
H="Content-Type: application/json"

echo "→ installing hrms"
docker compose exec -T backend bench get-app --branch version-15 hrms || true
docker compose exec -T backend bench --site frontend install-app hrms || true

echo "→ item group"
curl -s -X POST "$API/resource/Item%20Group" -H "$H" \
  -d '{"item_group_name":"Food","parent_item_group":"All Item Groups","is_group":0}' >/dev/null

echo "→ menu"
while IFS='|' read -r code name rate; do
  curl -s -X POST "$API/resource/Item" -H "$H" \
    -d "{\"item_code\":\"$code\",\"item_name\":\"$name\",\"item_group\":\"Food\",\"stock_uom\":\"Nos\",\"is_stock_item\":0,\"standard_rate\":$rate}" \
    -o /dev/null -w "  $code %{http_code}\n"
done << 'EOF'
BURG-01|Classic Burger|150
BURG-02|Cheese Burger|175
CHIK-01|Fried Chicken|180
RICE-01|Steamed Rice|35
FRIE-01|French Fries|75
PAST-01|Carbonara|165
DRNK-01|Iced Tea|45
DRNK-02|Soft Drink|50
DRNK-03|Coffee|65
DESS-01|Leche Flan|85
EOF

echo "→ customer"
curl -s -X POST "$API/resource/Customer" -H "$H" \
  -d '{"customer_name":"Walk-in Customer","customer_group":"Individual","territory":"All Territories"}' >/dev/null

echo "→ kitchen status field"
curl -s -X POST "$API/resource/Custom%20Field" -H "$H" \
  -d '{"dt":"Sales Order","fieldname":"custom_kitchen_status","label":"Kitchen Status","fieldtype":"Select","options":"New\nPreparing\nReady\nServed","default":"New","insert_after":"status","allow_on_submit":1}' >/dev/null

echo "→ pos invoice mode"
docker compose exec -T backend bench --site frontend execute frappe.db.set_single_value \
  --args "['POS Settings','invoice_type','POS Invoice']"

docker compose exec -T backend bench --site frontend clear-cache
echo "done. POS Profile still needs manual setup — see README."