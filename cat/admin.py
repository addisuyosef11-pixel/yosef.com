from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import *
from django.utils.html import format_html
from django.urls import reverse


# =======================
# ADMIN SITE CONFIGURATION
# =======================

admin.site.site_header = "Investment Platform Administration"
admin.site.site_title = "Admin Portal"
admin.site.index_title = "Welcome to Investment Platform Admin"


# =======================
# INLINE ADMIN CLASSES
# =======================

class ProfileInline(admin.StackedInline):
    model = Profile
    can_delete = False
    verbose_name_plural = 'Profile'
    fk_name = 'user'  # Specify which ForeignKey to use (the OneToOneField)
    readonly_fields = ('invite_code', 'balance', 'available_balance')
    fieldsets = (
        ('Personal Info', {
            'fields': ('phone', 'address', 'avatar', 'vip_level')
        }),
        ('Financial', {
            'fields': ('points', 'balance', 'available_balance', 'account_number')
        }),
        ('Referral', {
            'fields': ('inviter', 'invite_code')
        }),
    )


# =======================
# CUSTOM USER ADMIN
# =======================

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'phone', 'first_name', 'last_name', 
                   'is_staff', 'is_active')
    list_filter = ('is_staff', 'is_superuser', 'is_active')
    search_fields = ('username', 'email', 'phone', 'first_name', 'last_name')
    ordering = ('-id',)  # Changed from -date_joined to -id
    readonly_fields = ('last_login',)  # Removed date_joined
    
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'email', 'phone')}),
        (_('Permissions'), {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        (_('Important dates'), {'fields': ('last_login',)}),  # Removed date_joined
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'phone', 'password1', 'password2'),
        }),
    )
    
    inlines = [ProfileInline]
    
    def get_inline_instances(self, request, obj=None):
        if not obj:
            return []
        return super().get_inline_instances(request, obj)


# =======================
# PROFILE ADMIN
# =======================





