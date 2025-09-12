import snowflake

from api_services import api_extract
from api_services.api_extract import ENDPOINTS, ingest_endpoint


def main():
    try:
        for name, url in api_extract.ENDPOINTS.items():
            print(f"\nStarting extract for {name}...")
            api_extract.ingest_endpoint_loc(name, url)
        print("\n✅ All endpoints extracted successfully!")
    except Exception as e:
        print("❌ Fetch failed:", e)

if __name__ == "__main__":
    main()


# def main():
#     conn = snowflake.connector.connect(
#         user=SNOWFLAKE_CONFIG["user"],
#         password=SNOWFLAKE_CONFIG["password"],
#         account=SNOWFLAKE_CONFIG["account"],
#         warehouse=SNOWFLAKE_CONFIG["warehouse"],
#         database=SNOWFLAKE_CONFIG["database"],
#         schema=SNOWFLAKE_CONFIG["schema_raw"],
#         # ssl_ca_cert=certifi.where(),  # Use system CA certificates
#         application='RickMortyIngest',
#         client_session_keep_alive=True,
#         insecure_mode=False  # Only uncomment for testing if SSL fails
#     )
#
#     try:
#         for name, url in ENDPOINTS.items():
#             print(f"\nStarting extract for {name}...")
#             ingest_endpoint(name, url, conn)
#     finally:
#         conn.close()
#         print("\n✅ Extract finished.")