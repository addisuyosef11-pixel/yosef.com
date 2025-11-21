


from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import random, string
from datetime import timedelta

# =======================
# USER & PROFILE MODELS
# =======================

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone = models.CharField(max_length=20, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    avatar = models.ImageField(upload_to="avatars/", default="avatars/default.png")
    vip_level = models.PositiveIntegerField(default=0)
    inviter = models.ForeignKey(User, null=True, blank=True, related_name="invited_users", on_delete=models.SET_NULL)
    coins = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    gold = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    account_number = models.CharField(max_length=50, blank=True, null=True)
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    available_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    frozen_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    invite_code = models.CharField(max_length=6, unique=True, blank=True, null=True)

    def save(self, *args, **kwargs):
        """Generate unique 6-digit invite code if missing"""
        if not self.invite_code:
            self.invite_code = self.generate_invite_code()
        super().save(*args, **kwargs)

    @staticmethod
    def generate_invite_code():
        while True:
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            if not Profile.objects.filter(invite_code=code).exists():
                return code

    def __str__(self):
        return self.user.username

# =======================
# OTP MODEL
# =======================

class OTP(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    otp_code = models.CharField(max_length=6)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    def generate_otp(self):
        self.otp_code = ''.join(random.choices(string.digits, k=6))
        self.created_at = timezone.now()
        self.expires_at = self.created_at + timedelta(minutes=1)
        self.save()

    def is_expired(self):
        return timezone.now() > self.expires_at

# =======================
# BALANCE MODEL
# =======================

class Balance(models.Model):
    customer = models.OneToOneField(User, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.customer.username} - ETB {self.amount}"

# =======================
# FINANCE & BANKING
# =======================

class Bank(models.Model):
    name = models.CharField(max_length=100)
    account_name = models.CharField(max_length=150)
    account_number = models.CharField(max_length=50)
    branch = models.CharField(max_length=100, blank=True, null=True)

    def __str__(self):
        return self.name

class Transaction(models.Model):
    BANK_CHOICES = [
        ('cbe', 'CBE'),
        ('telebirr', 'Telebirr'),
        ('abay', 'Abay Bank'),
        ('dashen', 'Dashen Bank'),
    ]
    TRANSACTION_TYPES = [
        ('deposit', 'Deposit'),
        ('withdraw', 'Withdraw'),
        ('profit', 'Profit'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('sent', 'Sent'),
    ]

    customer = models.ForeignKey(User, on_delete=models.CASCADE)
    type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    bank = models.CharField(max_length=20, choices=BANK_CHOICES, blank=True, null=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    account_number = models.CharField(max_length=50, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.customer.username} - {self.type} - {self.amount}"

class Withdrawal(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date_requested = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default='pending')

    def __str__(self):
        return f"Withdrawal {self.amount} by {self.user.username} - {self.status}"

class Recharge(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    transaction_id = models.CharField(max_length=100, unique=True, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

# =======================
# TASKS & REWARDS
# =======================

class Task(models.Model):
    name = models.CharField(max_length=100, default="Daily Task")
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2, default=250.00)
    min_vip_level = models.PositiveIntegerField(default=0)
    active = models.BooleanField(default=True)
    priority = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class TaskReward(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE)
    task = models.ForeignKey(Task, on_delete=models.CASCADE)
    reward_amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateField(auto_now_add=True)

class InviteReward(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="invite_rewards")
    invited_user = models.ForeignKey(User, on_delete=models.CASCADE)
    reward_amount = models.DecimalField(max_digits=10, decimal_places=2, default=12.5)
    date = models.DateField(auto_now_add=True)

class Commission(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    level = models.PositiveSmallIntegerField()
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Level {self.level} - {self.user.username} - {self.amount}"

# =======================
# VIP & INVESTMENT
# =======================

class VIP(models.Model):
    title = models.CharField(max_length=100)
    description = models.TextField()
    image_url = models.URLField(blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    daily_income = models.DecimalField(max_digits=10, decimal_places=2)
    income_days = models.IntegerField()
    upgrade = models.IntegerField(unique=True)

    def total_earning(self):
        return self.daily_income * self.income_days

    def __str__(self):
        return self.title

class UserVIP(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    vip = models.ForeignKey(VIP, on_delete=models.CASCADE)
    invested = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    last_claim_time = models.DateTimeField(null=True, blank=True)

    def can_claim(self):
        if self.last_claim_time is None:
            return True
        return timezone.now() >= self.last_claim_time + timedelta(hours=24)

class Investment(models.Model):
    customer = models.ForeignKey(Profile, on_delete=models.CASCADE)
    invested_on = models.DateTimeField(default=timezone.now)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    daily_profit_rate = models.FloatField(default=0.05)

    def calculate_profit(self):
        days = (timezone.now().date() - self.invested_on.date()).days
        return self.amount * (self.daily_profit_rate * days)

# =======================
# ORDERS & PAYMENTS
# =======================

class Order(models.Model):
    PAYMENT_CHOICES = [
        ('bank', 'Bank Transfer'),
        ('telebirr', 'TeleBirr'),
    ]
    customer = models.ForeignKey(User, on_delete=models.CASCADE)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_CHOICES)
    is_paid = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Order #{self.id} - {self.customer}"

class PaymentProof(models.Model):
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name="payment_proof")
    transaction_id = models.CharField(max_length=100, blank=True, null=True)
    receipt = models.ImageField(upload_to="receipts/", blank=True, null=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    verified = models.BooleanField(default=False)

# =======================
# INVITE LOG
# =======================


# =======================
# MESSAGING & SUPPORT
# =======================

class Message(models.Model):
    sender = models.CharField(max_length=100)
    content = models.TextField()
    timestamp = models.DateTimeField(default=timezone.now)
    parent = models.ForeignKey('self', null=True, blank=True, related_name='replies', on_delete=models.CASCADE)

    class Meta:
        ordering = ["timestamp"]

    def __str__(self):
        return f"{self.sender}: {self.content[:20]}"

class CustomerMessage(models.Model):
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.phone})"







class GiftCode(models.Model):
    """
    Single code used by all users.
    """
    code = models.CharField(max_length=12, unique=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    per_user_amount = models.DecimalField(max_digits=12, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    def remaining_amount(self):
        used_amount = sum([r.amount for r in self.redemptions.all()])
        return self.total_amount - used_amount

    def __str__(self):
        return self.code


class GiftRedemption(models.Model):
    """
    Tracks which users have redeemed the code.
    """
    code = models.ForeignKey(GiftCode, related_name="redemptions", on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    redeemed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('code', 'user')  # one redemption per user

    def __str__(self):
        return f"{self.user.username} - {self.amount}"


   