from django.contrib import admin
from django.urls import path, reverse
from django.utils.html import format_html
from django.shortcuts import render, redirect
from django.http import HttpResponseRedirect
from django.contrib import messages
from django.db.models import Sum
from datetime import datetime
from .models import Profile, Transaction, RechargeRequest, Balance


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'phone', 'vip_level', 'balance_display', 
                   'available_balance_display', 'points', 'inviter_link',
                   'account_number', 'merchant_name', 'bank_type', 'get_recharge_action')
    list_filter = ('vip_level', 'bank_type')
    search_fields = ('user__username', 'phone', 'invite_code', 'account_number', 'merchant_name')
    readonly_fields = ('invite_code', 'balance', 'available_balance', 'user_link', 
                      'total_invested', 'total_withdrawn', 'total_earned', 'get_recharge_link')
    
    fieldsets = (
        ('User Information', {
            'fields': ('user_link', 'phone', 'address', 'avatar')
        }),
        ('Bank Account Details', {
            'fields': ('account_number', 'merchant_name', 'bank_type', 'withdraw_password')
        }),
        ('Financial Information', {
            'fields': ('balance', 'available_balance', 'points', 
                      'total_invested', 'total_withdrawn', 'total_earned')
        }),
        ('VIP & Referral', {
            'fields': ('vip_level', 'inviter_link', 'invite_code')
        }),
        ('Admin Actions', {
            'fields': ('get_recharge_link',),
            'classes': ('collapse',),
        }),
    )
    
    actions = ['manual_recharge_selected', 'reset_withdraw_password', 'export_bank_details']
    
    def balance_display(self, obj):
        return f"₹{obj.balance:,.2f}"
    balance_display.short_description = 'Balance'
    
    def available_balance_display(self, obj):
        return f"₹{obj.available_balance:,.2f}"
    available_balance_display.short_description = 'Available Balance'
    
    def user_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.username)
    user_link.short_description = 'User'
    
    def inviter_link(self, obj):
        if obj.inviter:
            url = reverse('admin:auth_user_change', args=[obj.inviter.id])
            return format_html('<a href="{}">{}</a>', url, obj.inviter.username)
        return "None"
    inviter_link.short_description = 'Inviter'
    
    def get_recharge_action(self, obj):
        return format_html(
            '<a class="button" href="recharge/{}/">Recharge</a>',
            obj.id
        )
    get_recharge_action.short_description = 'Action'
    
    def get_recharge_link(self, obj):
        return format_html(
            '<a class="button" href="/admin/custom_admin/manual-recharge/{}/" style="background-color: #4CAF50; color: white; padding: 8px 16px; text-decoration: none; border-radius: 4px;">💰 Manual Recharge</a>',
            obj.user.id
        )
    get_recharge_link.short_description = 'Quick Recharge'
    
    # Custom admin views for recharge
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('recharge/<int:profile_id>/', self.admin_site.admin_view(self.recharge_view),
                 name='profile-recharge'),
            path('manual-recharge/<int:user_id>/', self.admin_site.admin_view(self.manual_recharge_view),
                 name='manual-recharge'),
        ]
        return custom_urls + urls
    
    def recharge_view(self, request, profile_id):
        try:
            profile = Profile.objects.get(id=profile_id)
            
            if request.method == 'POST':
                amount = request.POST.get('amount')
                description = request.POST.get('description', 'Admin manual recharge')
                
                if amount:
                    try:
                        amount = float(amount)
                        if amount <= 0:
                            messages.error(request, 'Amount must be positive')
                        else:
                            # Perform recharge
                            old_balance = profile.balance
                            profile.balance += amount
                            profile.available_balance += amount
                            profile.total_earned += amount
                            profile.save()
                            
                            # Create transaction record
                            Transaction.objects.create(
                                user=profile.user,
                                amount=amount,
                                transaction_type='admin_recharge',
                                status='completed',
                                description=description,
                                balance_after=profile.balance
                            )
                            
                            # Create recharge request for audit
                            RechargeRequest.objects.create(
                                user=profile.user,
                                amount=amount,
                                admin_user=request.user,
                                status='approved',
                                notes=description
                            )
                            
                            # Create balance history
                            Balance.objects.create(
                                user=profile.user,
                                old_balance=old_balance,
                                new_balance=profile.balance,
                                change_amount=amount,
                                change_type='admin_recharge',
                                description=description,
                                admin_user=request.user.username
                            )
                            
                            messages.success(request, f'Successfully recharged ₹{amount:,.2f} to {profile.user.username}')
                            return redirect('admin:cat_profile_changelist')
                            
                    except ValueError:
                        messages.error(request, 'Invalid amount format')
            
            return render(request, 'admin/profile_recharge.html', {
                'profile': profile,
                'title': f'Recharge {profile.user.username}'
            })
            
        except Profile.DoesNotExist:
            messages.error(request, 'Profile not found')
            return redirect('admin:cat_profile_changelist')
    
    def manual_recharge_view(self, request, user_id):
        from django.contrib.auth.models import User
        try:
            user = User.objects.get(id=user_id)
            profile = user.profile
            
            if request.method == 'POST':
                amount = request.POST.get('amount')
                description = request.POST.get('description', 'Manual recharge by admin')
                
                if amount:
                    try:
                        amount = float(amount)
                        old_balance = profile.balance
                        old_available = profile.available_balance
                        
                        profile.balance += amount
                        profile.available_balance += amount
                        profile.total_earned += amount
                        profile.save()
                        
                        # Create transaction record
                        Transaction.objects.create(
                            user=user,
                            amount=amount,
                            transaction_type='admin_recharge',
                            status='completed',
                            description=description,
                            balance_after=profile.balance
                        )
                        
                        # Create recharge request
                        RechargeRequest.objects.create(
                            user=user,
                            amount=amount,
                            admin_user=request.user,
                            status='approved',
                            notes=description
                        )
                        
                        # Create balance history
                        Balance.objects.create(
                            user=user,
                            old_balance=old_balance,
                            new_balance=profile.balance,
                            change_amount=amount,
                            change_type='admin_recharge',
                            description=f"Admin recharge: {description}",
                            admin_user=request.user.username
                        )
                        
                        messages.success(request, f'✅ Successfully recharged ₹{amount:,.2f} to {user.username}')
                        return redirect(f'/admin/cat/profile/{profile.id}/change/')
                        
                    except ValueError:
                        messages.error(request, '❌ Invalid amount format')
            
            return render(request, 'admin/manual_recharge.html', {
                'user': user,
                'profile': profile,
                'title': f'Manual Recharge - {user.username}'
            })
            
        except User.DoesNotExist:
            messages.error(request, '❌ User not found')
            return redirect('/admin/')
        except Profile.DoesNotExist:
            messages.error(request, '❌ Profile not found')
            return redirect('/admin/')
    
    # Admin actions
    def manual_recharge_selected(self, request, queryset):
        if 'apply' in request.POST:
            amount = request.POST.get('amount')
            description = request.POST.get('description', 'Bulk recharge by admin')
            
            if not amount:
                self.message_user(request, 'Please enter an amount', level=messages.ERROR)
                return redirect('..')
            
            try:
                amount = float(amount)
                if amount <= 0:
                    self.message_user(request, 'Amount must be positive', level=messages.ERROR)
                    return redirect('..')
                    
                success_count = 0
                for profile in queryset:
                    try:
                        old_balance = profile.balance
                        old_available = profile.available_balance
                        
                        profile.balance += amount
                        profile.available_balance += amount
                        profile.total_earned += amount
                        profile.save()
                        
                        # Create records
                        Transaction.objects.create(
                            user=profile.user,
                            amount=amount,
                            transaction_type='admin_recharge',
                            status='completed',
                            description=description,
                            balance_after=profile.balance
                        )
                        
                        RechargeRequest.objects.create(
                            user=profile.user,
                            amount=amount,
                            admin_user=request.user,
                            status='approved',
                            notes=description
                        )
                        
                        BalanceHistory.objects.create(
                            user=profile.user,
                            old_balance=old_balance,
                            new_balance=profile.balance,
                            change_amount=amount,
                            change_type='admin_recharge',
                            description=f"Bulk recharge: {description}",
                            admin_user=request.user.username
                        )
                        
                        success_count += 1
                        
                    except Exception as e:
                        self.message_user(request, f'Error recharging {profile.user.username}: {str(e)}', level=messages.WARNING)
                
                self.message_user(request, 
                    f'✅ Successfully recharged {success_count}/{queryset.count()} profile(s) with ₹{amount:,.2f} each', 
                    level=messages.SUCCESS
                )
                return redirect('..')
                
            except ValueError:
                self.message_user(request, '❌ Invalid amount format', level=messages.ERROR)
                return redirect('..')
                
        return render(request, 'admin/bulk_recharge.html', {
            'profiles': queryset,
            'total_profiles': queryset.count(),
            'opts': self.model._meta,
        })
    
    manual_recharge_selected.short_description = "💰 Manual recharge selected"
    
    def reset_withdraw_password(self, request, queryset):
        for profile in queryset:
            profile.withdraw_password = None  # Reset to null
            profile.save()
        self.message_user(request, f'✅ Withdraw password reset for {queryset.count()} profile(s)', level=messages.SUCCESS)
    
    reset_withdraw_password.short_description = "🔒 Reset withdraw password"
    
    def export_bank_details(self, request, queryset):
        import csv
        from django.http import HttpResponse
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="bank_details_export.csv"'
        
        writer = csv.writer(response)
        writer.writerow(['Username', 'Email', 'Phone', 'Merchant Name', 'Bank Type', 
                        'Account Number', 'Balance', 'Available Balance'])
        
        for profile in queryset:
            writer.writerow([
                profile.user.username,
                profile.user.email,
                profile.phone or '',
                profile.merchant_name or '',
                profile.bank_type or '',
                profile.account_number or '',
                f"₹{profile.balance:,.2f}",
                f"₹{profile.available_balance:,.2f}"
            ])
        
        return response
    
    export_bank_details.short_description = "📄 Export bank details to CSV"


