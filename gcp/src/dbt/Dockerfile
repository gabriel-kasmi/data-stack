FROM ghcr.io/dbt-labs/dbt-core:1.7.0
WORKDIR /usr/app/dbt_project
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV DBT_PROFILES_DIR=.
ENTRYPOINT ["python", "main.py"]
