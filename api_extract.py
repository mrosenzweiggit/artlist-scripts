import requests
import time
import json
import certifi
# import snowflake.connector
import os
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
    "schema_raw": "DATA_LAKE",
    "schema_dwh": "DATA_DWH"
}

# ----------------------------
# Rick & Morty API endpoints
# ----------------------------
ENDPOINTS = {
    "characters": "https://rickandmortyapi.com/api/character",
    "episodes": "https://rickandmortyapi.com/api/episode",
    # "locations": "https://rickandmortyapi.com/api/location"
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
# Insert data into Snowflake
# ----------------------------
def ingest_endpoint(endpoint_name, url, conn):
    """Ingest all pages of an endpoint into its raw Snowflake table."""
    cursor = conn.cursor()
    page = 1
    try:
        while True:
            page_url = f"{url}?page={page}"
            data = fetch_with_backoff(page_url)

            table_name = f"RAW_{endpoint_name.upper()}"
            cursor.execute(
                f"""
                INSERT INTO {table_name} (page, raw_json)
                SELECT %s, PARSE_JSON(%s)
                """,
                (page, json.dumps(data))
            )

            print(f"Saved page {page} in {table_name}")

            # Check if there are more pages
            if "info" in data and data["info"].get("next"):
                page += 1
            else:
                break
    finally:
        cursor.close()

# ----------------------------
# Insert data locally
# ----------------------------
def ingest_endpoint_loc(endpoint_name, url):
    """Fetch all pages of an endpoint and save them as JSON files locally."""
    page = 1
    downloads_path = os.path.expanduser("~/Downloads/raw_data")  # Carpeta base raw_data
    os.makedirs(downloads_path, exist_ok=True)

    while True:
        page_url = f"{url}?page={page}"
        data = fetch_with_backoff(page_url)

        local_filename = os.path.join(downloads_path, f"{endpoint_name}_page_{page}.json")
        with open(local_filename, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"Saved page {page} JSON at: {local_filename}")

        # Verificar si hay más páginas
        if "info" in data and data["info"].get("next"):
            page += 1
        else:
            break


# ----------------------------
# Main function
# ----------------------------
#

# ----------------------------
# Run script
# ----------------------------
# if __name__ == "__main__":
#     main()

# def main():
#     for name, url in ENDPOINTS.items():
#         print(f"\nFetching data from {name}...")
#         ingest_endpoint_loc(name, url)
#     print("\n✅ All endpoints extracted successfully!")
#
# # ----------------------------
# # Run script
# # ----------------------------
# if __name__ == "__main__":
#     # ----------------------------
#     # Test fetch_with_backoff
#     # ----------------------------
#     test_url = "https://rickandmortyapi.com/api/character"
#     try:
#         print(f"Fetching data from {test_url}...")
#         data = fetch_with_backoff(test_url, max_retries=3)
#         print("✅ Fetch successful!")
#         print("Keys in response:", list(data.keys()))
#         print("Number of results on this page:", len(data.get("results", [])))
#     except Exception as e:
#         print("❌ Fetch failed:", e)
#     # ----------------------------
#     # Full extraction to Downloads
#     # ----------------------------
#     main()