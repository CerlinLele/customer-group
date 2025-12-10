#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Windows Spark Configuration Verification Script
Test Spark data write functionality on Windows
"""

import os
import sys
from pathlib import Path

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def test_spark_setup():
    """Test Spark and Hadoop configuration"""
    print("=" * 80)
    print("Windows Spark Configuration Verification")
    print("=" * 80)

    # 1. Check environment variables
    print("\n1. Environment Variables Check:")
    required_vars = ["JAVA_HOME", "SPARK_HOME"]
    for var in required_vars:
        value = os.environ.get(var)
        status = "OK" if value else "MISSING"
        print(f"  [{status}] {var}: {value or 'Not set'}")

    # 2. Check path existence
    print("\n2. Path Existence Check:")
    paths_to_check = {
        "JAVA_HOME": os.environ.get("JAVA_HOME"),
        "SPARK_HOME": os.environ.get("SPARK_HOME"),
    }

    for name, path in paths_to_check.items():
        if path:
            exists = Path(path).exists()
            status = "OK" if exists else "NOT FOUND"
            print(f"  [{status}] {name}: {path}")
        else:
            print(f"  [MISSING] {name}: Not set")

    # 3. Try importing PySpark
    print("\n3. PySpark Import Check:")
    try:
        from pyspark.sql import SparkSession
        print("  [OK] Can import SparkSession")
    except Exception as e:
        print(f"  [ERROR] Failed to import SparkSession: {e}")
        return False

    # 4. Create Spark Session
    print("\n4. Spark Session Creation:")
    try:
        spark = SparkSession.builder \
            .appName("TestSetup") \
            .master("local[1]") \
            .config("spark.hadoop.fs.file.impl", "org.apache.hadoop.fs.LocalFileSystem") \
            .config("spark.sql.shuffle.partitions", "1") \
            .getOrCreate()

        print(f"  [OK] Spark Session created successfully")
        print(f"       Version: {spark.version}")
        spark.stop()
    except Exception as e:
        print(f"  [ERROR] Failed to create Spark Session: {e}")
        return False

    # 5. Test data write
    print("\n5. Data Write Test:")
    test_dir = Path.cwd() / "spark_test_output"
    test_dir.mkdir(exist_ok=True)
    test_file = test_dir / "test.csv"

    try:
        spark = SparkSession.builder \
            .appName("TestWrite") \
            .master("local[1]") \
            .config("spark.hadoop.fs.file.impl", "org.apache.hadoop.fs.LocalFileSystem") \
            .getOrCreate()

        # Create simple test data
        data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
        df = spark.createDataFrame(data, ["name", "age"])

        # Method 1: Using Pandas
        try:
            df.toPandas().to_csv(str(test_file), index=False)
            print(f"  [OK] Pandas write successful: {test_file}")

            # Verify file exists
            if test_file.exists():
                size = test_file.stat().st_size
                print(f"       File size: {size} bytes")
        except Exception as e:
            print(f"  [ERROR] Pandas write failed: {e}")

        # Method 2: Using Spark distributed write
        try:
            spark_output = test_dir / "test_spark"
            if spark_output.exists():
                import shutil
                shutil.rmtree(spark_output)

            df.write.mode("overwrite").csv(str(spark_output))
            print(f"  [OK] Spark distributed write successful: {spark_output}")
        except Exception as e:
            print(f"  [WARNING] Spark distributed write failed: {e}")
            print(f"             This is expected without Hadoop, but Pandas should work")

        spark.stop()

    except Exception as e:
        print(f"  [ERROR] Write test failed: {e}")
        return False

    print("\n" + "=" * 80)
    print("Verification Complete!")
    print("=" * 80)
    print("\nRecommendations:")
    print("- Use Pandas method (toPandas().to_csv()) for local file writes")
    print("- For Spark distributed write, configure HADOOP_HOME environment variable")
    print("- See WINDOWS_SPARK_FIX.md for more information")

    return True

if __name__ == "__main__":
    # Configure environment variables
    if 'JAVA_HOME' not in os.environ:
        os.environ['JAVA_HOME'] = "C:\\Program Files\\Java\\jdk-11"

    if 'SPARK_HOME' not in os.environ:
        os.environ['SPARK_HOME'] = "C:\\Users\\hy120\\spark\\spark-3.5.7-bin-hadoop3"

    os.environ["PYSPARK_PYTHON"] = sys.executable
    os.environ["PYSPARK_DRIVER_PYTHON"] = sys.executable

    success = test_spark_setup()
    sys.exit(0 if success else 1)
