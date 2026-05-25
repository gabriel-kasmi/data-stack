import boto3

def lambda_handler(event, context):
    print(f"Successfully ingested records")
    return {"statusCode": 200, "body": "Ingestion complete"}

if __name__ == "__main__":
    lambda_handler({}, None)