# =======================
# OTP ADMIN
# =======================

@admin.register(OTP)
class OTPAdmin(admin.ModelAdmin):
    list_display = ('user', 'otp_code', 'is_verified', 'created_at', 
                   'expires_at', 'is_expired_display')
    list_filter = ('is_verified', 'created_at')
    search_fields = ('user__username', 'otp_code')
    readonly_fields = ('otp_code', 'created_at', 'expires_at', 'is_expired_display')
    
    def is_expired_display(self, obj):
        if obj.is_expired():
            return format_html('<span style="color: red;">Expired</span>')
        return format_html('<span style="color: green;">Valid</span>')
    is_expired_display.short_description = 'Status'


# =======================
# BALANCE ADMIN
# =======================

@admin.register(Balance)
class BalanceAdmin(admin.ModelAdmin):
    list_display = ('customer', 'amount', 'updated_at')
    search_fields = ('customer__username',)
    readonly_fields = ('updated_at',)


# =======================
# BANK ACCOUNT ADMIN
# =======================

@admin.register(BankAccount)
class BankAccountAdmin(admin.ModelAdmin):
    list_display = ('name', 'account_name', 'account_number', 'branch')
    search_fields = ('name', 'account_name', 'account_number')


# =======================
# TRANSACTION ADMIN
# =======================

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('customer', 'type', 'amount', 'bank', 'status', 'date')
    list_filter = ('type', 'status', 'bank', 'date')
    search_fields = ('customer__username', 'account_number', 'phone_number')
    readonly_fields = ('date',)
    list_editable = ('status',)
    fieldsets = (
        ('Transaction Details', {
            'fields': ('customer', 'type', 'amount', 'bank')
        }),
        ('Account Information', {
            'fields': ('account_number', 'phone_number')
        }),
        ('Status', {
            'fields': ('status', 'date')
        }),
    )


# =======================
# WITHDRAWAL ADMIN
# =======================

@admin.register(Withdrawal)
class WithdrawalAdmin(admin.ModelAdmin):
    list_display = ('user', 'amount', 'date_requested', 'status')
    list_filter = ('status', 'date_requested')
    search_fields = ('user__username',)
    list_editable = ('status',)
    readonly_fields = ('date_requested',)


# =======================
# RECHARGE ADMIN
# =======================

@admin.register(Recharge)
class RechargeAdmin(admin.ModelAdmin):
    list_display = ('user', 'amount', 'status', 'transaction_id', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('user__username', 'transaction_id')
    list_editable = ('status',)
    readonly_fields = ('created_at',)


# =======================
# TASK ADMIN
# =======================

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'min_vip_level', 'active', 'priority', 'created_at')
    list_filter = ('active', 'min_vip_level', 'created_at')
    search_fields = ('name', 'description')
    list_editable = ('price', 'active', 'priority', 'min_vip_level')
    fieldsets = (
        ('Task Information', {
            'fields': ('name', 'description')
        }),
        ('Requirements & Rewards', {
            'fields': ('price', 'min_vip_level')
        }),
        ('Settings', {
            'fields': ('active', 'priority')
        }),
    )


# =======================
# TASK REWARD ADMIN
# =======================

@admin.register(TaskReward)
class TaskRewardAdmin(admin.ModelAdmin):
    list_display = ('profile', 'task', 'reward_amount', 'date')
    list_filter = ('date', 'task')
    search_fields = ('profile__user__username', 'task__name')
    readonly_fields = ('date',)


# =======================
# INVITE REWARD ADMIN
# =======================

@admin.register(InviteReward)
class InviteRewardAdmin(admin.ModelAdmin):
    list_display = ('profile', 'invited_user', 'reward_amount', 'date')
    list_filter = ('date',)
    search_fields = ('profile__user__username', 'invited_user__username')
    readonly_fields = ('date',)


# =======================
# COMMISSION ADMIN
# =======================

@admin.register(Commission)
class CommissionAdmin(admin.ModelAdmin):
    list_display = ('user', 'level', 'amount', 'created_at')
    list_filter = ('level', 'created_at')
    search_fields = ('user__username',)
    readonly_fields = ('created_at',)


# =======================
# VIP ADMIN
# =======================

