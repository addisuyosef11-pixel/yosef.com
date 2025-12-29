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





# --------------------------
# ORDERS / INVEST
# --------------------------







@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_message_api(request):
    try:
        # Try to get content from request data (form data or JSON)
        content = request.data.get('content')
        
        # If not found in data, try to parse body
        if not content and request.body:
            try:
                body_data = json.loads(request.body)
                content = body_data.get('content') or body_data.get('message') or body_data.get('text')
            except:
                pass
        
        if not content:
            return Response({
                'error': 'Message content is required',
                'received_data': str(request.data)
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get sender from authenticated user
        sender = request.user.username
        
        # Create message
        msg = Message.objects.create(
            sender=sender, 
            content=content, 
            timestamp=timezone.now()
        )
        
        # Return the created message
        serializer = MessageSerializer(msg)
        return Response({
            'success': True,
            'message': 'Message sent successfully',
            'message_id': msg.id,
            'data': serializer.data
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'error': f'Error saving message: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_api(request):
    try:
        # Get all messages (you might want to filter or paginate)
        messages = Message.objects.all().order_by('timestamp')
        
        # If you want to get messages for the current user only:
        # messages = Message.objects.filter(sender=request.user.username).order_by('timestamp')
        
        serializer = MessageSerializer(messages, many=True)
        return Response({
            'success': True,
            'count': messages.count(),
            'messages': serializer.data
        })
        
    except Exception as e:
        return Response({
            'error': f'Error fetching messages: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Add a view to delete messages if needed
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_message_api(request, message_id):
    try:
        # Find the message
        message = Message.objects.get(id=message_id)
        
        # Check if the user owns the message (optional security)
        # if message.sender != request.user.username:
        #     return Response({
        #         'error': 'You can only delete your own messages'
        #     }, status=status.HTTP_403_FORBIDDEN)
        
        message.delete()
        return Response({
            'success': True,
            'message': 'Message deleted successfully'
        })
        
    except Message.DoesNotExist:
        return Response({
            'error': 'Message not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'error': f'Error deleting message: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)













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

# 







# cat/api_views.py
from django.utils import timezone
from datetime import timedelta
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from cat.models import UserVIP, Profile, Transaction

# Function for URL WITHOUT vip_id parameter (gets it from request body)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_vip_income(request):
    """Claim income from a VIP investment - vip_id from request body"""
    
    # Get vip_id from request body (JSON)
    vip_id = request.data.get('vip_id')
    
    if not vip_id:
        return Response({
            'success': False,
            'message': 'vip_id is required in request body',
        }, status=400)
    
    try:
        vip_id = int(vip_id)
        user_vip = UserVIP.objects.get(user=request.user, vip_id=vip_id)
        
        if not user_vip.can_claim():
            return Response({
                'success': False,
                'message': 'You can only claim once every 24 hours',
                'next_claim_time': (user_vip.last_claim_time + timedelta(hours=24)).isoformat() if user_vip.last_claim_time else None,
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
            'next_claim_time': (user_vip.last_claim_time + timedelta(hours=24)).isoformat(),
        })
        
    except UserVIP.DoesNotExist:
        return Response({
            'success': False,
            'message': 'VIP investment not found',
        }, status=404)
    except ValueError:
        return Response({
            'success': False,
            'message': 'vip_id must be a valid integer',
        }, status=400)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error claiming income: {str(e)}',
        }, status=500)


# Function for URL WITH vip_id parameter (gets it from URL)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_vip_income_api(request, vip_id):
    """Claim income from a VIP investment - vip_id from URL"""
    
    try:
        user_vip = UserVIP.objects.get(user=request.user, vip_id=vip_id)
        
        if not user_vip.can_claim():
            return Response({
                'success': False,
                'message': 'You can only claim once every 24 hours',
                'next_claim_time': (user_vip.last_claim_time + timedelta(hours=24)).isoformat() if user_vip.last_claim_time else None,
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
            'next_claim_time': (user_vip.last_claim_time + timedelta(hours=24)).isoformat(),
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


from .models import MainProject ,UserMainProject



@api_view(['POST'])
@permission_classes([IsAuthenticated])
def invest_in_project(request):
    """
    Invest in a main project (authenticated users only)
    """
    try:
        # Parse request data
        data = request.data
        
        project_id = data.get('project_id')
        units = data.get('units', 1)
        
        # Validate inputs
        if not project_id:
            return Response({
                'success': False,
                'message': 'project_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            units = int(units)
        except (ValueError, TypeError):
            return Response({
                'success': False,
                'message': 'Units must be a valid number'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if units < 1:
            return Response({
                'success': False,
                'message': 'Units must be at least 1'
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
        
        # Check available units
        if units > project.available_units:
            return Response({
                'success': False,
                'message': f'Only {project.available_units} units available. Requested: {units}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Calculate total amount
        try:
            total_amount = project.price * Decimal(units)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Error calculating amount: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check user profile and balance
        try:
            user_profile = request.user.profile
        except AttributeError:
            return Response({
                'success': False,
                'message': 'User profile not found'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user already invested in this project
        existing_investment = UserMainProject.objects.filter(
            user=request.user,
            main_project=project
        ).first()
        
        if existing_investment:
            return Response({
                'success': False,
                'message': f'You already have an investment in this project. You own {existing_investment.units} units.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check user balance
        if not hasattr(user_profile, 'balance') or user_profile.balance is None:
            return Response({
                'success': False,
                'message': 'User balance not found'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if Decimal(str(user_profile.balance)) < total_amount:
            return Response({
                'success': False,
                'message': f'Insufficient balance. Required: {total_amount:.2f} Br, Available: {user_profile.balance:.2f} Br'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Process investment
        try:
            with transaction.atomic():
                # Calculate incomes
                daily_income = project.daily_income * Decimal(units)
                total_income = project.total_income * Decimal(units)
                
                # Deduct from user balance
                user_profile.balance -= total_amount
                user_profile.save()
                
                # Update project available units
                project.available_units -= units
                project.save()
                
                # Create UserMainProject record
                user_main_project = UserMainProject.objects.create(
                    user=request.user,
                    main_project=project,
                    units=units,
                    invested_amount=total_amount,
                    status='active'
                )
                
                # Refresh the instance to get auto-added fields
                user_main_project.refresh_from_db()
                
                # Test the can_claim method to ensure no errors
                try:
                    can_claim = user_main_project.can_claim()
                    print(f"DEBUG: can_claim() result: {can_claim}")
                except Exception as method_error:
                    print(f"DEBUG: Error in can_claim(): {str(method_error)}")
                
                # Format dates safely
                purchase_date_str = None
                if user_main_project.purchase_date:
                    purchase_date_str = user_main_project.purchase_date.isoformat()
                
                last_claim_time_str = None
                if user_main_project.last_claim_time:
                    last_claim_time_str = user_main_project.last_claim_time.isoformat()
                
                # Prepare response data
                response_data = {
                    'success': True,
                    'message': f'Successfully invested in {project.title}',
                    'investment_id': user_main_project.id,
                    'project_title': project.title,
                    'units': units,
                    'total_amount': float(total_amount),
                    'daily_income': float(daily_income),
                    'total_income': float(total_income),
                    'cycle_days': project.cycle_days,
                    'purchase_date': purchase_date_str,
                    'last_claim_time': last_claim_time_str,
                    'remaining_units': project.available_units,
                    'new_balance': float(user_profile.balance)
                }
                
                return Response(response_data, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            import traceback
            error_details = traceback.format_exc()
            print(f"Transaction error details:\n{error_details}")
            
            return Response({
                'success': False,
                'message': f'Transaction failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"General error details:\n{error_details}")
        
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
def claim_vip_income(request):
    """Claim income from a VIP investment"""
    try:
        # Get vip_id from request data
        vip_id = request.data.get('vip_id')
        
        # If request.data is empty, try to parse body directly
        if vip_id is None and request.body:
            try:
                data = json.loads(request.body)
                vip_id = data.get('vip_id')
            except:
                pass
        
        if not vip_id:
            return Response({
                'success': False,
                'message': 'VIP ID is required. Please provide vip_id in the request body.',
            }, status=400)
        
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
def claim_main_project_income(request):
    """Claim income from a Main Project investment"""
    try:
        # Get project_id from request data
        project_id = request.data.get('project_id')
        
        # If request.data is empty, try to parse body directly
        if project_id is None and request.body:
            try:
                data = json.loads(request.body)
                project_id = data.get('project_id')
            except:
                pass
        
        if not project_id:
            return Response({
                'success': False,
                'message': 'Project ID is required. Please provide project_id in the request body.',
            }, status=400)
        
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




from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import (
    IsAuthenticated,
    IsAdminUser,
    AllowAny
)
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from django.db.models import Q
from django.views.decorators.csrf import csrf_exempt

from .models import Video
from .serializers import VideoSerializer, VideoUploadSerializer


# ==========================
# PUBLIC VIDEO ENDPOINTS
# ==========================

@api_view(['GET'])
@permission_classes([AllowAny])
def video_list(request):
    queryset = Video.objects.filter(
        is_published=True,
        status='approved'
    )

    featured = request.query_params.get('featured')
    category = request.query_params.get('category')
    search = request.query_params.get('search')

    if featured == 'true':
        queryset = queryset.filter(is_featured=True)

    if category:
        queryset = queryset.filter(category=category)

    if search:
        queryset = queryset.filter(
            Q(title__icontains=search) |
            Q(description__icontains=search)
        )

    serializer = VideoSerializer(
        queryset,
        many=True,
        context={'request': request}
    )
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def video_detail(request, pk):
    try:
        video = Video.objects.get(
            pk=pk,
            is_published=True,
            status='approved'
        )
    except Video.DoesNotExist:
        return Response(
            {'detail': 'Video not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    serializer = VideoSerializer(video, context={'request': request})
    return Response(serializer.data)


# ==========================
# VIDEO INTERACTIONS
# ==========================

@api_view(['POST'])
@permission_classes([AllowAny])
def increment_views(request, pk):
    video = Video.objects.get(pk=pk)
    video.views += 1
    video.save()
    return Response({'views': video.views})


@api_view(['POST'])
@permission_classes([AllowAny])
def like_video(request, pk):
    video = Video.objects.get(pk=pk)
    video.likes += 1
    video.save()
    return Response({'likes': video.likes})


@api_view(['POST'])
@permission_classes([AllowAny])
def dislike_video(request, pk):
    video = Video.objects.get(pk=pk)
    video.dislikes += 1
    video.save()
    return Response({'dislikes': video.dislikes})


# ==========================
# UPLOAD VIDEO
# ==========================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@csrf_exempt
def upload_video(request):
    parser_classes = (MultiPartParser, FormParser)

    serializer = VideoUploadSerializer(
        data=request.data,
        context={'request': request}
    )

    if serializer.is_valid():
        video_file = serializer.validated_data['video_file']

        video = serializer.save(
            uploaded_by=request.user,
            duration=0,
            file_size=video_file.size,
            status='approved' if request.user.is_staff else 'pending',
            is_published=request.user.is_staff
        )

        return Response(
            VideoSerializer(video, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ==========================
# ADMIN VIDEO ACTIONS
# ==========================

@api_view(['POST'])
@permission_classes([IsAdminUser])
def approve_video(request, pk):
    video = Video.objects.get(pk=pk)
    video.status = 'approved'
    video.is_published = True
    video.approved_by = request.user
    video.save()
    return Response({'message': 'Video approved'})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def reject_video(request, pk):
    video = Video.objects.get(pk=pk)
    video.status = 'rejected'
    video.is_published = False
    video.save()
    return Response({'message': 'Video rejected'})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def feature_video(request, pk):
    video = Video.objects.get(pk=pk)
    video.is_featured = True
    video.save()
    return Response({'message': 'Video featured'})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def unfeature_video(request, pk):
    video = Video.objects.get(pk=pk)
    video.is_featured = False
    video.save()
    return Response({'message': 'Video unfeatured'})


# ==========================
# CATEGORIES
# ==========================

@api_view(['GET'])
@permission_classes([AllowAny])
def video_categories(request):
    categories = Video.objects.values_list(
        'category',
        flat=True
    ).distinct()
    return Response({'categories': list(categories)})












# Add these imports at the top if not already there
from django.db.models import Sum, Count, Q
from decimal import Decimal
import json

# Add these views to your api_views.py file:

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_team_members(request):
    """Get user's team members (direct referrals)"""
    try:
        user = request.user
        user_profile = user.profile
        
        # Get all users directly referred by this user
        direct_referrals = User.objects.filter(
            profile__inviter=user
        ).select_related('profile')
        
        team_members = []
        for referral in direct_referrals:
            # Get referral's profile
            referral_profile = referral.profile
            
            # Calculate total investment for this referral
            total_investment = UserMainProject.objects.filter(
                user=referral,
                status='active'
            ).aggregate(
                total=Sum('invested_amount')
            )['total'] or Decimal('0')
            
            # Get user's VIP if any
            vip_level = 'No VIP'
            try:
                user_vip = UserVIP.objects.get(user=referral)
                vip_level = f"VIP {user_vip.vip.upgrade}"
            except UserVIP.DoesNotExist:
                pass
            
            # Calculate commission earned from this referral (if Commission model exists)
            commission_earned = Decimal('0')
            try:
                from .models import Commission
                commission_earned = Commission.objects.filter(
                    user=user,
                    related_user=referral
                ).aggregate(
                    total=Sum('amount')
                )['total'] or Decimal('0')
            except (ImportError, AttributeError):
                pass
            
            team_members.append({
                'id': referral.id,
                'name': referral.get_full_name() or referral.username,
                'username': referral.username,
                'phone': referral_profile.phone or '',
                'email': referral.email or '',
                'level': vip_level,
                'joined': referral.date_joined.strftime('%Y-%m-%d'),
                'status': 'active' if referral.is_active else 'inactive',
                'investment': float(total_investment),
                'commission_earned': float(commission_earned),
                'avatar': referral_profile.avatar.url if referral_profile.avatar else None,
            })
        
        # Get team stats
        total_members = direct_referrals.count()
        active_members = direct_referrals.filter(is_active=True).count()
        
        total_investment = UserMainProject.objects.filter(
            user__profile__inviter=user,
            status='active'
        ).aggregate(
            total=Sum('invested_amount')
        )['total'] or Decimal('0')
        
        # Calculate total commission earned
        total_commission = Decimal('0')
        try:
            from .models import Commission
            total_commission = Commission.objects.filter(
                user=user
            ).aggregate(
                total=Sum('amount')
            )['total'] or Decimal('0')
        except (ImportError, AttributeError):
            pass
        
        team_stats = {
            'total_members': total_members,
            'active_members': active_members,
            'total_investment': float(total_investment),
            'commission_earned': float(total_commission),
            'invite_code': user_profile.invite_code,
            'referral_link': f"https://yourapp.com/register?ref={user_profile.invite_code}",
        }
        
        return Response({
            'success': True,
            'team_members': team_members,
            'team_stats': team_stats,
        })
        
    except Exception as e:
        import traceback
        print(f"Error in get_team_members: {str(e)}")
        print(traceback.format_exc())
        return Response({
            'success': False,
            'message': f'Error loading team data: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_invitation(request):
    """Send invitation to potential team member"""
    try:
        data = request.data
        phone = data.get('phone')
        message = data.get('message', 'Join me on this amazing platform and start earning!')
        
        if not phone:
            return Response({
                'success': False,
                'message': 'Phone number is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get user's invite code
        invite_code = request.user.profile.invite_code
        referral_link = f"https://yourapp.com/register?ref={invite_code}"
        
        # Full message with referral link
        full_message = f"{message}\n\nUse my referral link to register: {referral_link}\n\nMy invite code: {invite_code}"
        
        # Log the invitation (in production, integrate with SMS service)
        print(f"[INVITATION] To: {phone}")
        print(f"[INVITATION] Message: {full_message}")
        
        # Create a record of the invitation (optional)
        # You could create an Invitation model to track these
        
        return Response({
            'success': True,
            'message': 'Invitation sent successfully!',
            'referral_link': referral_link,
            'invite_code': invite_code,
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error sending invitation: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_commission_history(request):
    """Get user's commission history"""
    try:
        # Try to get commissions from Commission model
        try:
            from .models import Commission
            commissions = Commission.objects.filter(
                user=request.user
            ).order_by('-created_at')[:50]
            
            commission_list = []
            for commission in commissions:
                commission_list.append({
                    'id': commission.id,
                    'amount': float(commission.amount),
                    'level': getattr(commission, 'level', 1),
                    'description': getattr(commission, 'description', f"Level {getattr(commission, 'level', 1)} Commission"),
                    'date': commission.created_at.strftime('%Y-%m-%d %H:%M'),
                    'from_user': getattr(commission.related_user, 'username', 'System') if hasattr(commission, 'related_user') else 'System',
                })
            
            total_commission = sum(float(c.amount) for c in commissions)
            
        except (ImportError, AttributeError):
            # If Commission model doesn't exist, return empty list
            commission_list = []
            total_commission = 0
        
        return Response({
            'success': True,
            'commissions': commission_list,
            'total_commission': total_commission,
            'commission_count': len(commission_list),
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error loading commission history: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_team_stats(request):
    """Get detailed team statistics"""
    try:
        user = request.user
        
        # Direct referrals (Level 1)
        level1_referrals = User.objects.filter(profile__inviter=user)
        
        # Level 2 referrals (referrals of referrals)
        level2_referrals = User.objects.filter(
            profile__inviter__in=level1_referrals
        )
        
        # Level 3 referrals
        level3_referrals = User.objects.filter(
            profile__inviter__in=level2_referrals
        )
        
        # Calculate investments by level
        def get_investment_for_users(users):
            return UserMainProject.objects.filter(
                user__in=users,
                status='active'
            ).aggregate(total=Sum('invested_amount'))['total'] or Decimal('0')
        
        level1_investment = get_investment_for_users(level1_referrals)
        level2_investment = get_investment_for_users(level2_referrals)
        level3_investment = get_investment_for_users(level3_referrals)
        
        # Calculate commissions by level (if Commission model exists)
        def get_commission_for_level(level):
            try:
                from .models import Commission
                return Commission.objects.filter(
                    user=user,
                    level=level
                ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
            except (ImportError, AttributeError):
                return Decimal('0')
        
        level1_commission = get_commission_for_level(1)
        level2_commission = get_commission_for_level(2)
        level3_commission = get_commission_for_level(3)
        
        stats = {
            'level1': {
                'members': level1_referrals.count(),
                'investment': float(level1_investment),
                'commission': float(level1_commission),
            },
            'level2': {
                'members': level2_referrals.count(),
                'investment': float(level2_investment),
                'commission': float(level2_commission),
            },
            'level3': {
                'members': level3_referrals.count(),
                'investment': float(level3_investment),
                'commission': float(level3_commission),
            },
            'total': {
                'members': level1_referrals.count() + level2_referrals.count() + level3_referrals.count(),
                'investment': float(level1_investment + level2_investment + level3_investment),
                'commission': float(level1_commission + level2_commission + level3_commission),
            }
        }
        
        return Response({
            'success': True,
            'stats': stats,
            'invite_code': user.profile.invite_code,
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error loading team stats: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def share_referral_link(request):
    """Generate shareable referral content"""
    try:
        user = request.user
        user_profile = user.profile
        
        invite_code = user_profile.invite_code
        referral_link = f"https://yourapp.com/register?ref={invite_code}"
        
        share_content = {
            'text': f"Join me on this amazing platform! Use my referral code: {invite_code}\n{referral_link}",
            'link': referral_link,
            'code': invite_code,
            'qr_code_url': f"https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={referral_link}",
        }
        
        return Response({
            'success': True,
            'share_content': share_content,
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error generating share content: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)







