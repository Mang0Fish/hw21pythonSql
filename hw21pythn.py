import psycopg2
import psycopg2.extras

connection = psycopg2.connect(
    host="localhost",
    database="h21try",
    user="postgres",  # postgres
    password="admin",
    port="5559"
)

cursor = connection.cursor(cursor_factory=psycopg2.extras.DictCursor)

select_query1 = "SELECT hello_user('Mango')"
select_query2 = "SELECT arithmetics(20,6)"
select_query3 = "SELECT smaller(7,3)"
cursor.execute(select_query1)
rows = cursor.fetchall()
for row in rows:
    rows_dict = dict(row)
    print(rows_dict)
cursor.execute(select_query2)
rows = cursor.fetchall()
for row in rows:
    rows_dict = dict(row)
    print(rows_dict)
cursor.execute(select_query3)
rows = cursor.fetchall()
for row in rows:
    rows_dict = dict(row)
    print(rows_dict)

insert_query = """insert into authors (name)
values ('Billy Jean');
"""
cursor.execute(insert_query)



connection.commit()
cursor.close()
connection.close()