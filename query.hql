1. Put custpayments_ORIG.sql in /home/hduser
2. Login to mysql
3. Execute the script file, it will create custpayments database and customers table.
	source /home/hduser/custpayments_ORIG.sql

4. Do sqoop import
sqoop import -Dmapreduce.job.user.classpath.first=true --connect jdbc:mysql://localhost/custpayments --username root --password root -table customers -m 3 --split-by customernumber --target-dir /user/hduser/custavro --delete-target-dir --as-avrodatafile;

5.Download avro jar (avro-tools-1.8.1.jar) and copy to /home/hduser/ from the below url, this is to extract the schema from the avro data imported in the above step.

https://mvnrepository.com/artifact/org.apache.avro/avro-tools/1.8.1  (1.8.1 is most used one as per site)

6. hadoop jar avro-tools-1.8.1.jar getschema /user/hduser/custavro/part-m-00000.avro > /home/hduser/customer.avsc => this command creates .avsc to linux location only.
   you can use any part-m avro (part-m-00001 or m-0002 ...) file of the import to create avsc file.

7. cat ~/customer.avsc => to see the schema of the table

8. hadoop fs -put -f customer.avsc /tmp/customer.avsc => put the schema file to hdfs location. so that HIVE can pick it up when loading table while querying.
	

9. create external table customeravro stored as AVRO location '/user/hduser/custavro' TBLPROPERTIES('avro.schema.url'='hdfs:///tmp/customer.avsc');

10. select * from customeravro limit 10; => we can see all columns and associated data.

Now, lets alter the table schema in mysql and evolve the column in HIVE.


10. alter table customers add (Email varchar(255), createddate date);


11. insert  into `customers`(`customerNumber`,`customerName`,`contactLastName`,`contactFirstName`,`phone`,`addressLine1`,`addressLine2`,`city`,`state`,`postalCode`,`country`,`salesRepEmployeeNumber`,`creditLimit`,Email,Createddate) values 
(497,'Ashok','Schmitt','Carine ','40.32.2555','54, rue Royale',NULL,'Nantes',NULL,'44000','France',1370,'21000.00','ashok.amsamani@gmail.com','2020-10-17'),
(498,'Ashok2','Schmitt','Carine ','40.32.2555','54, rue Royale',NULL,'Nantes',NULL,'44000','France',1370,'21000.00','ashok2.amsamani2@gmail.com','2020-10-18')


13. sqoop import -Dmapreduce.job.user.classpath.first=true --connect jdbc:mysql://localhost/custpayments --username root --password root -table customers -m 3 --split-by customernumber --target-dir /user/hduser/custavro --incremental append --check-column customerNumber --last-value 496 --as-avrodatafile;

14. hadoop fs -ls /user/hduser/custavro/

	Take the new part m file created - /user/hduser/custavro/part-m-00003.avro.

15. Generate avro schema file using new part-m file.
	hadoop jar avro-tools-1.8.1.jar getschema /user/hduser/custavro/part-m-00003.avro > /home/hduser/customer_inc.avsc 

16. hadoop fs -put -f customer_inc.avsc /tmp/customer1.avsc => overwrite the existing avro schema.This alone enough, when u query the table, HIVE will check the schema file and load the needed columns from new avsc file and rows from hdfs.

17. select * from customeravro where customernumber in (497,498) => u can see the new column and rows. All other rows will have NULL in the column.


/******Failed scenario************/
12. sqoop import -Dmapreduce.job.user.classpath.first=true --connect jdbc:mysql://localhost/custpayments --username root --password root -table customers -m 3 --split-by customernumber --target-dir /user/hduser/custavro --incremental lastmodified --check-column createddate --last-value '2020-10-17' --append --as-avrodatafile;

Job abondoned, WARN: --incremental lastmodified cannot be used in conjunction with --as-avrodatafile.
/***********************************/
