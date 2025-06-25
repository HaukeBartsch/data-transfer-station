#!/usr/bin/env python3
import sqlalchemy as sa
from typing import List,Dict,Text,Any
import datetime, os, json, sys, argparse

class BackendLoggingSQL():
    def __init__(self, host, port, dbname, driver):
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


if __name__ == '__main__':

    # Check command line arguments
    parser = argparse.ArgumentParser(
                    prog='BackendLogging',
                    description='Log messages and tumor sizes to a SQL database')
    parser.add_argument('-a', '--accession_number', type=str, help='Accession number for the log entry')
    parser.add_argument('-s', '--status', type=str, help='Status string (OK,ERROR) for the log entry')
    parser.add_argument('-m', '--message', type=str, help='Message string for the log entry')
    parser.add_argument('-t', '--tumor_size', type=float, help='Tumor size')
    parser.add_argument('-u', '--user', type=str, help='User name')
    args = parser.parse_args()

    # Find the configuration file
    path_to_configuration_config_json = "/root/data-transfer-station/configuration/config.json"
    if not os.path.exists(path_to_configuration_config_json):
        raise Exception("Configuration file not found at %s, edit path here" % path_to_configuration_config_json)

    config = None
    with open(path_to_configuration_config_json, 'r') as f:
        conf = json.load(f)
        if "logging" in conf:
            config = conf["logging"]
        else:
            raise Exception("Configuration file does not contain logging section")

    # Initialize the BackendLoggingSQL class with the configuration
    host = config.get("host", "localhost")
    port = config.get("port", 3306)
    dbname = config.get("dbname", "mydatabase")
    driver = config.get("driver", "17")
    c = BackendLoggingSQL(host, port, dbname, driver)

    if args.message is not None:
        c.save_log([{'datetime': datetime.datetime.now(),
                    'accession_number': args.accesson_number,
                    'user': args.user,
                    'status': args.status,
                    'error_message': args.message }
                ])
    if args.tumor_size is not None:
        c.save_prediction([{'datetime': datetime.datetime.now(),
                    'accession_number': args.accession_number,
                    'tumor_size': args.tumor_size }
                ])