@admin.register(VIP)
class VIPAdmin(admin.ModelAdmin):
    list_display = ('title', 'price', 'daily_income', 'income_days', 
                   'upgrade', 'total_earning_display')
    list_filter = ('upgrade',)
    search_fields = ('title', 'description')
    readonly_fields = ('total_earning_display',)
    fieldsets = (
        ('VIP Information', {
            'fields': ('title', 'description', 'image_url')
        }),
        ('Investment Details', {
            'fields': ('price', 'daily_income', 'income_days', 'upgrade')
        }),
        ('Calculations', {
            'fields': ('total_earning_display',)
        }),
    )
    
    def total_earning_display(self, obj):
        if obj is None:
            return "ETB 0.00"
        
        try:
            # Check if total_earning is callable or a property
            if callable(getattr(obj, 'total_earning', None)):
                total = obj.total_earning()
            else:
                total = obj.total_earning
            
            # Handle None result
            if total is None:
                return "ETB 0.00"
                
            return f"ETB {total:,.2f}"
        except (TypeError, AttributeError) as e:
            return f"ETB 0.00 (Error: {str(e)[:50]})"
    
    total_earning_display.short_description = 'Total Earning'


@admin.register(UserVIP)
class UserVIPAdmin(admin.ModelAdmin):
    list_display = ('user', 'vip', 'invested', 'purchase_date', 'last_claim_time', 'can_claim_display', 'status_display')
    list_filter = ('vip', 'last_claim_time', 'vip__income_days')
    search_fields = ('user__username', 'vip__title')
    
    # Fields to display in detail view
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'vip')
        }),
        ('Investment Details', {
            'fields': ('invested', 'purchase_date', 'last_claim_time')
        }),
        ('Status', {
            'fields': ('status_display', 'can_claim_display', 'remaining_days_display')
        }),
    )
    
    readonly_fields = ('status_display', 'can_claim_display', 'remaining_days_display')
    
    # Custom methods for list display
    def status_display(self, obj):
        if hasattr(obj, 'status'):
            colors = {
                'active': 'green',
                'completed': 'blue',
                'cancelled': 'red',
            }
            color = colors.get(obj.status, 'gray')
            return format_html(
                '<span style="color: white; background-color: {}; padding: 2px 6px; border-radius: 10px; font-size: 12px;">{}</span>',
                color,
                obj.status.upper()
            )
        return "Unknown"
    status_display.short_description = 'Status'
    
    def can_claim_display(self, obj):
        try:
            if obj and hasattr(obj, 'can_claim'):
                if obj.can_claim():
                    return format_html('<span style="color: green; font-weight: bold;">✅ READY</span>')
                
                # Show countdown if not ready
                if obj.last_claim_time:
                    from django.utils import timezone
                    from datetime import timedelta
                    
                    next_claim = obj.last_claim_time + timedelta(hours=24)
                    now = timezone.now()
                    
                    if next_claim > now:
                        time_remaining = next_claim - now
                        hours = time_remaining.seconds // 3600
                        minutes = (time_remaining.seconds % 3600) // 60
                        return format_html(
                            '<span style="color: orange;">⏳ {}h {}m</span>',
                            hours,
                            minutes
                        )
                
                return format_html('<span style="color: red;">❌ NOT READY</span>')
        except Exception as e:
            # Handle error properly - don't use f-string in format_html
            error_msg = str(e)[:50] if str(e) else "Unknown error"
            return format_html('<span style="color: orange;">Error: {}</span>', error_msg)
        
        return format_html('<span style="color: gray;">N/A</span>')
    
    can_claim_display.short_description = 'Claim Status'
    
    def remaining_days_display(self, obj):
        try:
            if obj and hasattr(obj, 'vip') and obj.vip:
                if hasattr(obj.vip, 'income_days'):
                    from django.utils import timezone
                    
                    if obj.vip.income_days <= 0:
                        return "∞ (Infinite)"
                    
                    if hasattr(obj, 'purchase_date') and obj.purchase_date:
                        days_since_purchase = (timezone.now() - obj.purchase_date).days
                        remaining = obj.vip.income_days - days_since_purchase
                        
                        if remaining <= 0:
                            return format_html('<span style="color: red; font-weight: bold;">0 (Expired)</span>')
                        elif remaining <= 3:
                            return format_html('<span style="color: orange;">{} days</span>', remaining)
                        else:
                            return f"{remaining} days"
        except Exception:
            pass
        
        return "N/A"
    
    remaining_days_display.short_description = 'Remaining Days'
    
    # Custom actions
    actions = ['reset_claim_timer', 'force_claim']
    
    def reset_claim_timer(self, request, queryset):
        updated = queryset.update(last_claim_time=None)
        self.message_user(request, f"{updated} claim timers reset.")
    reset_claim_timer.short_description = "Reset claim timer"
    
    def force_claim(self, request, queryset):
        successful = 0
        failed = 0
        
        for user_vip in queryset:
            try:
                if hasattr(user_vip, 'claim_income'):
                    result = user_vip.claim_income()
                    if result:
                        successful += 1
                    else:
                        failed += 1
                else:
                    failed += 1
            except Exception:
                failed += 1
        
        self.message_user(request, f"Force claim: {successful} successful, {failed} failed.")
    force_claim.short_description = "Force claim income"





# =======================
# ORDER ADMIN
# =======================

class PaymentProofInline(admin.StackedInline):
    model = PaymentProof
    can_delete = False
    verbose_name_plural = 'Payment Proof'
    readonly_fields = ('submitted_at', 'receipt_preview')
    
    def receipt_preview(self, obj):
        if obj.receipt:
            return format_html('<img src="{}" width="200" height="200" />', obj.receipt.url)
        return "No receipt uploaded"
    receipt_preview.short_description = 'Receipt Preview'


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'customer', 'total_amount', 'payment_method', 
                   'is_paid', 'created_at', 'payment_status')
    list_filter = ('is_paid', 'payment_method', 'created_at')
    search_fields = ('customer__username', 'id')
    readonly_fields = ('created_at',)
    list_editable = ('is_paid',)
    inlines = [PaymentProofInline]
    
    def payment_status(self, obj):
        if obj.is_paid:
            return format_html('<span style="color: green;">● Paid</span>')
        return format_html('<span style="color: orange;">● Pending</span>')
    payment_status.short_description = 'Status'


