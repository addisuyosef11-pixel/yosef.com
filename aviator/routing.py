from django.urls import re_path
from .consumers import AviatorConsumer

websocket_urlpatterns = [
    re_path(r"ws/aviator/$", AviatorConsumer.as_asgi()),
]
