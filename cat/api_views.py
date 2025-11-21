from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate, get_user_model
from django.utils import timezone
from rest_framework.authtoken.models import Token
from django.db.models import Sum
from .models import (
    Profile, Transaction, OTP, VIP, UserVIP, Task, Message, Order, Recharge, CustomerMessage
)
from .serializers import (
    ProfileSerializer, TransactionSerializer, UserVIPSerializer, TaskSerializer,
    MessageSerializer, OrderSerializer, RechargeSerializer, CustomerMessageSerializer
)

User = get_user_model()

# --------------------------
# AUTH APIs
# --------------------------


# views.py
import random, string
from datetime import timedelta
from django.utils import timezone
from django.contrib.auth.models import User
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from django.conf import settings
import json

from .models import OTP
import africastalking


def send_sms(phone_number, message):
    africastalking.initialize(settings.AFRICASTALKING_USERNAME, settings.AFRICASTALKING_API_KEY)
    sms = africastalking.SMS
    try:
        sms.send(message, [phone_number])
        return True
    except Exception as e:
        print("SMS sending error:", e)
        return False


@csrf_exempt
@require_POST
def signup_api(request):
    data = json.loads(request.body.decode('utf-8'))
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    phone = data.get('phone')

    # Validate required fields
    if not all([username, email, password, phone]):
        return JsonResponse({'error': 'All fields are required.'}, status=400)

    if User.objects.filter(username=username).exists():
        return JsonResponse({'error': 'Username already taken.'}, status=400)

    # Create user
    user = User.objects.create_user(username=username, email=email, password=password)

    # Create OTP
    otp_obj, created = OTP.objects.get_or_create(user=user)
    otp_obj.otp_code = ''.join(random.choices(string.digits, k=6))
    otp_obj.created_at = timezone.now()
    otp_obj.expires_at = otp_obj.created_at + timedelta(minutes=1)
    otp_obj.save()

    # Send OTP via SMS
    message = f"Hello {username}, your verification code is {otp_obj.otp_code}. It expires in 1 minute."
    send_sms(phone, message)

    return JsonResponse({'message': 'User created successfully. OTP sent to phone.'})




@csrf_exempt
@require_POST
def verify_otp(request):
    data = json.loads(request.body.decode('utf-8'))
    username = data.get('username')
    otp_code = data.get('otp')

    try:
        user = User.objects.get(username=username)
        otp_obj = OTP.objects.get(user=user)
    except (User.DoesNotExist, OTP.DoesNotExist):
        return JsonResponse({'error': 'Invalid user or OTP.'}, status=400)

    if otp_obj.is_expired():
        return JsonResponse({'error': 'OTP expired.'}, status=400)

    if otp_obj.otp_code != otp_code:
        return JsonResponse({'error': 'Incorrect OTP.'}, status=400)

    otp_obj.is_verified = True
    otp_obj.save()

    return JsonResponse({'message': 'OTP verified successfully!'})



@api_view(['POST'])
@permission_classes([AllowAny])
def login_api(request):
    username = request.data.get('username')
    password = request.data.get('password')
    user = authenticate(request, username=username, password=password)

    if not user:
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

    token, _ = Token.objects.get_or_create(user=user)
    return Response({'token': token.key, 'username': user.username})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_api(request):
    request.auth.delete()
    return Response({'message': 'Logged out successfully'})

# --------------------------
# PROFILE / DASHBOARD
# --------------------------







from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from cat.models import Profile
from cat.serializers import ProfileSerializer,CommissionSerializer
import logging

logger = logging.getLogger(__name__)
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
import logging

logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile_api(request):
    """
    Return the profile of the authenticated user.
    If the user does not have a profile yet, create one.
    Includes account_number.
    """
    try:
        # Get or create the profile
        profile, created = Profile.objects.get_or_create(user=request.user)

        # Serialize
        serializer = ProfileSerializer(profile)
        data = serializer.data

        # Add account number explicitly (if not already in serializer)
        data['account_number'] = profile.account_number

        return Response(data)

    except Exception as e:
        # Log full traceback
        logger.exception("Error fetching profile for user %s", request.user.username)
        
        # Return safe error message for Flutter
        return Response(
            {"error": "Failed to fetch profile. Please contact support."},
            status=500
        )



