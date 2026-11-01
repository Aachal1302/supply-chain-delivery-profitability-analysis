# supply-chain-delivery-profitability-analysis

# Supply Chain Delivery & Profitability Analysis

An end-to-end data analysis project: first checks in **Excel**, data cleaning and analysis in **PostgreSQL**, and a two-page interactive dashboard in **Power BI**.

The project answers two business problems:

1. **Delivery Delays & Shipping Performance**: how often orders arrive late, and what causes it.
2. **Sales, Profitability & Discount Effectiveness**: where sales and profit come from, and what discounts do to profit.

---

## Key Findings

### Problem 1: Delivery Delays & Shipping Performance

| Metric | Result |
|---|---|
| Late deliveries (all orders) | **54.83%** |
| Late deliveries (excluding canceled orders) | **57.29%** |
| Average actual vs scheduled shipping days | 3.50 vs 2.93 (0.57 days late) |
| First Class late rate | **100.00%** |
| Second Class late rate | **79.83%** |
| Same Day late rate | 47.93% |
| Standard Class late rate | 39.77% |

- **Shipping mode is the main cause of late deliveries.** First Class is scheduled for 1 day but takes 2. Second Class is scheduled for 2 days but takes about 4.
- **Region, category and month make almost no difference.** Late rates stay between 51.6% and 60.2% across 23 regions, and between 55% and 59% in every month from Jan 2015 to Jan 2018.
- **Recommendation:** make the scheduled days for First Class and Second Class realistic, or improve how fast these two modes ship.

### Problem 2: Sales, Profitability & Discount Effectiveness

| Metric | Result |
|---|---|
| Total sales | **$35.21M** |
| Total profit | **$3.81M** |
| Profit margin | **10.81%** |

| Discount range | Profit margin |
|---|---|
| 0%–5% | 11.73% |
| 5%–10% | 11.56% |
| 10%–15% | 10.50% |
| 15%–20% | 9.91% |
| 20%–25% | 9.26% |

- **Higher discounts reduce the profit margin.** It falls from 11.73% to 9.26%, and the drop starts above 10% discount. Keeping discounts under 10–15% protects profit.
- **Sales are concentrated.** The top 9 categories bring in about 88% of sales. Fishing ($6.64M), Cleats ($4.24M) and Camping & Hiking ($3.95M) lead.
- **Margins are similar across categories, regions and customer segments** (about 10–11%). Strength Training (0.45%) and Men's Clothing (4.38%) earn almost nothing.
- **Consumer is the largest segment** with about 52% of sales. **Standard Class** brings in about 60% of sales, and First Class has the highest margin (11.40%).

---

## Recommendations

### Fix delivery performance

1. **Reset the delivery promise for First Class and Second Class.** First Class is scheduled for 1 day but takes 2 (100% late), and Second Class is scheduled for 2 days but takes about 4 (80% late). Either promise 2 and 4 days, or speed up shipping on these two modes.
2. **Focus on shipping mode, not on region or category.** Late rates are almost the same in all regions, categories and months, so regional or product fixes will not move the number.
3. **Set a target and track it every month.** The late rate has stayed between 55% and 59% for four years, so it will not improve without action. A first target could be the Standard Class level (about 40%).
4. **Keep an eye on Standard Class.** It carries the most volume (about 60% of items), and its actual time (3.99 days) is right at its 4-day schedule, so small slips make orders late.

### Protect profit

5. **Keep discounts below 10–15%.** The profit margin falls from 11.73% (0–5% discount) to 9.26% (20–25% discount), and discounts of 15% and above make up about a third of sales.
6. **Review the near-zero-margin categories.** Strength Training (0.45%) and Men's Clothing (4.38%) earn almost nothing, so check their prices, discounts and costs.
7. **Grow the top categories without heavy discounting.** Fishing, Cleats and Camping & Hiking bring in most of the sales at margins of about 10–11%.
8. **Look at the lowest-margin regions.** Eastern Asia (9.93%), North Africa (9.78%) and Oceania (10.10%) are below the 10.81% average, so check discounting and costs there.

### Improve the data

9. **Add customer impact.** Late deliveries do not show up as lower profit margins here, so their real cost (reviews, repeat orders, refunds) needs data that is not in this dataset.
10. **Get complete data after October 2017.** The last months look incomplete, so trends after that date should not be used for decisions.

---

## Dashboard

A two-page Power BI dashboard built from the cleaned data.

| Page | Contents |
|---|---|
| **Delivery Performance** | Late delivery %, total orders, average actual and scheduled days, delivery status donut, late % by shipping mode, actual vs scheduled days, late % by region, monthly late % trend, and filters for shipping mode, region, customer segment and order date |
| **Sales & Profitability** | Total sales, total profit, profit margin, sales and profit by category (top 10), by region and by customer segment, profit and margin by discount range, monthly sales and profit trend, and profit by shipping mode |

