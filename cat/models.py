from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.utils import timezone
from datetime import timedelta
import random, string
from django.conf import settings
from django.core.validators import MinValueValidator, EmailValidator


# =======================
# CUSTOM USER MODEL
# =======================

class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, username, phone=None, email=None, password=None, **extra_fields):
        if not username:
            raise ValueError("Username is required")
        email = self.normalize_email(email)
        user = self.model(username=username, phone=phone, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, phone=None, email=None, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(username=username, phone=phone, email=email, password=password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    username = models.CharField(max_length=150, unique=True)
    first_name = models.CharField(max_length=30, blank=True, null=True)
    last_name = models.CharField(max_length=30, blank=True, null=True) 
    phone = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)
    objects = UserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.username


class Profile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    phone = models.CharField(max_length=20, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    avatar = models.ImageField(upload_to="avatars/", default="avatars/default.png")
    vip_level = models.PositiveIntegerField(default=0)
    inviter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        related_name="invited_users",
        on_delete=models.SET_NULL,
    )
    points = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    account_number = models.CharField(max_length=50, blank=True, null=True)
    merchant_name = models.CharField(max_length=100, blank=True, default='')
    bank_type = models.CharField(max_length=50, blank=True, default='')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    available_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    invite_code = models.CharField(max_length=6, unique=True, blank=True, null=True)
    total_invested = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    total_withdrawn = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    total_earned = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    def save(self, *args, **kwargs):
        if not self.invite_code:
            self.invite_code = self.generate_invite_code()
        super().save(*args, **kwargs)

    @staticmethod
    def generate_invite_code():
        while True:
            code = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
            if not Profile.objects.filter(invite_code=code).exists():
                return code

    def __str__(self):
        return self.user.username


# =======================
# OTP MODEL
# =======================

class OTP(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    otp_code = models.CharField(max_length=6)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    def generate_otp(self):
        self.otp_code = "".join(random.choices(string.digits, k=6))
        self.created_at = timezone.now()
        self.expires_at = self.created_at + timedelta(minutes=1)
        self.save()

    def is_expired(self):
        return timezone.now() > self.expires_at


# =======================
# BALANCE MODEL
# =======================

class Balance(models.Model):
    customer = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.customer.username} - ETB {self.amount}"


# =======================
# FINANCE & BANKING
# =======================

STATUS_CHOICES = [
    ('available', 'Available'),
    ('sold_out', 'Sold Out'),
    ('coming_soon', 'Coming Soon'),
]


class BankAccount(models.Model):
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
        ('success', 'success'),
    ]
   
    customer = models.ForeignKey(User, on_delete=models.CASCADE)
    type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    bank = models.CharField(max_length=20, choices=BANK_CHOICES, blank=True, null=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    account_number = models.CharField(max_length=50, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    description = models.TextField(blank=True, null=True)
    date = models.DateTimeField(auto_now_add=True)
    def get_description(self, obj):
        """Create description from available data"""
        amount = getattr(obj, 'amount', 0)
        
        # Try to get type if it exists
        if hasattr(obj, 'type'):
            return f"{obj.type} of ${amount}"
        elif hasattr(obj, 'transaction_type'):
            return f"{obj.transaction_type} of ${amount}"
        else:
            return f"Transaction of ${amount}"
    def __str__(self):
        return f"{self.customer.phone} - {self.type} - {self.amount}"


class Withdrawal(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date_requested = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default='pending')

    def __str__(self):
        return f"Withdrawal {self.amount} by {self.user.phone} - {self.status}"


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
# PAYMENT METHODS & RECHARGE
# =======================

class PaymentMethod(models.Model):
    """Payment methods available for recharge"""
    PAYMENT_TYPES = [
        ('bank', 'Bank Transfer'),
        ('mobile_money', 'Mobile Money'),
        ('digital_wallet', 'Digital Wallet'),
        ('card', 'Card Payment'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Maintenance'),
    ]
    
    name = models.CharField(max_length=100)
    payment_type = models.CharField(max_length=20, choices=PAYMENT_TYPES)
    account_name = models.CharField(max_length=150)
    account_number = models.CharField(max_length=100)
    bank_name = models.CharField(max_length=100, blank=True, null=True)
    branch = models.CharField(max_length=100, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    qr_code = models.ImageField(upload_to='payment_qrcodes/', blank=True, null=True)
    instructions = models.TextField(blank=True)
    min_amount = models.DecimalField(max_digits=10, decimal_places=2, default=10.00)
    max_amount = models.DecimalField(max_digits=10, decimal_places=2, default=10000.00)
    processing_time = models.CharField(max_length=50, default='5-15 minutes')
    is_active = models.BooleanField(default=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    priority = models.IntegerField(default=0)
    icon = models.CharField(max_length=50, blank=True, null=True, help_text='FontAwesome icon class')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['priority', '-created_at']
        verbose_name = 'Payment Method'
        verbose_name_plural = 'Payment Methods'
    
    def __str__(self):
        return f"{self.name} - {self.get_payment_type_display()}"


class RechargeRequest(models.Model):
    """User recharge requests with manual verification"""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('unpaid', 'Unpaid'),
        ('paid', 'Paid'),
        ('verified', 'Payment Verified'),
    ]
    
    # User and payment info
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recharge_requests')
    payment_method = models.ForeignKey(PaymentMethod, on_delete=models.SET_NULL, null=True)
    
    # Transaction details
    transaction_id = models.CharField(max_length=100, unique=True, blank=True, null=True)
    reference_number = models.CharField(max_length=100, blank=True, null=True, help_text='User-provided transaction reference')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, help_text='Amount + Fee')
    
    # Status tracking
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='unpaid')
    
    # Payment proof
    payment_proof = models.ImageField(upload_to='payment_proofs/', blank=True, null=True)
    payment_details = models.TextField(blank=True, help_text='Additional payment information')
    
    # Bank/Mobile details (if provided separately)
    sender_account_name = models.CharField(max_length=150, blank=True, null=True)
    sender_account_number = models.CharField(max_length=100, blank=True, null=True)
    sender_bank = models.CharField(max_length=100, blank=True, null=True)
    sender_phone = models.CharField(max_length=20, blank=True, null=True)
    
    # Timestamps
    requested_at = models.DateTimeField(auto_now_add=True)
    payment_made_at = models.DateTimeField(null=True, blank=True)
    processed_at = models.DateTimeField(null=True, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    
    # Admin fields
    verified_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='verified_recharges')
    admin_notes = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-requested_at']
        indexes = [
            models.Index(fields=['transaction_id']),
            models.Index(fields=['status', 'payment_status']),
            models.Index(fields=['user', 'requested_at']),
        ]
    
    def __str__(self):
        return f"Recharge #{self.id} - {self.user.username} - ETB {self.amount}"
    
    def save(self, *args, **kwargs):
        # Generate transaction ID if not provided
        if not self.transaction_id:
            timestamp = timezone.now().strftime('%Y%m%d%H%M%S')
            random_str = ''.join(random.choices(string.digits, k=6))
            self.transaction_id = f"RCH{timestamp}{random_str}"
        
        # Calculate total amount
        if not self.total_amount:
            self.total_amount = self.amount + self.fee
        
        super().save(*args, **kwargs)
    
    def mark_as_paid(self, proof_image=None, details=None):
        """Mark recharge as paid by user"""
        self.payment_status = 'paid'
        self.payment_made_at = timezone.now()
        
        if proof_image:
            self.payment_proof = proof_image
        
        if details:
            self.payment_details = details
        
        self.save()
    
    def approve(self, admin_user):
        """Approve recharge request"""
        if self.status == 'pending' and self.payment_status == 'paid':
            self.status = 'completed'
            self.verified_by = admin_user
            self.verified_at = timezone.now()
            self.processed_at = timezone.now()
            
            # Update user balance
            profile = Profile.objects.filter(user=self.user).first()
            if profile:
                profile.balance += self.amount
                profile.available_balance += self.amount
                profile.save()
            
            # Create transaction record
            Transaction.objects.create(
                customer=self.user,
                type='deposit',
                amount=self.amount,
                status='success',
                account_number=profile.account_number if profile else None
            )
            
            self.save()
            return True
        return False
    
    def reject(self, admin_user, notes=None):
        """Reject recharge request"""
        self.status = 'failed'
        self.verified_by = admin_user
        self.verified_at = timezone.now()
        
        if notes:
            self.admin_notes = notes
        
        self.save()
        return True
    
    @property
    def is_pending_payment(self):
        return self.status == 'pending' and self.payment_status == 'unpaid'
    
    @property
    def is_ready_for_verification(self):
        return self.status == 'pending' and self.payment_status == 'paid'


class RechargeNotification(models.Model):
    """Notifications for recharge status updates"""
    recharge = models.ForeignKey(RechargeRequest, on_delete=models.CASCADE, related_name='notifications')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    notification_type = models.CharField(max_length=50, choices=[
        ('payment_required', 'Payment Required'),
        ('payment_received', 'Payment Received'),
        ('approved', 'Recharge Approved'),
        ('rejected', 'Recharge Rejected'),
        ('processing', 'Processing'),
    ])
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Notification for {self.recharge.transaction_id}"


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
        return f"Level {self.level} - {self.user.phone} - {self.amount}"


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
    is_active = models.BooleanField(default=True)
    def total_earning(self):
        return self.daily_income * self.income_days

    def __str__(self):
        return self.title


from django.db import models
from django.utils import timezone
from datetime import timedelta

class UserVIP(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    vip = models.ForeignKey(VIP, on_delete=models.CASCADE)
    invested = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    purchase_date = models.DateTimeField(default=timezone.now)  # ADD THIS LINE
    last_claim_time = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    def can_claim(self):
        if self.last_claim_time is None:
            return True
        return timezone.now() >= self.last_claim_time + timedelta(hours=24)
    
    def __str__(self):
        return f"{self.user.username} - {self.vip.title}"

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
# MESSAGING & SUPPORT
# =======================

class Message(models.Model):
    sender = models.CharField(max_length=100)
    content = models.TextField()
    timestamp = models.DateTimeField(default=timezone.now)
    parent = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='replies')
    is_support = models.BooleanField(default=False)
    message_type = models.CharField(max_length=20, default='text')  # 'text' or 'image'
    image_url = models.URLField(blank=True, null=True)
    
    class Meta:
        ordering = ['timestamp']
    
    def __str__(self):
        return f"{self.sender}: {self.content[:50]}"



class CustomerMessage(models.Model):
    phone = models.CharField(max_length=20)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.phone} "


# =======================
# GIFT CODES
# =======================

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
        return f"{self.user.phone} - {self.amount}"


# =======================
# MAIN PROJECT MODEL
# =======================

class MainProject(models.Model):
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('sold_out', 'Sold Out'),
        ('coming_soon', 'Coming Soon'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    short_description = models.CharField(max_length=300, blank=True)
    
    # Investment details
    price = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(0)])
    daily_income = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(0)])
    cycle_days = models.IntegerField(default=30, validators=[MinValueValidator(1)])
    total_income = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(0)])
    
    # Inventory
    total_units = models.IntegerField(default=1, validators=[MinValueValidator(1)])
    available_units = models.IntegerField(default=1, validators=[MinValueValidator(0)])
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    is_featured = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    
    # Images
    image_url = models.URLField(blank=True, null=True)
    thumbnail_url = models.URLField(blank=True, null=True)
    
    # SEO
    slug = models.SlugField(unique=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_featured', '-created_at']
        verbose_name = 'Main Project'
        verbose_name_plural = 'Main Projects'
    
    def __str__(self):
        return self.title
    
    def save(self, *args, **kwargs):
        # Calculate total income if not set
        if not self.total_income or self.total_income == 0:
            self.total_income = self.daily_income * self.cycle_days
        
        # Generate slug if not provided
        if not self.slug:
            from django.utils.text import slugify
            self.slug = slugify(self.title)
        
        # Update status based on availability
        if self.available_units <= 0:
            self.status = 'sold_out'
        elif self.status == 'sold_out' and self.available_units > 0:
            self.status = 'available'
        
        super().save(*args, **kwargs)
    
    @property
    def remaining_units(self):
        return max(0, self.available_units)
    
    @property
    def is_available(self):
        return self.status == 'available' and self.available_units > 0 and self.is_active
    
    @property
    def investment_summary(self):
        return {
            'price': float(self.price),
            'daily_income': float(self.daily_income),
            'cycle_days': self.cycle_days,
            'total_income': float(self.total_income),
            'available_units': self.available_units,
            'total_units': self.total_units,
            'is_available': self.is_available,
        }
    


class UserMainProject(models.Model):
    """Tracks user's main project purchases"""
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    main_project = models.ForeignKey('MainProject', on_delete=models.CASCADE)
    units = models.IntegerField(default=1, validators=[MinValueValidator(1)])
    invested_amount = models.DecimalField(max_digits=12, decimal_places=2)
    purchase_date = models.DateTimeField(auto_now_add=True)
    last_claim_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=[
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ], default='active')
    
    class Meta:
        unique_together = ('user', 'main_project')
        ordering = ['-purchase_date']
    
    def __str__(self):
        return f"{self.user.username} - {self.main_project.title} ({self.units} units)"
    
    def can_claim(self):
        """Check if user can claim income (24-hour cooldown)"""
        if self.status != 'active':
            return False
            
        if self.last_claim_time is None:
            return True
            
        # ✅ Now timedelta is imported
        from datetime import timedelta
        return timezone.now() >= self.last_claim_time + timedelta(hours=24)
    
    def remaining_days(self):
        """Calculate remaining days in the investment cycle"""
        if not self.purchase_date:  # Check if purchase_date exists
            return self.main_project.cycle_days if self.main_project.cycle_days > 0 else float('inf')
            
        if self.main_project.cycle_days <= 0:
            return float('inf')  # Infinite cycle
            
        days_since_purchase = (timezone.now() - self.purchase_date).days
        remaining = self.main_project.cycle_days - days_since_purchase
        return max(0, remaining)
    
    def is_active(self):
        """Check if investment should still be active"""
        if self.status == 'cancelled':
            return False
            
        # If manually marked as completed, respect that
        if self.status == 'completed':
            return False
            
        # Check cycle days
        if self.main_project.cycle_days <= 0:
            return True  # Infinite cycle
            
        if not self.purchase_date:  # Check if purchase_date exists
            return True  # New investment is active
            
        days_since_purchase = (timezone.now() - self.purchase_date).days
        return days_since_purchase < self.main_project.cycle_days
    
    def claim_income(self):
        """Claim daily income from the investment"""
        if not self.can_claim():
            return None
            
        # Calculate daily income
        daily_income = self.main_project.daily_income * self.units
        
        # Update user balance
        try:
            # Import inside method to avoid circular imports
            from .models import Profile
            profile = Profile.objects.get(user=self.user)
            profile.balance += daily_income
            profile.available_balance += daily_income
            profile.save()
        except Profile.DoesNotExist:
            # Create profile if it doesn't exist
            from .models import Profile
            profile = Profile.objects.create(user=self.user)
            profile.balance = daily_income
            profile.available_balance = daily_income
            profile.save()
        
        # Update last claim time
        self.last_claim_time = timezone.now()
        
        # Check and update status based on cycle completion
        if self.main_project.cycle_days > 0 and self.purchase_date:
            days_since_purchase = (timezone.now() - self.purchase_date).days
            if days_since_purchase >= self.main_project.cycle_days:
                self.status = 'completed'
        
        self.save()
        
        return daily_income
    
    def save(self, *args, **kwargs):
        """Override save to auto-update status based on cycle days"""
        # Auto-update status when saving
        if self.main_project.cycle_days > 0 and self.purchase_date:
            days_since_purchase = (timezone.now() - self.purchase_date).days
            if days_since_purchase >= self.main_project.cycle_days:
                self.status = 'completed'
            elif self.status == 'completed' and days_since_purchase < self.main_project.cycle_days:
                # If someone manually set to completed but cycle isn't over, revert to active
                self.status = 'active'
        
        super().save(*args, **kwargs)






