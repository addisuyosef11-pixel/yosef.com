# apps.py
from django.apps import AppConfig

class catConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'cat'

    def ready(self):
        import cat.signals

