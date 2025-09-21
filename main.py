import certifi
from api_services import api_extract
from snowflake.snowpark import Session
from typing import Optional
from snowflake.snowpark import Session
from api_services import api_extract
import sys


def get_snowflake_session() -> Optional[Session]:
    connection_parameters = api_extract.SNOWFLAKE_CONFIG
    try:
        print("🔌 Connecting to Snowflake...")
        session = Session.builder.configs(connection_parameters).create()
        print("✅ Connected!")
        return session
    except Exception as e:
        print(f"⚠️ Could not connect to Snowflake: {e}", file=sys.stderr)
        return None


# ----------------------------
# Main 1: ingest da de API
# ----------------------------
def main_1():
    session = get_snowflake_session()

    try:
        for name, url in api_extract.ENDPOINTS.items():
            print(f"\nStarting extract for {name}...")
            api_extract.ingest_endpoint_loc(name, url)
            # api_extract.ingest_endpoint(name, url, session)

        print("\n✅ All endpoints extracted successfully!")
    except Exception as e:
        print("❌ Fetch failed:", e)
    finally:
        session.close()
        print("🔒 Session closed")


# ----------------------------
# Main 2: connection test
# ----------------------------
def main_2():
    session = get_snowflake_session()

    try:
        table_name = "TEST_TABLE"
        session.sql(f"DROP TABLE IF EXISTS {table_name}").collect()
        session.sql(f"""
            CREATE TABLE {table_name} (
                id INT,
                name STRING
            )
        """).collect()

        session.sql(f"""
            INSERT INTO {table_name} VALUES
            (1, 'Hello artlist'),
            (2, 'Snowpark'),
            (3, 'Test')
        """).collect()

        df = session.table(table_name)
        df.show()

    finally:
        session.close()
        print("🔒 Session closed")


if __name__ == "__main__":
    main_1()
    # main_2()











# import snowflake
#
# from api_services import api_extract
# from api_services.api_extract import ENDPOINTS, ingest_endpoint
#
#
# def main():
#     try:
#         for name, url in api_extract.ENDPOINTS.items():
#             print(f"\nStarting extract for {name}...")
#             api_extract.ingest_endpoint_loc(name, url)
#         print("\n✅ All endpoints extracted successfully!")
#     except Exception as e:
#         print("❌ Fetch failed:", e)
#
# if __name__ == "__main__":
#     main()
#
#
# # def main():
# #     conn = snowflake.connector.connect(
# #         user=SNOWFLAKE_CONFIG["user"],
# #         password=SNOWFLAKE_CONFIG["password"],
# #         account=SNOWFLAKE_CONFIG["account"],
# #         warehouse=SNOWFLAKE_CONFIG["warehouse"],
# #         database=SNOWFLAKE_CONFIG["database"],
# #         schema=SNOWFLAKE_CONFIG["schema_raw"],
# #         # ssl_ca_cert=certifi.where(),  # Use system CA certificates
# #         application='RickMortyIngest',
# #         client_session_keep_alive=True,
# #         insecure_mode=False  # Only uncomment for testing if SSL fails
# #     )
# #
# #     try:
# #         for name, url in ENDPOINTS.items():
# #             print(f"\nStarting extract for {name}...")
# #             ingest_endpoint(name, url, conn)
# #     finally:
# #         conn.close()
# #         print("\n✅ Extract finished.")