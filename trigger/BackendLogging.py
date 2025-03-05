import sqlalchemy as sa
from typing import List,Dict,Text,Any
# import datetime

class BackendLoggingSQL(host, port, dbname, driver):
    def __init__(self):
        self.servername = "%s:%d" % (host, port)
        self.dbname = dbname
        self.driver = driver
        cstring = f'mssql+pyodbc://@{self.servername}/{self.dbname}?trusted_connection=yes&driver=ODBC+Driver+{self.driver}+for+SQL+Server'
        self.engine = sa.create_engine(cstring)
        self.metadata_obj = sa.MetaData()
        self.log_table_name='log'
        self.log_table = sa.Table(
            self.log_table_name,
            self.metadata_obj,
            # columns definition here
            sa.Column('datetime', sa.DateTime),
            sa.Column('accession_number', sa.String),
            sa.Column('user', sa.String),
            sa.Column('status', sa.String),
            sa.Column('error_message', sa.String),
        )

        self.prediction_table_name='prediction'
        self.prediction_table= sa.Table(
            self.prediction_table_name,
            self.metadata_obj,
            # columns definition here
            sa.Column('datetime', sa.DateTime),
            sa.Column('accession_number', sa.String),
            sa.Column('tumor_size', sa.Float),
        )


        self.drop_tables()
        self.create_tables()

    # Create the log table if it does not exist already
    def create_tables(self):
        log_table_exists = sa.inspect(self.engine).has_table(self.log_table_name)
        prediciton_table_exist = sa.inspect(self.engine).has_table(self.prediction_table_name)
        if not log_table_exists and not prediciton_table_exist:
            self.metadata_obj.create_all(self.engine)
        elif log_table_exists != prediciton_table_exist:
            raise Exception("Table creation failed, make sure to have in the database all requried tables.  Or remove all user generated tables (with drop_tables) and initialize this class again.")

    def drop_tables(self):
        self.log_table.drop(self.engine)
        self.prediction_table.drop(self.engine)

    #########################
    def update(self,table, new_rows : List[Dict[Text,Any]]):
        # new_rows like [ {"col1": val1, "col2": val2 ...}, ... ],
        statement = sa.insert(table).values(new_rows)
        with self.engine.begin() as conn:
            conn.execute(statement)

    def save_log(self,new_rows : List[Dict[Text,Any]]):
        self.update(self.log_table,new_rows)

    def save_prediction(self,new_rows : List[Dict[Text,Any]]):
        self.update(self.prediction_table,new_rows)


#if __name__ == '__main__':
#    c = SQLConnection()
#
#    c.save_log([{'datetime': datetime.datetime.now(),
#                 'accession_number': "someaccessionnumber",
#                 'user': "user",
#                 'status': "OK",
#                 'error_message': "" }
#               ])
#    c.save_prediction([{'datetime': datetime.datetime.now(),
#                 'accession_number': "someaccessionnumber",
#                 'tumor_size': 3.3 }
#               ])
