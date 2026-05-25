import os
import dlt

def run_pipeline():
    secrets_content = os.getenv("DLT_SECRETS")
    
    if secrets_content:
        print("Creating secrets.toml from environment variable...")
        os.makedirs(".dlt", exist_ok=True)
        with open(".dlt/secrets.toml", "w") as f:
            f.write(secrets_content)
    
    print("Running K8s DLT Pipeline...")

if __name__ == "__main__":
    run_pipeline()