# =======================
# PAYMENT PROOF ADMIN
# =======================

@admin.register(PaymentProof)
class PaymentProofAdmin(admin.ModelAdmin):
    list_display = ('order', 'transaction_id', 'verified', 'submitted_at', 'receipt_preview')
    list_filter = ('verified', 'submitted_at')
    search_fields = ('order__id', 'transaction_id')
    list_editable = ('verified',)
    readonly_fields = ('submitted_at', 'receipt_preview')
    
    def receipt_preview(self, obj):
        if obj.receipt:
            return format_html('<img src="{}" width="100" height="100" />', obj.receipt.url)
        return "No receipt uploaded"
    receipt_preview.short_description = 'Receipt'


# =======================
# MESSAGE ADMIN
# =======================

class MessageInline(admin.TabularInline):
    model = Message
    fk_name = 'parent'
    extra = 0
    readonly_fields = ('sender', 'content', 'timestamp')


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('sender', 'content_preview', 'timestamp', 'has_replies')
    list_filter = ('timestamp',)
    search_fields = ('sender', 'content')
    readonly_fields = ('timestamp', 'replies_count')
    inlines = [MessageInline]
    
    def content_preview(self, obj):
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'
    
    def has_replies(self, obj):
        return obj.replies.exists()
    has_replies.boolean = True
    has_replies.short_description = 'Replies'
    
    def replies_count(self, obj):
        return obj.replies.count()
    replies_count.short_description = 'Number of Replies'


# =======================
# CUSTOMER MESSAGE ADMIN
# =======================

