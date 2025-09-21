import requests
import time
import json
import certifi
import os
from snowflake.snowpark import Session
from snowflake.snowpark.functions import lit, parse_json
from datetime import datetime

# ----------------------------
# Snowflake configuration
# ----------------------------
SNOWFLAKE_CONFIG = {
    "user": "MROSENZWEIG",
    "password": "KB64usRHxJu9QQS",
    "account": "JRHDVKQ-AS11050",
    "warehouse": "COMPUTE_WH",
    "database": "ARTLIST_DB",
    "schema": "DATA_LAKE",
    # "role": "your_role",
}

# ----------------------------
# Rick & Morty API endpoints
# ----------------------------
ENDPOINTS = {
    "characters": "https://rickandmortyapi.com/api/character",
    "episodes": "https://rickandmortyapi.com/api/episode",
}

# ----------------------------
# Fetch data with exponential backoff
# ----------------------------
def fetch_with_backoff(url, max_retries=5):
    """Fetch data from API with exponential backoff."""
    backoff = 1
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=15, verify=certifi.where())
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Error: {e}. Retrying in {backoff} seconds...")
            time.sleep(backoff)
            backoff *= 2
    raise Exception(f"Max retries reached for {url}")

# ----------------------------
# Insert data using Snowpark
# ----------------------------
def ingest_endpoint(endpoint_name, url, session: Session):
    """Ingest all pages of an endpoint into its raw Snowflake table using Snowpark."""
    page = 1
    table_name = f"RAW_{endpoint_name.upper()}_1"

    while True:
        page_url = f"{url}?page={page}"
        data = fetch_with_backoff(page_url)

        # Create Snowpark DataFrame (solo page + raw_json)
        df = session.create_dataframe(
            [[page, json.dumps(data)]],
            schema=["page", "raw_json"]
        ).with_column("raw_json", parse_json("raw_json"))

        # Insert into Snowflake (fetched_at se autocompleta)
        # df.write.mode("append").save_as_table(f"{SNOWFLAKE_CONFIG['schema']}.{table_name}")
        df.write.mode("append").save_as_table(f"{SNOWFLAKE_CONFIG['schema']}.{table_name}",column_order="name")

        print(f"✅ Saved page {page} in {table_name}")

        # Next page?
        if "info" in data and data["info"].get("next"):
            page += 1
        else:
            break


# ----------------------------
# Insert data locally (sin cambios)
# ----------------------------
def ingest_endpoint_loc(endpoint_name, url):
    """Fetch all pages of an endpoint and save them as JSON files locally."""
    page = 1
    downloads_path = os.path.expanduser("~/Downloads/raw_data")
    os.makedirs(downloads_path, exist_ok=True)

    while True:
        page_url = f"{url}?page={page}"
        data = fetch_with_backoff(page_url)

        local_filename = os.path.join(downloads_path, f"{endpoint_name}page{page}.json")
        with open(local_filename, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"Saved page {page} JSON at: {local_filename}")

        if "info" in data and data["info"].get("next"):
            page += 1
        else:
            break

# # ----------------------------
# # Main: ejecutar el proceso
# # ----------------------------
# if _name_ == "_main_":
#     # Crear sesión de Snowpark
#     session = Session.builder.configs(SNOWFLAKE_CONFIG).create()
#
#     for name, url in ENDPOINTS.items():
#         ingest_endpoint(name, url, session)
#
#     session.close()