from django.core.validators import FileExtensionValidator
import os
import uuid

def video_upload_path(instance, filename):
    # Upload to: videos/{username}/{filename}
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('videos', instance.uploaded_by.username, filename)

def thumbnail_upload_path(instance, filename):
    # Upload to: thumbnails/{username}/{filename}
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('thumbnails', instance.uploaded_by.username, filename)

class Video(models.Model):
    CATEGORY_CHOICES = [
        ('educational', 'Educational'),
        ('training', 'Training'),
        ('news', 'News'),
        ('tutorial', 'Tutorial'),
        ('promotional', 'Promotional'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    video_file = models.FileField(
        upload_to=video_upload_path,
        validators=[FileExtensionValidator(allowed_extensions=['mp4', 'avi', 'mov', 'mkv', 'webm'])],
        help_text='Upload video files (MP4, AVI, MOV, MKV, WEBM)'
    )
    thumbnail = models.ImageField(
        upload_to=thumbnail_upload_path,
        null=True,
        blank=True,
        help_text='Optional thumbnail image'
    )
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='educational')
    duration = models.IntegerField(default=0, help_text='Duration in seconds')
    file_size = models.BigIntegerField(default=0, help_text='File size in bytes')
    views = models.PositiveIntegerField(default=0)
    likes = models.PositiveIntegerField(default=0)
    dislikes = models.PositiveIntegerField(default=0)
    is_featured = models.BooleanField(default=False)
    is_published = models.BooleanField(default=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='approved')
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='uploaded_videos')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_videos')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['category']),
            models.Index(fields=['is_featured']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return self.title
    
    def save(self, *args, **kwargs):
        if self.is_published and not self.published_at:
            self.published_at = timezone.now()
        if not self.is_published:
            self.published_at = None
        super().save(*args, **kwargs)
    
    def get_video_url(self):
        """Get the absolute URL for the video file"""
        return self.video_file.url if self.video_file else None
    
    def get_thumbnail_url(self):
        """Get the absolute URL for the thumbnail"""
        if self.thumbnail:
            return self.thumbnail.url
        # Return default thumbnail if none uploaded
        return '/static/images/default-video-thumbnail.jpg'
    
    def format_duration(self):
        """Format duration in HH:MM:SS"""
        hours = self.duration // 3600
        minutes = (self.duration % 3600) // 60
        seconds = self.duration % 60
        if hours > 0:
            return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        return f"{minutes:02d}:{seconds:02d}"
    
    def format_file_size(self):
        """Format file size in human-readable format"""
        size = self.file_size
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.2f} {unit}"
            size /= 1024.0
        return f"{size:.2f} TB"