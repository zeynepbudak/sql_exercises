--SORU 1 Customers isimli bir veritabanı ve verilen veri setindeki değişkenleri içerecek FLO isimli bir tablo oluşturunuz.

CREATE DATABASE CUSTOMERS

CREATE TABLE FLO (
	master_id							VARCHAR(50),
	order_channel						VARCHAR(50),
	last_order_channel					VARCHAR(50),
	first_order_date					DATE,
	last_order_date						DATE,
	last_order_date_online				DATE,
	last_order_date_offline				DATE,
	order_num_total_ever_online			INT,
	order_num_total_ever_offline		INT,
	customer_value_total_ever_offline	FLOAT,
	customer_value_total_ever_online	FLOAT,
	interested_in_categories_12			VARCHAR(50),
	store_type							VARCHAR(10)
);


--SORU 2: Kaç farklı müşterinin alışveriş yaptığını gösterecek sorguyu yazınız.

SELECT COUNT(DISTINCT(master_id)) AS DISTINCT_KISI_SAYISI FROM FLO;


--SORU 3: Toplam yapılan alışveriş sayısı ve ciroyu getirecek sorguyu yazınız.

SELECT 
	SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOPLAM_SIPARIS_SAYISI,
	ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOPLAM_CIRO
FROM FLO;


--SORU 4:  Alışveriş başına ortalama ciroyu getirecek sorguyu yazınız. 

SELECT  
--SUM(order_num_total_ever_online+order_num_total_ever_offline) ToplamSiparisMiktari
	ROUND((SUM(customer_value_total_ever_offline + customer_value_total_ever_online) / 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) 
	), 2) AS SIPARIS_ORT_CIRO 
 FROM FLO


--SORU 5: En son alışveriş yapılan kanal (last_order_channel) üzerinden yapılan alışverişlerin toplam ciro ve alışveriş sayılarını getirecek sorguyu yazınız.

SELECT  last_order_channel SON_ALISVERIS_KANALI,
SUM(customer_value_total_ever_offline + customer_value_total_ever_online) TOPLAMCIRO,
SUM(order_num_total_ever_online+order_num_total_ever_offline) TOPLAM_SIPARIS_SAYISI
FROM FLO
GROUP BY  last_order_channel


--SORU 6: Store type kırılımında elde edilen toplam ciroyu getiren sorguyu yazınız.

SELECT store_type MAGAZATURU, 
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) TOPLAM_CIRO 
FROM FLO 
GROUP BY store_type;

--BONUS - > Store type icerisindeki verilerin parse edilmis hali.

SELECT Value,SUM(TOPLAM_CIRO/COUNT_) FROM
(
SELECT store_type MAGAZATURU,(SELECT COUNT(VALUE) FROM  string_split(store_type,',') ) COUNT_,
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) TOPLAM_CIRO 
FROM FLO 
GROUP BY store_type) T
CROSS APPLY (SELECT  VALUE  FROM  string_split(T.MAGAZATURU,',') ) D
GROUP BY Value
 

--SORU 7: Yıl kırılımında alışveriş sayılarını getirecek sorguyu yazınız (Yıl olarak müşterinin ilk alışveriş tarihi (first_order_date) yılını baz alınız)

SELECT 
YEAR(first_order_date) YIL,  SUM(order_num_total_ever_offline + order_num_total_ever_online) SIPARIS_SAYISI
FROM  FLO
GROUP BY YEAR(first_order_date)


--SORU 8: En son alışveriş yapılan kanal kırılımında alışveriş başına ortalama ciroyu hesaplayacak sorguyu yazınız.

SELECT last_order_channel, 
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online),2) TOPLAM_CIRO,
	   SUM(order_num_total_ever_offline + order_num_total_ever_online) TOPLAM_SIPARIS_SAYISI,
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online) / SUM(order_num_total_ever_offline + order_num_total_ever_online),2) AS VERIMLILIK
FROM FLO
GROUP BY last_order_channel;


--SORU 9: Son 12 ayda en çok ilgi gören kategoriyi getiren sorguyu yazınız.

SELECT interested_in_categories_12, 
       COUNT(*) FREKANS_BILGISI 
FROM FLO
GROUP BY interested_in_categories_12
ORDER BY 2 DESC;

--BONUS - > kategorilerin parse edilmis cozumu

SELECT K.VALUE,SUM(T.FREKANS_BILGISI/T.SAYI) FROM 
(
SELECT 
(SELECT COUNT(VALUE) FROM string_split(interested_in_categories_12,',')) SAYI,
REPLACE(REPLACE(interested_in_categories_12,']',''),'[','') KATEGORI, 
COUNT(*) FREKANS_BILGISI 
FROM FLO
GROUP BY interested_in_categories_12
) T 
CROSS APPLY (SELECT * FROM string_split(KATEGORI,',')) K
GROUP BY K.value


--SORU 10:  En çok tercih edilen store_type bilgisini getiren sorguyu yazınız.

SELECT TOP 1   
	store_type, 
    COUNT(*) FREKANS_BILGISI 
FROM FLO 
GROUP BY store_type 
ORDER BY 2 DESC;

--BONUS - > rownumber kullanilarak cozulmus hali

SELECT * FROM
(
SELECT    
ROW_NUMBER() OVER(  ORDER BY COUNT(*) DESC) ROWNR,
	store_type, 
    COUNT(*) FREKANS_BILGISI 
FROM FLO 
GROUP BY store_type 
)T 
WHERE ROWNR=1


