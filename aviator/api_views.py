


from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
import random, time

# 🧠 Example: Start new Aviator round (non-realtime)
@api_view(['GET'])
@permission_classes([AllowAny])  # or IsAuthenticated if you need auth
def aviator_start_api(request):
    crash_point = round(random.uniform(1.1, 10.0), 2)
    return Response({
        "round_id": int(time.time()),
        "crash_point": crash_point,
        "message": "Aviator round initialized"
    })


# 🧠 Example: Get previous rounds (mock)
@api_view(['GET'])
@permission_classes([AllowAny])
def aviator_history_api(request):
    data = [
        {"round_id": 101, "crash": 2.35},
        {"round_id": 102, "crash": 7.42},
        {"round_id": 103, "crash": 1.87},
    ]
    return Response({"history": data})