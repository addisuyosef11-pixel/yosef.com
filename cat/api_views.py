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


# In api_views.py
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
import json

User = get_user_model()

@csrf_exempt
def signup_api(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    try:
        # Parse JSON data
        data = json.loads(request.body)
        
        # Extract data with defaults
        username = data.get('username')
        email = data.get('email')
        phone = data.get('phone')
        password = data.get('password')
        refcode = data.get('refcode')
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        
        # Debug print
        print(f"Signup attempt: username={username}, email={email}, phone={phone}")
        
        # Validate required fields
        if not username:
            return JsonResponse({'error': 'Username is required'}, status=400)
        if not password:
            return JsonResponse({'error': 'Password is required'}, status=400)
        
        # Check if user already exists
        if User.objects.filter(username=username).exists():
            return JsonResponse({'error': 'Username already exists'}, status=400)
        if email and User.objects.filter(email=email).exists():
            return JsonResponse({'error': 'Email already registered'}, status=400)
        
        # ✅ FIXED: Create user without date_joined parameter
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name or '',
            last_name=last_name or '',
        )
        
        # Add optional fields
        if phone:
            user.phone = phone
        if refcode:
            user.refcode = refcode
        
        user.save()
        
        # Return success response
        return JsonResponse({
            'success': True,
            'message': 'User created successfully',
            'user_id': user.id,
            'username': user.username
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON format'}, status=400)
    except Exception as e:
        # Make sure to return a response for all exceptions
        print(f"Unexpected error in signup_api: {e}")
        return JsonResponse({'error': f'Server error: {str(e)}'}, status=500)
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
    """
    try:
        user = request.user
        transactions = Transaction.objects.filter(customer=user).order_by('-date')

        # Calculate total deposits and withdrawals
        total_deposit = transactions.filter(type='deposit').aggregate(total=Sum('amount'))['total'] or 0
        total_withdraw = transactions.filter(type='withdraw').aggregate(total=Sum('amount'))['total'] or 0

        # Calculate balances
        balance = float(total_deposit - total_withdraw)
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
def redeem_gift_code(request):
    """
    Redeem a gift code and add balance to user's account.
    """
    try:
        user = request.user
        code = request.data.get('gift_code', '').strip().upper()
        
        if not code:
            return Response(
                {"error": "Gift code is required."},
                status=400
            )
        
        # Validate gift code
        gift_code = _validate_gift_code(code, user)
        if isinstance(gift_code, Response):
            return gift_code  # Return error response
        
        # Calculate redemption amount
        redemption_amount = _calculate_redemption_amount(gift_code)
        
        # Process redemption
        redemption, transaction = _process_redemption(gift_code, user, redemption_amount)
        
        # Update user balance
        _update_user_balance(user, redemption_amount)
        
        logger.info(f"User {user.username} redeemed gift code {code} for {redemption_amount} Br")
        
        return Response({
            "success": True,
            "message": f"Successfully redeemed {redemption_amount:.2f} Br",
            "amount": redemption_amount,
            "balance": float(user.profile.balance) if hasattr(user, 'profile') else 0,
            "transaction_id": transaction.id,
            "redemption_id": redemption.id
        })
        
    except Exception as e:
        logger.exception(f"Error redeeming gift code for user {user.username}: {str(e)}")
        return Response(
            {"error": "Failed to redeem gift code. Please try again."},
            status=500
        )

def _validate_gift_code(code, user):
    """Validate gift code and return it or error response"""
    try:
        gift_code = GiftCode.objects.get(code=code)
    except GiftCode.DoesNotExist:
        return Response(
            {"error": "Invalid gift code."},
            status=400
        )
    
    # Check if user already redeemed this code
    if GiftRedemption.objects.filter(gift_code=gift_code, user=user).exists():
        return Response(
            {"error": "You have already redeemed this gift code."},
            status=400
        )
    
    # Check expiration
    if gift_code.expires_at and gift_code.expires_at < timezone.now():
        return Response(
            {"error": "This gift code has expired."},
            status=400
        )
    
    # Check if active
    if not gift_code.is_active:
        return Response(
            {"error": "This gift code is no longer active."},
            status=400
        )
    
    # Check remaining amount
    remaining_amount = gift_code.remaining_amount()
    if remaining_amount <= 0:
        return Response(
            {"error": "This gift code has no remaining balance."},
            status=400
        )
    
    # Check max redemptions
    if gift_code.max_redemptions and gift_code.redemptions.count() >= gift_code.max_redemptions:
        return Response(
            {"error": "This gift code has reached its redemption limit."},
            status=400
        )
    
    return gift_code

def _calculate_redemption_amount(gift_code):
    """Calculate the amount to redeem"""
    remaining_amount = gift_code.remaining_amount()
    redemption_amount = float(gift_code.per_user_amount)
    
    # If per_user_amount exceeds remaining, use remaining
    if redemption_amount > remaining_amount:
        redemption_amount = remaining_amount
    
    return redemption_amount

def _process_redemption(gift_code, user, amount):
    """Process the redemption and create records"""
    # Create redemption record
    redemption = GiftRedemption.objects.create(
        gift_code=gift_code,
        user=user,
        amount=amount,
        redeemed_at=timezone.now()
    )
    
    # Create transaction
    transaction = Transaction.objects.create(
        customer=user,
        amount=amount,
        type='deposit',
        description=f'Gift code redemption: {gift_code.code}',
        status='completed'
    )
    
    return redemption, transaction

def _update_user_balance(user, amount):
    """Update user's balance"""
    try:
        if hasattr(user, 'profile'):
            user.profile.balance += amount
            user.profile.save()
    except Exception as e:
        logger.error(f"Error updating user balance: {str(e)}")

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
        # Get data from request
        account_number = request.data.get('account_number')
        merchant_name = request.data.get('merchant_name', '')
        bank_type = request.data.get('bank_type', '')
        
        # Validate required field
        if not account_number:
            return JsonResponse({'error': 'Account number is required'}, status=400)
        
        # Update profile
        profile = Profile.objects.get(user=request.user)
        profile.account_number = account_number
        profile.merchant_name = merchant_name
        profile.bank_type = bank_type
        profile.save()
        
        return JsonResponse({
            'message': 'Account details updated successfully',
            'account_number': profile.account_number,
            'merchant_name': profile.merchant_name,
            'bank_type': profile.bank_type
        })
        
    except Profile.DoesNotExist:
        return JsonResponse({'error': 'Profile not found'}, status=404)
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
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recharge_history(request):
    """
    Get user's recharge/deposit history
    Endpoint: GET /api/recharge/history/
    """
    try:
        user = request.user
        logger.info(f"Fetching recharge history for user: {user.username}")
        
        # Get all deposit/recharge transactions for the user
        # Filter by type: 'deposit', 'recharge', 'payment', 'topup'
        deposits = Transaction.objects.filter(
            customer=user,
            type__in=['deposit', 'recharge', 'payment', 'topup']
        ).order_by('-date')  # Most recent first
        
        # Prepare response data
        history_data = []
        for deposit in deposits:
            # Safely format the transaction data using getattr
            transaction_data = {
                'id': getattr(deposit, 'id', None),
                'transaction_id': getattr(deposit, 'transaction_id', None) or f"TX{getattr(deposit, 'id', 0):08d}",
                'amount': float(getattr(deposit, 'amount', 0)),
                'type': getattr(deposit, 'type', 'deposit'),
                'description': getattr(deposit, 'description', 'Deposit'),  # Use getattr for safety
                'status': getattr(deposit, 'status', 'pending'),
                'payment_method': getattr(deposit, 'payment_method', ''),
                'reference_number': getattr(deposit, 'reference_number', ''),
            }
            
            # Safely handle date fields
            date = getattr(deposit, 'date', None)
            if date:
                transaction_data['created_at'] = date.isoformat()
            else:
                transaction_data['created_at'] = None
            
            completed_at = getattr(deposit, 'completed_at', None)
            if completed_at:
                transaction_data['completed_at'] = completed_at.isoformat()
            else:
                transaction_data['completed_at'] = None
            
            # Add payment proof URL if exists
            if hasattr(deposit, 'payment_proof') and deposit.payment_proof:
                try:
                    transaction_data['payment_proof_url'] = request.build_absolute_uri(deposit.payment_proof.url)
                except (AttributeError, ValueError):
                    transaction_data['payment_proof_url'] = None
            
            history_data.append(transaction_data)
        
        logger.info(f"Found {len(history_data)} recharge transactions for {user.username}")
        
        return Response({
            'success': True,
            'count': len(history_data),
            'transactions': history_data
        })
        
    except Exception as e:
        logger.error(f"Error in recharge_history for user {request.user.username}: {str(e)}")
        return Response(
            {"success": False, "error": "Failed to fetch recharge history", "details": str(e)},
            status=500
        )

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.utils import timezone
from django.shortcuts import get_object_or_404
from .models import MainProject, User
from .serializers import MainProjectSerializer
from decimal import Decimal
import json
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_main_projects(request):
    """
    Get all main projects (public access)
    """
    try:
        # Filter by query parameters
        featured = request.GET.get('featured', '').lower() == 'true'
        available = request.GET.get('available', '').lower() == 'true'
        
        queryset = MainProject.objects.filter(is_active=True)
        
        if featured:
            queryset = queryset.filter(is_featured=True)
        
        if available:
            queryset = queryset.filter(status='available', available_units__gt=0)
        
        # Order by featured first, then creation date
        queryset = queryset.order_by('-is_featured', '-created_at')
        
        serializer = MainProjectSerializer(queryset, many=True)
        return Response({
            'success': True,
            'count': len(serializer.data),
            'projects': serializer.data
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error fetching projects: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_featured_projects(request):
    """
    Get featured main projects (public access)
    """
    try:
        projects = MainProject.objects.filter(
            is_active=True,
            is_featured=True,
            status='available',
            available_units__gt=0
        ).order_by('-created_at')[:3]
        
        serializer = MainProjectSerializer(projects, many=True)
        return Response({
            'success': True,
            'count': len(serializer.data),
            'projects': serializer.data
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error fetching featured projects: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_available_projects(request):
    """
    Get available projects for investment (public access)
    """
    try:
        projects = MainProject.objects.filter(
            is_active=True,
            status='available',
            available_units__gt=0
        ).order_by('-is_featured', '-created_at')
        
        serializer = MainProjectSerializer(projects, many=True)
        return Response({
            'success': True,
            'count': len(serializer.data),
            'projects': serializer.data
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error fetching available projects: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_project_detail(request, slug):
    """
    Get specific project details by slug (public access)
    """
    try:
        project = get_object_or_404(MainProject, slug=slug, is_active=True)
        serializer = MainProjectSerializer(project)
        return Response({
            'success': True,
            'project': serializer.data
        })
        
    except MainProject.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Project not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error fetching project: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def invest_in_project(request):
    """
    Invest in a main project (authenticated users only)
    """
    try:
        # Parse request data
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            data = request.data
            
        project_id = data.get('project_id')
        units = data.get('units', 1)
        
        if not project_id:
            return Response({
                'success': False,
                'message': 'project_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get project
        try:
            project = MainProject.objects.get(
                id=project_id, 
                is_active=True,
                status='available'
            )
        except MainProject.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Project not found or not available for investment'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Validate units
        if units < 1:
            return Response({
                'success': False,
                'message': 'Units must be at least 1'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if units > project.available_units:
            return Response({
                'success': False,
                'message': f'Only {project.available_units} units available. Requested: {units}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Calculate total amount
        total_amount = project.price * units
        
        # Check user balance (adjust based on your UserProfile model)
        user_profile = request.user.profile
        
        if not hasattr(user_profile, 'balance'):
            return Response({
                'success': False,
                'message': 'User profile error: balance field not found'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if user_profile.balance < total_amount:
            return Response({
                'success': False,
                'message': f'Insufficient balance. Required: {total_amount} Br, Available: {user_profile.balance} Br'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Process investment
        try:
            with transaction.atomic():
                # Deduct from user balance
                user_profile.balance -= total_amount
                user_profile.save()
                
                # Update project available units
                project.available_units -= units
                project.save()
                
                # Create investment record
                investment = User.objects.create(
                    user=request.user,
                    project=project,
                    units=units,
                    total_amount=total_amount,
                    daily_income=project.daily_income * units,
                    total_income=project.total_income * units,
                    cycle_days=project.cycle_days,
                    status='active',
                    start_date=timezone.now(),
                    end_date=timezone.now() + timezone.timedelta(days=project.cycle_days)
                )
                
                # Prepare response data
                response_data = {
                    'success': True,
                    'message': f'Successfully invested in {project.title}',
                    'investment_id': investment.id,
                    'project_title': project.title,
                    'units': units,
                    'total_amount': float(total_amount),
                    'daily_income': float(investment.daily_income),
                    'total_income': float(investment.total_income),
                    'cycle_days': investment.cycle_days,
                    'start_date': investment.start_date,
                    'end_date': investment.end_date,
                    'remaining_units': project.available_units,
                    'new_balance': float(user_profile.balance)
                }
                
                return Response(response_data, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Transaction failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Investment error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_investments(request):
    """
    Get current user's investments in main projects
    """
    try:
        investments = User.objects.filter(
            user=request.user
        ).select_related('project').order_by('-created_at')
        
        investment_list = []
        for inv in investments:
            investment_list.append({
                'id': inv.id,
                'project_title': inv.project.title,
                'project_id': inv.project.id,
                'units': inv.units,
                'total_amount': float(inv.total_amount),
                'daily_income': float(inv.daily_income),
                'total_income': float(inv.total_income),
                'cycle_days': inv.cycle_days,
                'status': inv.status,
                'start_date': inv.start_date,
                'end_date': inv.end_date,
                'created_at': inv.created_at,
            })
        
        return Response({
            'success': True,
            'count': len(investment_list),
            'investments': investment_list
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error fetching investments: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    



from .models import PaymentMethod


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_payment_methods(request):
    methods = PaymentMethod.objects.filter(is_active=True)

    data = []
    for m in methods:
        data.append({
            "id": m.id,
            "name": m.name,
            "account": m.account_number,
            "account_name": m.account_name,
            "status": "available",
        })

    return JsonResponse({"methods": data}, status=200)



@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_investments(request):
    """Get user's purchased VIPs and Main Projects"""
    user = request.user
    
    # Get user's VIPs
    user_vips = UserVIP.objects.filter(user=user)
    vip_data = []
    for user_vip in user_vips:
        vip = user_vip.vip
        vip_data.append({
            'id': vip.id,
            'title': vip.title,
            'price': float(vip.price),
            'daily_income': float(vip.daily_income),
            'income_days': vip.income_days,
            'total_income': float(vip.daily_income * vip.income_days),
            'purchase_date': user_vip.purchase_date.strftime('%Y-%m-%d') if hasattr(user_vip, 'purchase_date') else timezone.now().strftime('%Y-%m-%d'),
            'last_claim_time': user_vip.last_claim_time.strftime('%Y-%m-%d %H:%M:%S') if user_vip.last_claim_time else None,
            'status': 'active' if user_vip.can_claim() else 'completed',
            'type': 'vip',
            'image_url': vip.image_url,
        })
    
    # Get user's Main Projects (if you have UserMainProject model)
    main_projects_data = []
    try:
        from .models import UserMainProject
        user_projects = UserMainProject.objects.filter(user=user)
        for user_project in user_projects:
            project = user_project.main_project
            main_projects_data.append({
                'id': project.id,
                'title': project.title,
                'price': float(project.price),
                'daily_income': float(project.daily_income),
                'cycle_days': project.cycle_days,
                'total_income': float(project.total_income),
                'purchase_date': user_project.purchase_date.strftime('%Y-%m-%d'),
                'units': user_project.units,
                'available_units': project.available_units,
                'last_claim_time': user_project.last_claim_time.strftime('%Y-%m-%d %H:%M:%S') if user_project.last_claim_time else None,
                'status': user_project.status,
                'type': 'main_project',
                'image_url': project.image_url,
            })
    except ImportError:
        # If UserMainProject doesn't exist yet, return empty list
        pass
    
    return Response({
        'vips': vip_data,
        'main_projects': main_projects_data,
        'total_count': len(vip_data) + len(main_projects_data),
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_vip_income(request, vip_id):
    """Claim income from a VIP investment"""
    try:
        user_vip = UserVIP.objects.get(user=request.user, vip_id=vip_id)
        
        if not user_vip.can_claim():
            return Response({
                'success': False,
                'message': 'You can only claim once every 24 hours',
                'next_claim': user_vip.last_claim_time + timedelta(hours=24) if user_vip.last_claim_time else None,
            }, status=400)
        
        # Calculate daily income
        daily_income = user_vip.vip.daily_income
        
        # Update user balance
        profile = Profile.objects.get(user=request.user)
        profile.balance += daily_income
        profile.available_balance += daily_income
        profile.save()
        
        # Update last claim time
        user_vip.last_claim_time = timezone.now()
        user_vip.save()
        
        # Record transaction
        Transaction.objects.create(
            customer=request.user,
            type='profit',
            amount=daily_income,
            status='success',
        )
        
        return Response({
            'success': True,
            'message': f'Successfully claimed {daily_income} Br',
            'amount': float(daily_income),
            'balance': float(profile.balance),
        })
        
    except UserVIP.DoesNotExist:
        return Response({
            'success': False,
            'message': 'VIP investment not found',
        }, status=404)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error claiming income: {str(e)}',
        }, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_main_project_income(request, project_id):
    """Claim income from a Main Project investment"""
    try:
        # This requires the UserMainProject model
        from .models import UserMainProject
        user_project = UserMainProject.objects.get(user=request.user, main_project_id=project_id)
        
        if user_project.status != 'active':
            return Response({
                'success': False,
                'message': 'This investment is not active',
            }, status=400)
        
        if not user_project.can_claim():
            return Response({
                'success': False,
                'message': 'You can only claim once every 24 hours',
                'next_claim': user_project.last_claim_time + timedelta(hours=24) if user_project.last_claim_time else None,
            }, status=400)
        
        # Calculate daily income (daily income * units)
        daily_income = user_project.main_project.daily_income * user_project.units
        
        # Update user balance
        profile = Profile.objects.get(user=request.user)
        profile.balance += daily_income
        profile.available_balance += daily_income
        profile.save()
        
        # Update last claim time
        user_project.last_claim_time = timezone.now()
        user_project.save()
        
        # Check if investment cycle is completed
        days_since_purchase = (timezone.now() - user_project.purchase_date).days
        if days_since_purchase >= user_project.main_project.cycle_days:
            user_project.status = 'completed'
            user_project.save()
        
        # Record transaction
        Transaction.objects.create(
            customer=request.user,
            type='profit',
            amount=daily_income,
            status='success',
        )
        
        return Response({
            'success': True,
            'message': f'Successfully claimed {daily_income} Br',
            'amount': float(daily_income),
            'balance': float(profile.balance),
        })
        
    except ImportError:
        return Response({
            'success': False,
            'message': 'Main project investment tracking not implemented',
        }, status=501)
    except UserMainProject.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Main project investment not found',
        }, status=404)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error claiming income: {str(e)}',
        }, status=500)
    









# views.py or api/views.py
from rest_framework import viewsets, status, generics, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q
from .models import Video
from .serializers import VideoSerializer, VideoUploadSerializer
from django.utils import timezone
import os

class VideoViewSet(viewsets.ModelViewSet):
    queryset = Video.objects.filter(is_published=True, status='approved')
    serializer_class = VideoSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'is_featured', 'uploaded_by']
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'views', 'likes']
    ordering = ['-created_at']
    
    def get_permissions(self):
        """
        Instantiates and returns the list of permissions that this view requires.
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy', 'upload']:
            permission_classes = [IsAdminUser]
        elif self.action in ['list', 'retrieve']:
            permission_classes = [AllowAny]
        else:
            permission_classes = [IsAuthenticated]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # For admin users, show all videos (including unpublished)
        if self.request.user.is_staff:
            queryset = Video.objects.all()
        
        # Filter by featured
        featured = self.request.query_params.get('featured')
        if featured == 'true':
            queryset = queryset.filter(is_featured=True)
        
        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        
        # Filter by search query
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search)
            )
        
        return queryset
    
    @action(detail=True, methods=['post'])
    def increment_views(self, request, pk=None):
        video = self.get_object()
        video.views += 1
        video.save()
        return Response({'message': 'View count incremented', 'views': video.views})
    
    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        video = self.get_object()
        video.likes += 1
        video.save()
        return Response({'message': 'Video liked', 'likes': video.likes})
    
    @action(detail=True, methods=['post'])
    def dislike(self, request, pk=None):
        video = self.get_object()
        video.dislikes += 1
        video.save()
        return Response({'message': 'Video disliked', 'dislikes': video.dislikes})
    
    @action(detail=False, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def upload(self, request):
        serializer = VideoUploadSerializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            # Calculate duration and file size (you might need to implement this)
            video_file = serializer.validated_data['video_file']
            
            # Create video instance
            video = serializer.save(
                uploaded_by=request.user,
                duration=0,  # You'll need to calculate this
                file_size=video_file.size,
                status='approved' if request.user.is_staff else 'pending'
            )
            
            # Return the created video
            response_serializer = VideoSerializer(video, context={'request': request})
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def categories(self, request):
        categories = Video.objects.values_list('category', flat=True).distinct()
        return Response({'categories': list(categories)})

class AdminVideoViewSet(viewsets.ModelViewSet):
    """
    Admin-only video management
    """
    queryset = Video.objects.all()
    serializer_class = VideoSerializer
    permission_classes = [IsAdminUser]
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        video = self.get_object()
        video.status = 'approved'
        video.approved_by = request.user
        video.is_published = True
        video.save()
        return Response({'message': 'Video approved'})
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        video = self.get_object()
        video.status = 'rejected'
        video.is_published = False
        video.save()
        return Response({'message': 'Video rejected'})
    
    @action(detail=True, methods=['post'])
    def feature(self, request, pk=None):
        video = self.get_object()
        video.is_featured = True
        video.save()
        return Response({'message': 'Video featured'})
    
    @action(detail=True, methods=['post'])
    def unfeature(self, request, pk=None):
        video = self.get_object()
        video.is_featured = False
        video.save()
        return Response({'message': 'Video unfeatured'})