--SORU 11: En son alışveriş yapılan kanal (last_order_channel) bazında, en çok ilgi gören kategoriyi ve bu kategoriden ne kadarlık alışveriş yapıldığını getiren sorguyu yazınız.

SELECT DISTINCT last_order_channel,
(
	SELECT top 1 interested_in_categories_12
	FROM FLO  WHERE last_order_channel=f.last_order_channel
	group by interested_in_categories_12
	order by 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) desc 
),
(
	SELECT top 1 SUM(order_num_total_ever_online+order_num_total_ever_offline)
	FROM FLO  WHERE last_order_channel=f.last_order_channel
	group by interested_in_categories_12
	order by 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) desc 
)
FROM FLO F


--BONUS - > CROSS APPLY yontemi ile yapilmis cozum

SELECT DISTINCT last_order_channel,D.interested_in_categories_12,D.TOPLAMSIPARIS
FROM FLO  F
CROSS APPLY 
(
	SELECT top 1 interested_in_categories_12,SUM(order_num_total_ever_online+order_num_total_ever_offline) TOPLAMSIPARIS
	FROM FLO   WHERE last_order_channel=f.last_order_channel
	group by interested_in_categories_12
	order by 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) desc 
) D


--SORU 12: En çok alışveriş yapan kişinin ID’sini getiren sorguyu yazınız. 

SELECT TOP 1 master_id   		    
	FROM FLO 
	GROUP BY master_id 
ORDER BY  SUM(customer_value_total_ever_offline + customer_value_total_ever_online)    DESC 

--BONUS

SELECT D.master_id
FROM 
	(SELECT master_id, 
		   ROW_NUMBER() OVER(ORDER BY SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC) RN
	FROM FLO 
	GROUP BY master_id) AS D
WHERE RN = 1;


--SORU 13: En çok alışveriş yapan kişinin alışveriş başına ortalama cirosunu ve alışveriş yapma gün ortalamasını (alışveriş sıklığını) getiren sorguyu yazınız.

SELECT D.master_id,ROUND((D.TOPLAM_CIRO / D.TOPLAM_SIPARIS_SAYISI),2) SIPARIS_BASINA_ORTALAMA,
ROUND((DATEDIFF(DAY, first_order_date, last_order_date)/D.TOPLAM_SIPARIS_SAYISI ),1) ALISVERIS_GUN_ORT
FROM
(
SELECT TOP 1 master_id, first_order_date, last_order_date,
		   SUM(customer_value_total_ever_offline + customer_value_total_ever_online) TOPLAM_CIRO,
		   SUM(order_num_total_ever_offline + order_num_total_ever_online) TOPLAM_SIPARIS_SAYISI
	FROM FLO 
	GROUP BY master_id,first_order_date, last_order_date
ORDER BY TOPLAM_CIRO DESC
) D


--SORU 14: En çok alışveriş yapan (ciro bazında) ilk 100 kişinin alışveriş yapma gün ortalamasını (alışverişsıklığını) getiren sorguyu yazınız. 

SELECT  
D.master_id,
       D.TOPLAM_CIRO,
	   D.TOPLAM_SIPARIS_SAYISI,
       ROUND((D.TOPLAM_CIRO / D.TOPLAM_SIPARIS_SAYISI),2) SIPARIS_BASINA_ORTALAMA,
	   DATEDIFF(DAY, first_order_date, last_order_date) ILK_SN_ALVRS_GUN_FRK,
	  ROUND((DATEDIFF(DAY, first_order_date, last_order_date)/D.TOPLAM_SIPARIS_SAYISI ),1) ALISVERIS_GUN_ORT	 
  FROM
(
SELECT TOP 100 master_id, first_order_date, last_order_date,
		   SUM(customer_value_total_ever_offline + customer_value_total_ever_online) TOPLAM_CIRO,
		   SUM(order_num_total_ever_offline + order_num_total_ever_online) TOPLAM_SIPARIS_SAYISI
	FROM FLO 
	GROUP BY master_id,first_order_date, last_order_date
ORDER BY TOPLAM_CIRO DESC
) D


--SORU 15: En son alışveriş yapılan kanal (last_order_channel) kırılımındaen çok alışverişyapan müşteriyi getiren sorguyu yazınız.

SELECT DISTINCT last_order_channel,
(
	SELECT top 1 master_id
	FROM FLO  WHERE last_order_channel=f.last_order_channel
	group by master_id
	order by 
	SUM(customer_value_total_ever_offline+customer_value_total_ever_online) desc 
) EN_COK_ALISVERIS_YAPAN_MUSTERI,
(
	SELECT top 1 SUM(customer_value_total_ever_offline+customer_value_total_ever_online)
	FROM FLO  WHERE last_order_channel=f.last_order_channel
	group by master_id
	order by 
	SUM(customer_value_total_ever_offline+customer_value_total_ever_online) desc 
) CIRO
FROM FLO F


--SORU 16:  En son alışveriş yapan kişinin ID’ sini getiren sorguyu yazınız. (Max son tarihte birden fazla alışveriş yapan ID bulunmakta. Bunları da getiriniz.) 

SELECT master_id,last_order_date FROM FLO
WHERE last_order_date=(SELECT MAX(last_order_date) FROM FLO)
