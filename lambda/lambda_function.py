import json
import pymysql
import boto3
import os
from botocore.exceptions import ClientError

def get_db_credentials():
    try:
        secret_arn = os.environ["DB_SECRET"]
        region_name = "eu-west-1"
        
        client = boto3.client("secretsmanager", region_name=region_name)

        response = client.get_secret_value(SecretId=secret_arn)
    
        secret = json.loads(response["SecretString"])

        db_name = secret["db_name"]
        db_user = secret["username"]
        db_password = secret["password"]

        return db_user, db_password, db_name
    except ClientError as e:
        print(f"Secrets Manager error: {e}")
        raise

def lambda_handler(event, context):
    try:
        # Get database configuration
        db_host = os.environ["DB_HOST"]
        db_user, db_password, db_name = get_db_credentials()
        
        # Validate credentials
        if not all([db_host, db_user, db_password, db_name]):
            raise ValueError("Missing database configuration")

        print(db_name, db_user, db_password, db_host)

        # Set shorter connection timeout
        conn = pymysql.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name,
        )
        
        with conn.cursor() as cursor:
            create_table_sql = """
            CREATE TABLE IF NOT EXISTS tasks (
                id INT AUTO_INCREMENT PRIMARY KEY,
                task VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
            cursor.execute(create_table_sql)
            conn.commit()
            
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Table created successfully!"})
        }

    except pymysql.Error as e:
        print(f"Database error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Database error: {str(e)}"})
        }
    except Exception as e:
        print(f"General error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
    finally:
        if 'conn' in locals() and conn:
            conn.close()