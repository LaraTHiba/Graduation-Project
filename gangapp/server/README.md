# Django Project Setup and Common Commands

This guide provides instructions for setting up a Django project and common commands used during development.

## Prerequisites

*   Python 3.x installed
*   pip (Python package installer)

## 1. Setting Up a Virtual Environment

It's highly recommended to use a virtual environment for each Django project to manage dependencies separately.

### Create a virtual environment:

```bash
python -m venv venv
```

(`venv` is the name of the virtual environment directory, you can choose another name).

### Activate the virtual environment:

*   **Windows (PowerShell/CMD):**
    ```bash
    .\venv\Scripts\activate
    ```
*   **macOS/Linux (Bash/Zsh):**
    ```bash
    source venv/bin/activate
    ```

You should see the virtual environment name (e.g., `(venv)`) prefixed to your shell prompt.

## 2. Installing Django

With the virtual environment activated, install Django using pip:

```bash
pip install django
```

## 3. Creating a Django Project

Navigate to the directory where you want to create your project and run:

```bash
django-admin startproject <project_name> .
```

*   Replace `<project_name>` with the desired name for your project (e.g., `myproject`).
*   The `.` at the end creates the project in the current directory. Omitting it will create a new directory with the project name.

This command creates the basic project structure, including `manage.py` and a directory named `<project_name>` containing project-level settings (`settings.py`, `urls.py`, etc.).

## 4. Creating a Django App

Apps are modules within your Django project that encapsulate specific functionalities (e.g., a blog, user authentication).

Navigate into your project directory (where `manage.py` is located) and run:

```bash
python manage.py startapp <app_name>
```

*   Replace `<app_name>` with the desired name for your app (e.g., `myapp`, `blog`).

This creates a directory named `<app_name>` with files like `models.py`, `views.py`, `admin.py`, etc.

### Register the App

After creating an app, you need to tell Django about it. Open `<project_name>/settings.py` and add your app's configuration class name (usually `apps.<AppName>Config`) to the `INSTALLED_APPS` list:

```python
# <project_name>/settings.py

INSTALLED_APPS = [
    # ... other default apps
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    '<app_name>.apps.<AppName>Config', # e.g., 'myapp.apps.MyappConfig'
    # ... or simply '<app_name>' if you don't have a custom AppConfig
]
```

## 5. Database Migrations

Whenever you create or modify database models (in `models.py`), you need to create and apply migrations.

### Create migrations:

```bash
python manage.py makemigrations
```

(If you created a new app, you might need to specify the app name: `python manage.py makemigrations <app_name>`)

### Apply migrations:

```bash
python manage.py migrate
```

This command applies the pending migrations, creating or updating the database schema. Run `migrate` initially to set up the tables for Django's built-in apps.

## 6. Running the Development Server

Start the development server to test your application:

```bash
python manage.py runserver
```

By default, the server runs at `http://127.0.0.1:8000/`. You can access it in your web browser. Press `Ctrl+C` in the terminal to stop the server.

## 7. Creating a Superuser

A superuser has all permissions in the Django admin interface.

```bash
python manage.py createsuperuser
```

Follow the prompts to set a username, email (optional), and password.

You can then access the admin interface at `http://127.0.0.1:8000/admin/` and log in with the superuser credentials.

## 8. Managing Dependencies (`requirements.txt`)

To ensure others (or your future self) can replicate the project's environment, list the dependencies in a `requirements.txt` file.

### Generate `requirements.txt`:

Make sure your virtual environment is activated.

```bash
pip freeze > requirements.txt
```

This command lists all installed packages and their versions in the `requirements.txt` file.

### Install dependencies from `requirements.txt`:

On a new machine or in a new virtual environment, you can install all required packages using:

```bash
pip install -r requirements.txt
```

## 9. Deactivating the Virtual Environment

When you're done working on the project, you can deactivate the virtual environment:

```bash
deactivate
```

Remember to reactivate it (`.\venv\Scripts\activate` or `source venv/bin/activate`) the next time you work on the project. 