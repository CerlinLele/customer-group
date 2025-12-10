# AWS Glue Databases

## Overview

**Databases** are logical containers used to organize metadata tables in the AWS Glue Data Catalog. Every table created in the data catalog must be mapped to a database.

## Purpose of Databases

### 1. Organize Metadata Tables
- Group related tables into logical databases
- Provide clear organization of data assets
- Facilitate data discovery and management

### 2. Represent Different Data Sources
A data catalog can have one or more databases, each representing different data sources:

**Example: E-commerce System**
```
Data Catalog
├── Database: ecommerce_rds
│   ├── Table: orders
│   ├── Table: customers
│   └── Table: products
├── Database: supplier_data
│   ├── Table: suppliers
│   └── Table: inventory
└── Database: shipment_data
    ├── Table: shipments
    └── Table: tracking
```

### 3. Organize Different Datasets Within the Same Data Source
A single database can contain one or more tables to organize different datasets from the same data source:

**Example: E-commerce RDS Database**
```
ecommerce_rds Database
├── orders table (order information)
├── product_reviews table (product reviews)
├── customers table (customer information)
└── transactions table (transaction records)
```

## Creating Databases

### Method 1: AWS Glue Console

**Steps:**

1. **Open AWS Glue Console**
   - Navigate to the AWS Glue service

2. **Access Data Catalog**
   - Find "Data Catalog" in the left menu
   - Click on "Databases"

3. **View Existing Databases**
   - Display list of all created databases

4. **Create New Database**
   - Click "Add database" button on the right side

5. **Fill in Database Information**
   - **Name** (Required): Unique identifier for the database
   - **Location** (Optional): S3 path or other storage location
   - **Description** (Optional): Explanation and purpose of the database

6. **Create**
   - Click "Create Database" button

### Method 2: AWS SDK (Programmatic)

```python
import boto3

glue_client = boto3.client('glue', region_name='us-east-1')

# Create a database
response = glue_client.create_database(
    DatabaseInput={
        'Name': 'my_database',
        'Description': 'My database for organizing tables',
        'LocationUri': 's3://my-bucket/my-database/'
    }
)
```

### Method 3: Terraform (Infrastructure as Code)

```hcl
resource "aws_glue_catalog_database" "example" {
  name        = "my_database"
  description = "My database for organizing tables"

  parameters = {
    "classification" = "parquet"
  }
}
```

## Database Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| **Name** | ✅ | Database name, must be unique within AWS account |
| **Location** | ❌ | Default location for the database (S3 URI) |
| **Description** | ❌ | Description and purpose of the database |
| **Parameters** | ❌ | Custom properties and metadata |

## After Database Creation

### 1. Database Dashboard
After creation, the system displays a database dashboard containing:
- Basic database information
- Database properties
- All tables contained in the database

### 2. View Database Details
Clicking on a specific database shows:
- **Database Properties**: Name, location, description, etc.
- **Table List**: All tables in the database
- **Table Metadata**: Columns and data types for each table

### 3. Manage Tables
Within a database you can:
- Add new tables
- Edit existing tables
- Delete tables
- View detailed table information

## Best Practices

### 1. Naming Conventions
```
✅ Good naming:
- customer_raw_db (raw data)
- customer_cleaned_db (cleaned data)
- customer_feature_db (feature data)

❌ Avoid:
- db1, db2 (unclear)
- MyDatabase (mixed case)
```

### 2. Organization Structure
```
Organize by data processing stage:
├── raw_data (raw data)
├── cleaned_data (cleaned data)
├── feature_data (feature data)
└── analytics_data (analytics data)

Or organize by data source:
├── rds_database
├── s3_data
└── external_api
```

### 3. Documentation
- Add clear descriptions for each database
- Document the purpose and datasets contained
- Maintain a data dictionary

### 4. Access Control
- Use IAM policies to control database access
- Restrict who can create, modify, or delete databases
- Audit database access and modifications

## Relationship to Data Catalog

```
AWS Glue Data Catalog (Central Repository)
    │
    ├── Database 1: customer_raw_db
    │   ├── Table: raw_customer_base
    │   └── Table: raw_customer_behavior
    │
    ├── Database 2: customer_cleaned_db
    │   ├── Table: cleaned_customer_base
    │   └── Table: cleaned_customer_behavior
    │
    └── Database 3: customer_feature_db
        ├── Table: customer_features
        └── Table: customer_segments
```

## Common Use Cases

### 1. Data Lake Organization
```
data_lake
├── bronze_db (raw data)
├── silver_db (cleaned data)
└── gold_db (business data)
```

### 2. Multi-tenant System
```
├── tenant_a_db
├── tenant_b_db
└── tenant_c_db
```

### 3. Multi-environment Deployment
```
├── dev_db (development environment)
├── staging_db (staging environment)
└── prod_db (production environment)
```

## Key Concepts

### Database vs Table
- **Database**: Logical container for organizing tables
- **Table**: Metadata reference to actual data stored in S3, RDS, or other sources

### Database vs Data Source
- **Database**: Logical grouping in Glue Data Catalog
- **Data Source**: Actual storage location (S3, RDS, etc.)

One database can reference multiple data sources, and one data source can have multiple databases.

## Next Steps

- Learn how to create and manage tables within databases
- Understand how crawlers automatically discover and create tables
- Learn how to query tables in a database
- Configure database-level permissions and access control
- Integrate databases with AWS Athena for SQL queries
