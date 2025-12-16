

from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Profile, Balance, Transaction, VIP, UserVIP, Task, GiftCode, GiftRedemption,
    Message, Order, Recharge, CustomerMessage, Commission, InviteReward
)

User = get_user_model()


# -----------------------
# USER SERIALIZER
# -----------------------
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
from rest_framework import serializers
from .models import MainProject

class MainProjectSerializer(serializers.ModelSerializer):
    remaining_units = serializers.ReadOnlyField()
    is_available = serializers.ReadOnlyField()
    
    class Meta:
        model = MainProject
        fields = [
            'id',
            'title',
            'description',
            'short_description',
            'price',
            'daily_income',
            'cycle_days',
            'total_income',
            'total_units',
            'available_units',
            'remaining_units',
            'status',
            'is_featured',
            'is_active',
            'is_available',
            'image_url',
            'thumbnail_url',
            'slug',
            'created_at',
        ]

# -----------------------
# PROFILE SERIALIZER
# -----------------------
class ProfileSerializer(serializers.ModelSerializer):
    username = serializers.SerializerMethodField()
    balance = serializers.SerializerMethodField()
    available_balance = serializers.SerializerMethodField()
    frozen_balance = serializers.SerializerMethodField()
    vip = serializers.SerializerMethodField()
    invite_code = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = [
            'username', 'balance', 'available_balance', 'frozen_balance',
            'vip', 'invite_code'
        ]

    def get_username(self, obj):
        return getattr(obj.user, 'username', 'Unknown')

    def _get_balance_obj(self, obj):
        return Balance.objects.filter(customer=obj.user).first()

    def get_balance(self, obj):
        balance = self._get_balance_obj(obj)
        return float(balance.amount) if balance else 0.0

    def get_available_balance(self, obj):
        balance = self._get_balance_obj(obj)
        return float(balance.amount) if balance else 0.0

    def get_frozen_balance(self, obj):
        balance = self._get_balance_obj(obj)
        return float(getattr(balance, 'frozen_balance', 0.0))

    def get_vip(self, obj):
        return getattr(obj, 'vip_level', 'VIP0')

    def get_invite_code(self, obj):
        return getattr(obj, 'invite_code', '')


# -----------------------
# TRANSACTION SERIALIZER
# -----------------------
class TransactionSerializer(serializers.ModelSerializer):
   
    
    class Meta:
        model = Transaction
        fields = ['id', 'type', 'amount', 'date', 'status', 'bank', 'account_number', 'phone_number']


# -----------------------
# VIP SERIALIZER
# -----------------------
class VIPSerializer(serializers.ModelSerializer):
    totalIncome = serializers.SerializerMethodField()
    dailyEarnings = serializers.DecimalField(source='daily_income', max_digits=10, decimal_places=2)
    validityDays = serializers.IntegerField(source='income_days')

    class Meta:
        model = VIP
        fields = [
            'id', 'title', 'description', 'image_url', 'price',
            'dailyEarnings', 'totalIncome', 'validityDays', 'upgrade'
        ]

    def get_totalIncome(self, obj):
        return float(obj.daily_income) * obj.income_days


# -----------------------
# USER VIP SERIALIZER
# -----------------------
class UserVIPSerializer(serializers.ModelSerializer):
    vip_level = VIPSerializer(read_only=True)

    class Meta:
        model = UserVIP
        fields = ['vip_level', 'invested', 'last_claim_time']


# -----------------------
# TASK SERIALIZER
# -----------------------
class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'name', 'description', 'price', 'min_vip_level']


# -----------------------
# MESSAGE SERIALIZER
# -----------------------
class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'sender', 'content', 'timestamp', 'parent']


# -----------------------
# ORDER SERIALIZER
# -----------------------
class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ['id', 'total_amount', 'payment_method', 'is_paid', 'created_at']


# -----------------------
# RECHARGE SERIALIZER
# -----------------------
class RechargeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recharge
        fields = ['id', 'user', 'amount', 'status', 'transaction_id', 'created_at']


# -----------------------
# CUSTOMER MESSAGE SERIALIZER
# -----------------------
class CustomerMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerMessage
        fields = ['id', 'name', 'phone', 'message', 'created_at']


# -----------------------
# COMMISSION SERIALIZER
# -----------------------
class CommissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Commission
        fields = ['id', 'amount']


# -----------------------
#
from rest_framework import serializers
from .models import GiftCode, GiftRedemption

class GiftCodeSerializer(serializers.ModelSerializer):
    remaining_amount = serializers.SerializerMethodField()
    already_redeemed = serializers.SerializerMethodField()

    class Meta:
        model = GiftCode
        fields = ['code', 'per_user_amount', 'remaining_amount', 'already_redeemed']

    def get_remaining_amount(self, obj):
        return float(obj.remaining_amount())

    def get_already_redeemed(self, obj):
        user = self.context.get('request').user
        if not user.is_authenticated:
            return False
        return GiftRedemption.objects.filter(code=obj, user=user).exists()

# -----------------------
# INVITE REWARD SERIALIZER
# -----------------------
class InviteRewardSerializer(serializers.ModelSerializer):
    class Meta:
        model = InviteReward
        fields = ['id', 'profile', 'invited_user', 'reward_amount', 'date']
