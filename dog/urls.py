from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView  # Add this import
from django.http import JsonResponse  # Add this import
from django.views.decorators.csrf import csrf_exempt  # Add this import

# Simple view for root URL
@csrf_exempt
def home_view(request):
    return JsonResponse({
        'app': 'Yosef.com',
        'version': '1.0',
        'status': 'API is running',
        'message': 'Welcome to Yosef.com API',
        'endpoints': {
            'api': '/api/',
            'admin': '/admin/',
            'accounts': '/accounts/',
            'aviator': '/api/aviator/'
        },
        'documentation': 'API documentation available at /api/'
    })

urlpatterns = [
    # Home/Root page
    path('', home_view, name='home'),
    
    # Admin panel
    path('admin/', admin.site.urls),

    # API routes for Flutter
    path('api/', include('cat.api_urls')),  # <-- all your API endpoints go here
    path('api/aviator/', include('aviator.api_urls')),
    
    # Optional: default Django auth (HTML-based) if needed
    path('accounts/', include('django.contrib.auth.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)