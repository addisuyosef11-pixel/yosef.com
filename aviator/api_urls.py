from django.urls import path
from . import api_views

urlpatterns = [
    
    path('start/', api_views.aviator_start_api, name='api_aviator_start'),
    path('history/', api_views.aviator_history_api, name='api_aviator_history'),


]
