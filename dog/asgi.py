"""
ASGI config for dog project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/asgi/
"""

import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import chat.routing
import aviator.routing

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog.settings')

# Combine all websocket URL patterns
websocket_urlpatterns = (
    chat.routing.websocket_urlpatterns +
    aviator.routing.websocket_urlpatterns
)

# Main ASGI application
application = ProtocolTypeRouter({
    "http": get_asgi_application(),  # Handles normal HTTP requests
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