@admin.register(CustomerMessage)
class CustomerMessageAdmin(admin.ModelAdmin):
    list_display = ('phone', 'message_preview', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('phone', 'message')
    readonly_fields = ('created_at',)
    
    def message_preview(self, obj):
        return obj.message[:50] + "..." if len(obj.message) > 50 else obj.message
    message_preview.short_description = 'Message'


# =======================
# GIFT CODE ADMIN
# =======================

class GiftRedemptionInline(admin.TabularInline):
    model = GiftRedemption
    extra = 0
    readonly_fields = ('redeemed_at', 'user_link')
    
    def user_link(self, obj):
        url = reverse('admin:cat_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.username)
    user_link.short_description = 'User'


@admin.register(GiftCode)
class GiftCodeAdmin(admin.ModelAdmin):
    list_display = ('code', 'total_amount', 'per_user_amount', 
                   'created_at', 'remaining_amount_display', 'redemptions_count')
    search_fields = ('code',)
    readonly_fields = ('created_at', 'remaining_amount_display', 'redemptions_count')
    inlines = [GiftRedemptionInline]
    
    def remaining_amount_display(self, obj):
        if obj is None:
            return format_html('<span style="color: gray;">N/A</span>')
        
        try:
            remaining = obj.remaining_amount()
            
            # Format the number BEFORE passing to format_html
            remaining_formatted = f"{remaining:.2f}"
            
            if remaining <= 0:
                return format_html(
                    '<span style="color: red;">ETB {} (Exhausted)</span>',
                    remaining_formatted
                )
            return format_html(
                '<span style="color: green;">ETB {}</span>',
                remaining_formatted
            )
        except (AttributeError, TypeError, ValueError) as e:
            return format_html('<span style="color: gray;">Error: {}</span>', str(e)[:30])
    
    remaining_amount_display.short_description = 'Remaining Amount'
    
    def redemptions_count(self, obj):
        if obj is None:
            return 0
        return obj.redemptions.count()
    
    redemptions_count.short_description = 'Total Redemptions'

# =======================
# GIFT REDEMPTION ADMIN
# =======================

@admin.register(GiftRedemption)
class GiftRedemptionAdmin(admin.ModelAdmin):
    list_display = ('code', 'user', 'amount', 'redeemed_at')
    list_filter = ('redeemed_at', 'code')
    search_fields = ('code__code', 'user__username')
    readonly_fields = ('redeemed_at',)


# =======================
# MAIN PROJECT ADMIN
# =======================

from django.utils.html import format_html

@admin.register(MainProject)
class MainProjectAdmin(admin.ModelAdmin):
    list_display = ('title', 'status', 'price', 'daily_income', 
                   'available_units', 'total_units', 'is_featured', 
                   'created_at', 'availability_status')
    list_filter = ('status', 'is_featured', 'is_active', 'created_at')
    search_fields = ('title', 'description', 'slug')
    list_editable = ('status', 'is_featured')
    readonly_fields = ('created_at', 'updated_at', 'total_income_calculated', 
                      'availability_status')  # Remove investment_summary_display from here
    prepopulated_fields = {'slug': ('title',)}
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'slug', 'description', 'short_description')
        }),
        ('Investment Details', {
            'fields': ('price', 'daily_income', 'cycle_days', 'total_income')
        }),
        ('Inventory Management', {
            'fields': ('total_units', 'available_units')
        }),
        ('Status & Visibility', {
            'fields': ('status', 'is_featured', 'is_active')
        }),
        ('Media', {
            'fields': ('image_url', 'thumbnail_url')
        }),
        ('Calculations & Stats', {
            'fields': ('total_income_calculated', 'availability_status', 
                      'investment_summary_display')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        """Only show investment_summary_display when editing existing object"""
        readonly_fields = list(self.readonly_fields)
        
        if obj:  # obj exists (edit mode)
            readonly_fields.append('investment_summary_display')
        
        return tuple(readonly_fields)
    
    def get_fieldsets(self, request, obj=None):
        """Conditionally show fieldsets based on object existence"""
        fieldsets = super().get_fieldsets(request, obj)
        
        # If adding new object, hide the Calculations & Stats section
        if obj is None:
            # Filter out the Calculations & Stats section
            fieldsets = [fs for fs in fieldsets if fs[0] != 'Calculations & Stats']
        
        return fieldsets

    # Safe calculation for total income
    def total_income_calculated(self, obj):
        if obj is None:
            return "N/A"
        daily_income = obj.daily_income or 0
        cycle_days = obj.cycle_days or 0
        return f"ETB {daily_income * cycle_days:,.2f}"
    total_income_calculated.short_description = 'Calculated Total Income'

    # Availability status
    def availability_status(self, obj):
        if obj is None:
            return format_html('<span style="color: gray;">N/A</span>')
        
        if not obj.is_active:
            return format_html('<span style="color: gray; font-weight: bold;">Inactive</span>')
        elif obj.status == 'sold_out':
            return format_html('<span style="color: red; font-weight: bold;">SOLD OUT</span>')
        elif obj.status == 'coming_soon':
            return format_html('<span style="color: blue; font-weight: bold;">COMING SOON</span>')
        else:
            available = obj.available_units or 0
            total = obj.total_units or 0
            return format_html('<span style="color: green; font-weight: bold;">AVAILABLE ({}/{})</span>', available, total)
    availability_status.short_description = 'Availability'

    # Safe investment summary display - only shows when obj exists
    def investment_summary_display(self, obj):
        if obj is None:
            return "N/A"
        
        try:
            summary = obj.investment_summary
            
            # Safely extract values from summary
            price = summary.get('price', 0) or 0
            daily_income = summary.get('daily_income', 0) or 0
            cycle_days = summary.get('cycle_days', 0) or 0
            total_income = summary.get('total_income', 0) or 0
            available_units = summary.get('available_units', 0) or 0
            total_units = summary.get('total_units', 0) or 0
            sold_units = summary.get('sold_units', 0) or 0
            remaining_investment = summary.get('remaining_investment', 0) or 0
            completion_percentage = summary.get('completion_percentage', 0) or 0
            
            return format_html("""
                <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; border-left: 4px solid #4CAF50;">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
                        <div>
                            <strong style="color: #666;">Price:</strong><br>
                            <span style="font-size: 18px; font-weight: bold; color: #2196F3;">ETB {price:,.2f}</span>
                        </div>
                        <div>
                            <strong style="color: #666;">Daily Income:</strong><br>
                            <span style="font-size: 18px; font-weight: bold; color: #4CAF50;">ETB {daily_income:,.2f}</span>
                        </div>
                        <div>
                            <strong style="color: #666;">Total Income:</strong><br>
                            <span style="font-size: 18px; font-weight: bold; color: #FF9800;">ETB {total_income:,.2f}</span>
                        </div>
                    </div>
                    
                    <hr style="border: none; border-top: 1px solid #ddd; margin: 10px 0;">
                    
                    <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
                        <div>
                            <strong style="color: #666;">Units:</strong><br>
                            <span style="font-size: 16px;">{sold_units} sold / {available_units} available / {total_units} total</span>
                        </div>
                        <div>
                            <strong style="color: #666;">Progress:</strong><br>
                            <span style="font-size: 16px; font-weight: bold; color: {color};">{completion_percentage:.1f}%</span>
                        </div>
                    </div>
                    
                    <div style="background: #e0e0e0; height: 10px; border-radius: 5px; margin: 10px 0;">
                        <div style="background: #4CAF50; height: 100%; width: {completion_percentage}%; border-radius: 5px;"></div>
                    </div>
                    
                    <div style="text-align: center; margin-top: 10px;">
                        <strong style="color: #666;">Remaining Investment Needed:</strong><br>
                        <span style="font-size: 20px; font-weight: bold; color: #F44336;">ETB {remaining_investment:,.2f}</span>
                    </div>
                </div>
            """.format(
                price=float(price),
                daily_income=float(daily_income),
                total_income=float(total_income),
                sold_units=int(sold_units),
                available_units=int(available_units),
                total_units=int(total_units),
                completion_percentage=float(completion_percentage),
                remaining_investment=float(remaining_investment),
                color='#4CAF50' if completion_percentage > 50 else '#FF9800' if completion_percentage > 25 else '#F44336'
            ))
        except Exception as e:
            return format_html('<div style="color: red; padding: 10px; background: #FFEBEE; border-radius: 5px;">Error calculating summary: {}</div>', str(e))
    
    investment_summary_display.short_description = 'Investment Summary'

    actions = ['mark_as_featured', 'mark_as_sold_out', 'activate_projects']

    def mark_as_featured(self, request, queryset):
        queryset.update(is_featured=True)
    mark_as_featured.short_description = "Mark selected projects as featured"

    def mark_as_sold_out(self, request, queryset):
        queryset.update(status='sold_out', available_units=0)
    mark_as_sold_out.short_description = "Mark selected projects as sold out"

    def activate_projects(self, request, queryset):
        queryset.update(is_active=True, status='available')
    activate_projects.short_description = "Activate selected projects"





from django.contrib import admin
from django.utils import timezone
from datetime import timedelta
from django.utils.html import format_html

@admin.register(UserMainProject)
class UserMainProjectAdmin(admin.ModelAdmin):
    """Admin interface for UserMainProject model"""
    
    # Display fields in list view
    list_display = [
        'id',
        'user',
        'project_title',
        'units',
        'invested_amount',
        'purchase_date',
        'last_claim_time',
        'status',  # ADDED: Must be in list_display if in list_editable
        'status_badge',
        'remaining_days_display',
        'can_claim_display',
        'is_active_display',
    ]
    
    # Fields that can be searched
    search_fields = [
        'user__username',
        'user__email',
        'main_project__title',
        'main_project__description',
    ]
    
    # Filters for the sidebar
    list_filter = [
        'status',
        'purchase_date',
        'main_project',
        'user',
    ]
    
    # Fields that can be edited in the list view
    list_editable = ['status']
    
    # Number of items per page
    list_per_page = 25
    
    # Date hierarchy for navigation
    date_hierarchy = 'purchase_date'
    
    # Fields to display in detail view
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'profile_link')
        }),
        ('Project Information', {
            'fields': ('main_project', 'project_details')
        }),
        ('Investment Details', {
            'fields': (
                'units',
                'invested_amount',
                'purchase_date',
                'last_claim_time',
                'status',
            )
        }),
        ('Calculated Fields', {
            'fields': (
                'remaining_days',
                'is_active',
                'can_claim',
                'next_claim_time',
                'total_earned',
            ),
            'classes': ('collapse',)
        }),
    )
    
    # Read-only fields
    readonly_fields = [
        'user',
        'main_project',
        'units',
        'invested_amount',
        'purchase_date',
        'last_claim_time',
        'remaining_days',
        'is_active',
        'can_claim',
        'next_claim_time',
        'total_earned',
        'profile_link',
        'project_details',
    ]
    
    # Custom actions
    actions = [
        'mark_as_active',
        'mark_as_completed',
        'mark_as_cancelled',
        'force_claim_income',
        'reset_claim_timer',
    ]
    
    # Custom methods for list display
    def project_title(self, obj):
        return obj.main_project.title
    project_title.short_description = 'Project'
    project_title.admin_order_field = 'main_project__title'
    
    def status_badge(self, obj):
        colors = {
            'active': 'green',
            'completed': 'blue',
            'cancelled': 'red',
        }
        color = colors.get(obj.status, 'gray')
        return format_html(
            '<span style="color: white; background-color: {}; padding: 3px 8px; border-radius: 12px; font-weight: bold;">{}</span>',
            color,
            obj.status.upper()
        )
    status_badge.short_description = 'Status Badge'
    
    def remaining_days_display(self, obj):
        remaining = obj.remaining_days()
        if remaining == float('inf'):
            return '∞ (Infinite)'
        elif remaining <= 0:
            return format_html('<span style="color: red; font-weight: bold;">0 (Expired)</span>')
        elif remaining <= 3:
            return format_html('<span style="color: orange; font-weight: bold;">{} days</span>', remaining)
        else:
            return f"{remaining} days"
    remaining_days_display.short_description = 'Remaining Days'
    
    def can_claim_display(self, obj):
        if not obj.is_active():
            return format_html('<span style="color: gray;">❌ Not Active</span>')
        if obj.can_claim():
            return format_html('<span style="color: green; font-weight: bold;">✅ Ready</span>')
        
        # Calculate time until next claim
        next_claim = obj.last_claim_time + timedelta(hours=24)
        hours_until = (next_claim - timezone.now()).seconds // 3600
        minutes_until = ((next_claim - timezone.now()).seconds % 3600) // 60
        
        return format_html(
            '<span style="color: orange;">⏳ {}h {}m</span>',
            hours_until,
            minutes_until
        )
    can_claim_display.short_description = 'Can Claim'
    
    def is_active_display(self, obj):
        if obj.is_active():
            return format_html('<span style="color: green; font-weight: bold;">✅ Active</span>')
        return format_html('<span style="color: red;">❌ Inactive</span>')
    is_active_display.short_description = 'Active'
    
    # Custom methods for detail view
    def remaining_days(self, obj):
        remaining = obj.remaining_days()
        if remaining == float('inf'):
            return 'Infinite (No cycle limit)'
        return f"{remaining} days (out of {obj.main_project.cycle_days} total)"
    remaining_days.short_description = 'Remaining Cycle Days'
    
    def is_active(self, obj):
        return "Yes" if obj.is_active() else "No"
    is_active.short_description = 'Is Investment Active?'
    
    def can_claim(self, obj):
        if not obj.is_active():
            return "No - Investment is not active"
        if obj.can_claim():
            return "Yes - Ready to claim"
        
        next_claim = obj.last_claim_time + timedelta(hours=24)
        time_until = next_claim - timezone.now()
        hours = time_until.seconds // 3600
        minutes = (time_until.seconds % 3600) // 60
        
        return f"No - Next claim in {hours}h {minutes}m"
    can_claim.short_description = 'Can Claim Now?'
    
    def next_claim_time(self, obj):
        if obj.last_claim_time and obj.is_active():
            next_claim = obj.last_claim_time + timedelta(hours=24)
            return next_claim.strftime('%Y-%m-%d %H:%M:%S')
        return "N/A"
    next_claim_time.short_description = 'Next Claim Time'
    
    def total_earned(self, obj):
        """Calculate total earned from this investment"""
        if obj.last_claim_time:
            # Estimate based on days since purchase and daily income
            days_since_purchase = (timezone.now() - obj.purchase_date).days
            daily_income = obj.main_project.daily_income * obj.units
            max_days = min(days_since_purchase, obj.main_project.cycle_days) if obj.main_project.cycle_days > 0 else days_since_purchase
            estimated = daily_income * max_days
            return f"~{estimated:.2f}"
        return "0.00"
    total_earned.short_description = 'Estimated Total Earned'
    
    def profile_link(self, obj):
        url = f"/admin/auth/user/{obj.user.id}/change/"
        return format_html('<a href="{}" target="_blank">👤 View User Profile</a>', url)
    profile_link.short_description = 'User Profile'
    
    def project_details(self, obj):
        url = f"/admin/app_name/mainproject/{obj.main_project.id}/change/"
        return format_html(
            '<a href="{}" target="_blank">📊 View Project Details</a><br>'
            '<strong>Daily Income:</strong> {}<br>'
            '<strong>Cycle Days:</strong> {}<br>'
            '<strong>Total Income:</strong> {}',
            url,
            obj.main_project.daily_income,
            obj.main_project.cycle_days,
            obj.main_project.daily_income * obj.main_project.cycle_days
        )
    project_details.short_description = 'Project Information'
    
    # Custom admin actions
    def mark_as_active(self, request, queryset):
        updated = queryset.update(status='active')
        self.message_user(request, f"{updated} investments marked as active.")
    mark_as_active.short_description = "Mark selected as Active"
    
    def mark_as_completed(self, request, queryset):
        updated = queryset.update(status='completed')
        self.message_user(request, f"{updated} investments marked as completed.")
    mark_as_completed.short_description = "Mark selected as Completed"
    
    def mark_as_cancelled(self, request, queryset):
        updated = queryset.update(status='cancelled')
        self.message_user(request, f"{updated} investments marked as cancelled.")
    mark_as_cancelled.short_description = "Mark selected as Cancelled"
    
    def force_claim_income(self, request, queryset):
        successful = 0
        failed = 0
        
        for investment in queryset:
            if investment.is_active():
                income = investment.claim_income()
                if income:
                    successful += 1
                else:
                    failed += 1
            else:
                failed += 1
        
        self.message_user(
            request, 
            f"Force claim completed: {successful} successful, {failed} failed."
        )
    force_claim_income.short_description = "Force claim income (24h bypass)"
    
    def reset_claim_timer(self, request, queryset):
        updated = queryset.update(last_claim_time=None)
        self.message_user(request, f"{updated} claim timers reset.")
    reset_claim_timer.short_description = "Reset claim timer (make claimable)"
    
    # Customize the change form
    def get_readonly_fields(self, request, obj=None):
        if obj:  # Editing an existing object
            return self.readonly_fields + ['user', 'main_project', 'units', 'invested_amount', 'purchase_date']
        return self.readonly_fields
    
    # Add warning for status changes
    def save_model(self, request, obj, form, change):
        if change and 'status' in form.changed_data:
            old_status = form.initial.get('status')
            new_status = obj.status
            
            if old_status == 'completed' and new_status == 'active':
                # Warn admin about reactivating completed investment
                from django.contrib import messages
                messages.warning(
                    request,
                    f"Investment reactivated from 'completed' to 'active'. "
                    f"Check if cycle days ({obj.main_project.cycle_days}) have expired."
                )
        
        super().save_model(request, obj, form, change)



    # admin.py
