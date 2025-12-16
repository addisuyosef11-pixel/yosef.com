# reset_migrations.py
import os
import shutil
import subprocess
import sqlite3

def reset_migrations():
    print("=" * 60)
    print("COMPLETE MIGRATION HISTORY RESET")
    print("=" * 60)
    print("WARNING: This will delete ALL database data!")
    print("=" * 60)
    
    confirm = input("Type 'YES' to continue: ")
    if confirm != 'YES':
        print("Cancelled.")
        return
    
    # 1. Delete database
    db_files = ['db.sqlite3', 'dev.db', 'test.db']
    for db_file in db_files:
        if os.path.exists(db_file):
            os.remove(db_file)
            print(f"✓ Deleted database: {db_file}")
    
    # 2. Delete all migration files
    for root, dirs, files in os.walk('.'):
        if 'migrations' in dirs:
            migrations_dir = os.path.join(root, 'migrations')
            for file in os.listdir(migrations_dir):
                if file != '__init__.py':
                    file_path = os.path.join(migrations_dir, file)
                    try:
                        if os.path.isfile(file_path):
                            os.remove(file_path)
                        elif os.path.isdir(file_path):
                            shutil.rmtree(file_path)
                    except:
                        pass
    
    # 3. Delete all __pycache__ directories
    for root, dirs, files in os.walk('.'):
        for dir_name in dirs:
            if dir_name == '__pycache__':
                shutil.rmtree(os.path.join(root, dir_name))
    
    # 4. Recreate __init__.py in migrations folders
    for root, dirs, files in os.walk('.'):
        if 'migrations' in dirs:
            migrations_dir = os.path.join(root, 'migrations')
            init_file = os.path.join(migrations_dir, '__init__.py')
            with open(init_file, 'w') as f:
                f.write('# Fresh start\n')
    
    print("\n" + "=" * 60)
    print("Running fresh migrations...")
    print("=" * 60)
    
    # 5. Run migrations
    subprocess.run(['python', 'manage.py', 'makemigrations'])
    subprocess.run(['python', 'manage.py', 'migrate'])
    
    print("\n" + "=" * 60)
    print("Reset complete!")
    print("=" * 60)
    print("\nNow create a superuser:")
    print("python manage.py createsuperuser")
    print("\nOr run the server:")
    print("python manage.py runserver")
    print("=" * 60)

if __name__ == '__main__':
    reset_migrations()