Add your screenshots to the `images/` folder and they will show here:

![Delivery Performance](images/Page%201.png)
![Sales and Profitability](images/Page%202.png)
---

## Dataset

- **Rows:** 180,519 order-item records (65,752 distinct orders)
- **Columns:** 44 in the original dataset. The cleaned dataset has 23 columns: 18 original columns used in the analysis, plus 5 helper columns (`order_month`, `delay_days`, `is_late`, `is_canceled`, `discount_range`)
- **Period:** January 2015 to January 2018
- **Source:** *(add the link to where you downloaded the dataset)*

Each row is one order item, so `total_items` in the queries counts item rows, not orders. The number of real orders (excluding canceled) is 62,897.

---

## Data Cleaning

All SQL cleaning is done in `sql/Supply_Chain_Analysis.sql`.

1. **Initial checks in Excel.** Checked the raw data for duplicates, blank values and negative values. There were no duplicate rows, and only 3 blank values (customer zipcode). The only negative values are in the profit columns (33,784 loss-making items), which are real losses and were kept, and in latitude and longitude, which are normal coordinates.
2. **Fixed mixed date formats.** The order and shipping dates were stored in two formats. About 71,000 values were in `YYYY-MM-DD` format with the **day and month swapped** (a spreadsheet had misread them). Reading them as `YYYY-DD-MM` fixes this: after the fix, shipping dates are never before order dates, and the gap between the two dates matches the recorded shipping days on all 180,519 rows.
3. **Trimmed extra spaces** in text columns (for example, in `order_region`, `category_name` and `product_name`), which had split single values into duplicate groups.
4. **Cleaned the zipcode** by removing the trailing `.0` and converting blanks to NULL.
5. **Checked for duplicates:** none found (180,519 unique order items).
6. **Defined the canceled-order rule.** All suspected-fraud orders are also marked "Shipping canceled", so one filter (`delivery_status <> 'Shipping canceled'`) excludes both. This filter is applied in every query except the delivery status distribution.

---

## Analysis (SQL)

14 queries, answering the business questions one by one.

| Query | Question |
|---|---|
| 1.1 | What is the overall distribution of delivery statuses? |
| 1.2 | What is the overall late delivery risk percentage? |
| 1.3 | How do late delivery rates compare across shipping modes? |
| 1.4 | How do actual and scheduled shipping days compare? |
| 1.5 | Which order regions have the most late deliveries? |
| 1.6 | How do monthly delivery performance and late delivery trends look? |
| 1.7 | Which product categories have the highest late delivery rates? |
| 2.1 | What are the overall sales and profit? |
| 2.2 | How do sales and profit compare across product categories? |
| 2.3 | How do sales and profit compare across order regions? |
| 2.4 | How do sales and profit change across discount ranges? |
| 2.5 | What are the monthly sales and profit trends? |
| 2.6 | How do sales and profit compare across customer segments? |
| 2.7 | How do sales and profit compare across shipping modes? |

Profit margin is calculated as total profit divided by total sales, and "sales" is the sales value before discount.

---

## Data Notes

- Order volume drops by about half from October 2017 and the last months look incomplete, so read the monthly trends after October 2017 with care.
- Canceled and suspected-fraud orders are excluded from the sales and delivery analysis (apart from the status distribution).
- Country names in the source data are partly in Spanish (for example, "EE. UU.").

---

## Tools

- **Excel**: first checks on the raw data (duplicates, blank values and negative values)
- **PostgreSQL**: data cleaning and analysis
- **Power BI**: dashboard (DAX measures for late delivery %, total orders, average days, sales, profit and margin)

---

## Repository Structure

```
supply-chain-delivery-profitability-analysis/
├── data/
│   ├── raw/        original dataset (.gz)
│   └── cleaned/    cleaned dataset exported from SQL (.zip)
├── sql/            Supply_Chain_Analysis.sql (cleaning and analysis queries)
├── dashboard/      Supply_Chain_Analysis_Dashboard.pbix
├── images/         dashboard screenshots
└── README.md
```

## How to Reproduce

1. Unzip the raw dataset from `data/raw/`, create the table with the `CREATE TABLE` statement at the top of the SQL file, and load the CSV into it.
2. Run the cleaning section of the SQL file, in order.
3. Run the analysis queries (1.1 to 2.7).
4. Unzip the cleaned data from `data/cleaned/` if you want to use it directly, and open `dashboard/Supply_Chain_Analysis_Dashboard.pbix` in Power BI Desktop. If the data does not load, point it at your copy of the cleaned CSV.

---

