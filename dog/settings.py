import os
from pathlib import Path

# -------------------------------------------------
# Base Directory
# -------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent

# -------------------------------------------------
# Security
# -------------------------------------------------
SECRET_KEY = 'django-insecure-your_secret_key_here'
DEBUG = True
ALLOWED_HOSTS = ['127.0.0.1', 'localhost', '*', '192.168.137.1']

# -------------------------------------------------
# Installed Apps - IMPORTANT: ORDER MATTERS!
# -------------------------------------------------
INSTALLED_APPS = [
    # Django core apps (must come first)
    
    'django.contrib.auth',           # MUST come before 'cat'
    'django.contrib.contenttypes',   # MUST come before 'cat'
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    
    # Third-party apps
    'jazzmin',
    'django.contrib.admin',                      # Moved after django apps
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'phonenumber_field',
    'widget_tweaks',
    'channels',
   
    # Local apps (must come after auth and contenttypes)
    'cat',                          # Your custom user model app
    'chat',
    'aviator',
]

# -------------------------------------------------
# Custom User Model - MUST be set BEFORE any imports
# -------------------------------------------------
AUTH_USER_MODEL = 'cat.User'

# -------------------------------------------------
# Middleware
# -------------------------------------------------
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.locale.LocaleMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'cat.middleware.ReferralMiddleware',
]

# -------------------------------------------------
# REST Framework Configuration
# -------------------------------------------------
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# -------------------------------------------------
# CORS (for Flutter frontend)
# -------------------------------------------------
CORS_ALLOW_ALL_ORIGINS = True  # ✅ OK for dev
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    'authorization',
    'content-type',
    'accept',
    'origin',
    'user-agent',
    'dnt',
    'x-csrftoken',
    'x-requested-with',
]

# -------------------------------------------------
# URL Configuration
# -------------------------------------------------
ROOT_URLCONF = 'dog.urls'

# -------------------------------------------------
# Templates
# -------------------------------------------------
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# -------------------------------------------------
# WSGI / ASGI
# -------------------------------------------------
WSGI_APPLICATION = 'dog.wsgi.application'
ASGI_APPLICATION = 'dog.asgi.application'  # ✅ WebSocket support

# -------------------------------------------------
# Database - SIMPLIFIED FOR NOW
# -------------------------------------------------
# Remove dj_database_url import and use simple SQLite
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# -------------------------------------------------
# Password Validators
# -------------------------------------------------
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# -------------------------------------------------
# Internationalization
# -------------------------------------------------
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# -------------------------------------------------
# Static and Media Files
# -------------------------------------------------
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# -------------------------------------------------
# Authentication Redirects
# -------------------------------------------------
LOGIN_URL = '/login/'
LOGIN_REDIRECT_URL = '/home/'
LOGOUT_REDIRECT_URL = '/login/'

# -------------------------------------------------
# Authentication Backends
# -------------------------------------------------
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
]

# -------------------------------------------------
# Email Configuration
# -------------------------------------------------
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
EMAIL_USE_TLS = True
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_HOST_USER = 'addisuyosef11@gmail.com'
EMAIL_HOST_PASSWORD = 'fzph nevp fqda xqjf'
DEFAULT_FROM_EMAIL = 'cat <noreply@shiene.com>'

# -------------------------------------------------
# Jazzmin Admin Customization
# -------------------------------------------------
JAZZMIN_SETTINGS = {
    "custom_index_template": "admin/index.html",
    "site_title": "TrustInvest Admin",
    "site_header": "TrustInvest Dashboard",
    "welcome_sign": "Welcome to TrustInvest Admin Panel",
}

JAZZMIN_UI_TWEAKS = {
    "theme": "lumen",
    "navbar_fixed": True,
    "footer_fixed": False,
    "body_small_text": True,
    "custom_css": "css/custom_admin.css",
    "custom_js": "Js/custom_admin.js",
}

# -------------------------------------------------
# Chapa Keys (for testing)
# -------------------------------------------------
CHAPA_SECRET_KEY = "CHASECK_TEST-pTLNb1zDAmpaG4TX9Gbl8MznLLbQqDDv"
CHAPA_PUBLIC_KEY = "CHAPUBK_TEST-JXCIMqrKxB26W3fJYkWDLG3M1vvUF6nJ"

# -------------------------------------------------
# Channels / Redis (for WebSocket Aviator + Chat)
# -------------------------------------------------
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [('127.0.0.1', 6379)],
        },
    },
}

# -------------------------------------------------
# Default primary key field
# -------------------------------------------------
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# -------------------------------------------------
# Languages
# -------------------------------------------------
LANGUAGES = [
    ('en', 'English'),
    ('am', 'Amharic'),
]
LOCALE_PATHS = [BASE_DIR / 'locale']

# -------------------------------------------------