@api_view(['GET'])
@permission_classes([IsAuthenticated])
def balance_api(request):
    """
    Return the balance details for the authenticated user.
    Includes total balance, available balance, frozen balance, and transaction history.
    """
    try:
        user = request.user
        transactions = Transaction.objects.filter(customer=user).order_by('-date')

        # Calculate total deposits and withdrawals
        total_deposit = transactions.filter(type='deposit').aggregate(total=Sum('amount'))['total'] or 0
        total_withdraw = transactions.filter(type='withdraw').aggregate(total=Sum('amount'))['total'] or 0

        # Calculate balances
        balance = float(total_deposit - total_withdraw)
        # Example: You can define available_balance and frozen_balance as needed
        # For simplicity, let's assume 10% of balance is frozen
        frozen_balance = float(balance * 0.01)
        available_balance = float(balance - frozen_balance)

        serializer = TransactionSerializer(transactions, many=True)

        return Response({
            'balance': balance,
            'available_balance': available_balance,
            'frozen_balance': frozen_balance,
            'transactions': serializer.data
        })

    except Exception as e:
        logger.exception("Error fetching balance for user %s", request.user.username)
        return Response(
            {"error": "Failed to fetch balance. Please contact support."},
            status=500
        )



@api_view(['POST'])
@permission_classes([IsAuthenticated])
def withdraw_api(request):
    amount = request.data.get('amount')
    user = request.user
    transactions = Transaction.objects.filter(customer=user)
    balance = transactions.filter(type='deposit').aggregate(total=Sum('amount'))['total'] or 0
    balance -= transactions.filter(type='withdraw').aggregate(total=Sum('amount'))['total'] or 0

    if not amount or float(amount) <= 0:
        return Response({'error': 'Invalid amount'}, status=status.HTTP_400_BAD_REQUEST)
    if float(amount) > balance:
        return Response({'error': 'Insufficient balance'}, status=status.HTTP_400_BAD_REQUEST)

    Transaction.objects.create(customer=user, type='withdraw', amount=amount)
    return Response({'message': f'Withdrawal request {amount} submitted'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def withdraw_history_api(request):
    withdrawals = Transaction.objects.filter(customer=request.user, type='withdraw').order_by('-date')
    serializer = TransactionSerializer(withdrawals, many=True)
    return Response(serializer.data)


# --------------------------
# VIP / TASK
# --------------------------
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import VIP
from .serializers import VIPSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vip_packages_api(request):
    vips = VIP.objects.all().order_by('upgrade')
    serializer = VIPSerializer(vips, many=True)
    return Response(serializer.data)



from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Sum
from django.utils import timezone
from .models import UserVIP, VIP, Transaction

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def buy_vip_api(request):
    vip_id = request.data.get('vip_id')
    user = request.user

    # Validate VIP package
    try:
        vip_package = VIP.objects.get(id=vip_id)
    except VIP.DoesNotExist:
        return Response({'error': 'VIP not found'}, status=status.HTTP_404_NOT_FOUND)

    # Calculate user balance
    transactions = Transaction.objects.filter(customer=user)
    deposit_sum = transactions.filter(type='deposit').aggregate(total=Sum('amount'))['total'] or 0
    withdraw_sum = transactions.filter(type='withdraw').aggregate(total=Sum('amount'))['total'] or 0
    balance = deposit_sum - withdraw_sum

    if balance < vip_package.price:
        return Response({'error': 'Insufficient balance'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Create or update VIP first
        user_vip, created = UserVIP.objects.get_or_create(
            user=user,
            defaults={
                'vip': vip_package,
                'invested': vip_package.price,
                'last_claim_time': timezone.now(),
            }
        )

        if not created:
            user_vip.vip = vip_package
            user_vip.invested = vip_package.price
            user_vip.last_claim_time = timezone.now()
            user_vip.save()

        # Deduct balance
        Transaction.objects.create(customer=user, type='withdraw', amount=vip_package.price)

    except Exception as e:
        return Response({'error': f'Purchase failed: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({'message': f'Successfully upgraded to {vip_package.title}'}, status=status.HTTP_200_OK)







@api_view(['GET'])
@permission_classes([IsAuthenticated])
def task_api(request):
    user_vip = UserVIP.objects.filter(user=request.user).first()
    min_vip = user_vip.vip_level.id if user_vip else 0
    tasks = Task.objects.filter(min_vip_level__lte=min_vip)
    serializer = TaskSerializer(tasks, many=True)
    return Response(serializer.data)


# --------------------------
# CHAT
# --------------------------

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_message_api(request):
    content = request.data.get('content')
    if not content:
        return Response({'error': 'Message empty'}, status=status.HTTP_400_BAD_REQUEST)
    msg = Message.objects.create(sender=request.user.username, content=content, timestamp=timezone.now())
    serializer = MessageSerializer(msg)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_api(request):
    messages = Message.objects.filter(parent__isnull=True).prefetch_related('replies')
    serializer = MessageSerializer(messages, many=True)
    return Response(serializer.data)


# --------------------------
# ORDERS / INVEST
# --------------------------

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_orders_api(request):
    orders = Order.objects.filter(user=request.user)
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def process_order_api(request):
    payment_method = request.data.get('payment_method')
    total_amount = request.data.get('total_amount', 100)
    if not payment_method:
        return Response({'error': 'Missing payment method'}, status=status.HTTP_400_BAD_REQUEST)

    order = Order.objects.create(user=request.user, payment_method=payment_method, total_amount=total_amount)
    serializer = OrderSerializer(order)
    return Response(serializer.data)




from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from .models import  Profile, Commission
import json





@api_view(['GET'])
@permission_classes([IsAuthenticated])
def commissions_api(request):
    try:
        user = request.user
        print(f"Fetching commissions for user: {user}")
        commissions = Commission.objects.filter(user=user)
        serializer = CommissionSerializer(commissions, many=True)
        return Response(serializer.data)
    except Exception as e:
        print("Error in commissions_api:", e)
        return Response({'error': str(e)}, status=500)


# ----- UPDATE ACCOUNT NUMBER -----
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_account_number(request):
    try:
        new_account = request.data.get('newAccountNumber')
        if not new_account:
            return JsonResponse({'error': 'Missing account number'}, status=400)

        profile = Profile.objects.get(user=request.user)
        profile.account_number = new_account
        profile.save()
        return JsonResponse({'message': 'Account number updated successfully', 'account_number': profile.account_number})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
    

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def set_withdraw_password_api(request):
    try:
        password = request.data.get('withdraw_password')
        if not password:
            return Response({'error': 'withdraw_password is required'}, status=400)

        # Use the correct related_name
        profile = request.user.profile  # match your related_name in UserProfile
        profile.withdraw_password = password
        profile.save()

        return Response({'success': True})
    except AttributeError:
        return Response({'error': "'User' object has no attribute 'profile'"}, status=500)





from datetime import timedelta
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import UserVIP, Transaction,InviteReward

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_vip_income_api(request):
    user = request.user
    try:
        user_vip = UserVIP.objects.select_related('vip').get(user=user)
    except UserVIP.DoesNotExist:
        return Response({'error': 'No active VIP found.'}, status=status.HTTP_404_NOT_FOUND)

    # Check if user can claim
    if user_vip.last_claim_time and timezone.now() < user_vip.last_claim_time + timedelta(hours=24):
        remaining = (user_vip.last_claim_time + timedelta(hours=24)) - timezone.now()
        hours = remaining.seconds // 3600
        minutes = (remaining.seconds % 3600) // 60
        return Response(
            {'error': f'You can claim again in {hours}h {minutes}m'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Add daily earning to balance
    daily_earning = user_vip.vip.dailyEarnings  # from your VIP model
    Transaction.objects.create(
        customer=user,
        type='deposit',
        amount=daily_earning,
        description=f'Daily income from {user_vip.vip.name}'
    )

    # Update last claim time
    user_vip.last_claim_time = timezone.now()
    user_vip.save()

    return Response({'message': f'Successfully claimed Br {daily_earning} income.'})

















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






@api_view(['POST'])
@permission_classes([IsAuthenticated])
def recharge_api(request):
    try:
        # 1️⃣ Validate amount
        amount = request.data.get("amount")
        if not amount:
            return Response({"error": "amount is required"}, status=400)

        user = request.user

        # 2️⃣ Check profile exists
        try:
            profile = user.profile
        except Exception as e:
            return Response({"error": f"profile missing: {str(e)}"}, status=500)

        # 3️⃣ Create recharge
        try:
            recharge = Recharge.objects.create(
                user=user,
                amount=amount,
                status="success"
            )
        except Exception as e:
            return Response({"error": f"recharge create failed: {str(e)}"}, status=500)

        # 4️⃣ Check inviter exists
        inviter = profile.invited_by
        if not inviter:
            return Response({
                "success": True,
                "message": "Recharge successful (no inviter)"
            })

        # 5️⃣ Check if reward already exists
        try:
            if InviteReward.objects.filter(invited_user=user).exists():
                return Response({
                    "success": True,
                    "message": "Recharge successful (reward already given)"
                })
        except Exception as e:
            return Response({"error": f"reward check failed: {str(e)}"}, status=500)

        # 6️⃣ Create reward
        reward_amount = 12.5
        try:
            InviteReward.objects.create(
                profile=inviter,
                invited_user=user,
                reward_amount=reward_amount
            )
        except Exception as e:
            return Response({"error": f"reward creation failed: {str(e)}"}, status=500)

        # 7️⃣ Update inviter balance
        try:
            inviter.balance += reward_amount
            inviter.save()
        except Exception as e:
            return Response({"error": f"balance update failed: {str(e)}"}, status=500)

        return Response({
            "success": True,
            "message": "Recharge successful (reward given)",
            "reward_amount": reward_amount
        })

    except Exception as e:
        return Response({"error": f"unexpected error: {str(e)}"}, status=500)









from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth.models import User
from .models import Profile

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def use_invite_code(request):
    """
    Allows the current user to set an inviter using an invite code.
    """
    invite_code = request.data.get('invite_code')

    if not invite_code:
        return Response({'error': 'invite_code is required'}, status=400)

    try:
        inviter_profile = Profile.objects.get(invite_code=invite_code)
    except Profile.DoesNotExist:
        return Response({'error': 'Invalid invite code'}, status=404)

    # Prevent self-invitation
    if inviter_profile.user == request.user:
        return Response({'error': "You can't use your own invite code"}, status=400)

    profile = request.user.profile
    if profile.inviter:
        return Response({'error': 'You already have an inviter'}, status=400)

    profile.inviter = inviter_profile.user
    profile.save()

    return Response({'success': f'Invite code applied! You were invited by {inviter_profile.user.username}'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_invite_code(request):
    """
    Returns the invite code for the current user.
    """
    profile = request.user.profile
    return Response({'invite_code': profile.invite_code})


from .models import GiftCode, GiftRedemption, Profile

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def redeem_gift_code(request):
    """
    Redeem the single gift code for a user.
    """
    code_text = request.data.get('code', '').strip()
    if not code_text:
        return Response({"success": False, "message": "Code is required."}, status=400)

    try:
        gift = GiftCode.objects.get(code=code_text)
    except GiftCode.DoesNotExist:
        return Response({"success": False, "message": "Invalid code."}, status=404)

    # Check if user has already redeemed
    if GiftRedemption.objects.filter(code=gift, user=request.user).exists():
        return Response({"success": False, "message": "You have already redeemed this code."}, status=400)

    # Check if total pool has enough left
    if gift.remaining_amount() < gift.per_user_amount:
        return Response({"success": False, "message": "Gift pool exhausted."}, status=400)

    # Redeem
    GiftRedemption.objects.create(
        code=gift,
        user=request.user,
        amount=gift.per_user_amount
    )

    # Add to user's balance
    profile = request.user.profile
    profile.balance += gift.per_user_amount
    profile.available_balance += gift.per_user_amount
    profile.save()

    return Response({"success": True, "amount": float(gift.per_user_amount)})


from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import GiftCode
from .serializers import GiftCodeSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_gift_code_info(request):
    """
    Returns gift code info for Flutter: remaining amount, per user amount, redeemed status.
    """
    try:
        gift = GiftCode.objects.first()  # Only one code for all users
        serializer = GiftCodeSerializer(gift, context={'request': request})
        return Response(serializer.data)
    except GiftCode.DoesNotExist:
        return Response({"message": "No gift code available."}, status=404)
