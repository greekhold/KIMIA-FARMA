WITH TotalNettSales AS (
    SELECT 
        EXTRACT(YEAR FROM t.date) AS tahun,
        SUM(t.price * (1 - t.discount_percentage / 100)) AS total_nett_sales
    FROM `rakamin-kf-analytics-449801.kimia_farma.kf_final_transaction` t
    WHERE EXTRACT(YEAR FROM t.date) BETWEEN 2020 AND 2023
    GROUP BY tahun
),
NettSalesPerProvinsi AS (
    SELECT 
        c.provinsi,
        SUM(t.price * (1 - t.discount_percentage / 100)) AS total_nett_sales
    FROM `rakamin-kf-analytics-449801.kimia_farma.kf_final_transaction` t
    JOIN `rakamin-kf-analytics-449801.kimia_farma.kf_kantor_cabang` c 
        ON t.branch_id = c.branch_id
    WHERE EXTRACT(YEAR FROM t.date) BETWEEN 2020 AND 2023
    GROUP BY c.provinsi
),
RankedBranches AS (
    SELECT 
        c.branch_name, 
        c.rating AS rating_cabang, 
        t.rating AS rating_transaksi,
        RANK() OVER (ORDER BY c.rating DESC, t.rating ASC) AS ranking
    FROM `rakamin-kf-analytics-449801.kimia_farma.kf_final_transaction` t
    JOIN `rakamin-kf-analytics-449801.kimia_farma.kf_kantor_cabang` c 
        ON t.branch_id = c.branch_id
)

SELECT 
    t.transaction_id,
    t.date,
    tn.tahun,
    tn.total_nett_sales,
    c.branch_id,
    rb.branch_name,
    c.kota,
    c.provinsi,
    rb.rating_cabang,
    t.customer_name,
    p.product_id,
    p.product_name,
    t.price AS actual_price,
    t.discount_percentage,

    -- Perhitungan Nett Sales
    t.price * (1 - t.discount_percentage / 100) AS nett_sales,

    -- Perhitungan Persentase Gross Laba
    CASE 
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        ELSE 0.30
    END AS persentase_gross_laba,

    -- Perhitungan Nett Profit
    (t.price * (1 - t.discount_percentage / 100)) * 
    CASE 
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        ELSE 0.30
    END AS nett_profit,

    t.rating AS rating_transaksi

FROM `rakamin-kf-analytics-449801.kimia_farma.kf_final_transaction` t
JOIN `rakamin-kf-analytics-449801.kimia_farma.kf_kantor_cabang` c 
    ON t.branch_id = c.branch_id
JOIN `rakamin-kf-analytics-449801.kimia_farma.kf_product` p
    ON t.product_id = p.product_id
JOIN TotalNettSales tn
    ON EXTRACT(YEAR FROM t.date) = tn.tahun
JOIN RankedBranches rb
    ON c.branch_name = rb.branch_name
WHERE rb.ranking <= 5  -- Top 5 cabang dengan rating cabang tinggi tetapi rating transaksi rendah
ORDER BY tn.tahun, c.branch_id;



SELECT 
    EXTRACT(YEAR FROM date) AS tahun,
    EXTRACT(MONTH FROM date) AS bulan,
    SUM(price * (1 - discount_percentage / 100)) AS total_nett_sales
FROM `rakamin-kf-analytics-449801.kimia_farma.kf_final_transaction`
GROUP BY tahun, bulan
ORDER BY tahun, bulan;


WITH RankedProvinces AS (
    SELECT 
        c.provinsi,
        AVG(c.rating) AS avg_rating_cabang,
        AVG(t.rating) AS avg_rating_transaksi
    FROM `rakamin-kf-analytics-449801.kimia_farma.kf_final_transaction` t
    JOIN `rakamin-kf-analytics-449801.kimia_farma.kf_kantor_cabang` c 
        ON t.branch_id = c.branch_id
    GROUP BY c.provinsi
),
RankedData AS (
    SELECT 
        provinsi,
        avg_rating_cabang,
        avg_rating_transaksi,
        RANK() OVER (ORDER BY avg_rating_cabang DESC, avg_rating_transaksi ASC) AS ranking
    FROM RankedProvinces
)
SELECT *
FROM RankedData
WHERE ranking <= 5
ORDER BY ranking ASC;

