from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
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