from django.contrib import admin
from django.utils.html import format_html
from .models import Video

@admin.register(Video)
class VideoAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'uploaded_by', 'views', 'status', 'is_featured', 'is_published', 'created_at']
    list_filter = ['category', 'status', 'is_featured', 'is_published', 'created_at']
    search_fields = ['title', 'description', 'uploaded_by__username']
    readonly_fields = ['views', 'likes', 'dislikes', 'created_at', 'updated_at']
    list_per_page = 20
    actions = ['approve_videos', 'reject_videos', 'feature_videos', 'unfeature_videos']
    
    fieldsets = (
        ('Video Information', {
            'fields': ('title', 'description', 'category', 'duration', 'file_size')
        }),
        ('Media Files', {
            'fields': ('video_file', 'thumbnail')
        }),
        ('Status & Visibility', {
            'fields': ('status', 'is_featured', 'is_published')
        }),
        ('Statistics', {
            'fields': ('views', 'likes', 'dislikes')
        }),
        ('User Information', {
            'fields': ('uploaded_by', 'approved_by')
        }),
        ('Dates', {
            'fields': ('created_at', 'updated_at', 'published_at')
        }),
    )
    
    def save_model(self, request, obj, form, change):
        if not obj.uploaded_by_id:
            obj.uploaded_by = request.user
        if obj.status == 'approved' and not obj.approved_by_id:
            obj.approved_by = request.user
        super().save_model(request, obj, form, change)
    
    def approve_videos(self, request, queryset):
        updated = queryset.update(status='approved', approved_by=request.user)
        self.message_user(request, f'{updated} videos were approved.')
    
    def reject_videos(self, request, queryset):
        updated = queryset.update(status='rejected')
        self.message_user(request, f'{updated} videos were rejected.')
    
    def feature_videos(self, request, queryset):
        updated = queryset.update(is_featured=True)
        self.message_user(request, f'{updated} videos were marked as featured.')
    
    def unfeature_videos(self, request, queryset):
        updated = queryset.update(is_featured=False)
        self.message_user(request, f'{updated} videos were unfeatured.')
    
    approve_videos.short_description = "Approve selected videos"
    reject_videos.short_description = "Reject selected videos"
    feature_videos.short_description = "Mark as featured"
    unfeature_videos.short_description = "Remove featured status"