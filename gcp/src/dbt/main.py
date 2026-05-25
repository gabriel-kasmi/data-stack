import os
import subprocess

def main():
    profile_content = os.getenv("DBT_PROFILES")
    
    if profile_content:
        print("Creating profiles.yml from environment variable...")
        with open("profiles.yml", "w") as f:
            f.write(profile_content)
    
    dbt_command = os.getenv("DBT_COMMAND", "dbt run")
    print(f"Executing: {dbt_command}")
    
    subprocess.run(dbt_command.split(), check=True)

if __name__ == "__main__":
    main()
