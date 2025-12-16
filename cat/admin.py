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

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'phone', 'vip_level', 'balance', 
                   'available_balance', 'points', 'inviter_link')
    list_filter = ('vip_level',)
    search_fields = ('user__username', 'phone', 'invite_code')
    readonly_fields = ('invite_code', 'balance', 'available_balance', 'user_link')
    fieldsets = (
        ('User Information', {
            'fields': ('user_link', 'phone', 'address', 'avatar')
        }),
        ('Financial Information', {
            'fields': ('balance', 'available_balance', 'points', 'account_number')
        }),
        ('VIP & Referral', {
            'fields': ('vip_level', 'inviter_link', 'invite_code')
        }),
    )
    
    def user_link(self, obj):
        url = reverse('admin:cat_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.username)
    user_link.short_description = 'User'
    
    def inviter_link(self, obj):
        if obj.inviter:
            url = reverse('admin:cat_user_change', args=[obj.inviter.id])
            return format_html('<a href="{}">{}</a>', url, obj.inviter.username)
        return "None"
    inviter_link.short_description = 'Inviter'


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


# =======================
# USER VIP ADMIN
# =======================

@admin.register(UserVIP)
class UserVIPAdmin(admin.ModelAdmin):
    list_display = ('user', 'vip', 'invested', 'last_claim_time', 'can_claim_display')
    list_filter = ('vip', 'last_claim_time')
    search_fields = ('user__username', 'vip__title')
    
    # Don't include can_claim_display in readonly_fields by default
    readonly_fields = ('last_claim_time',)
    
    def get_readonly_fields(self, request, obj=None):
        # Only show can_claim_display when editing an existing object
        if obj:  # obj exists (edit view)
            return self.readonly_fields + ('can_claim_display',)
        return self.readonly_fields  # add view
    
    def can_claim_display(self, obj):
        # Safe implementation with try-except
        try:
            if obj and hasattr(obj, 'can_claim'):
                if obj.can_claim():
                    return format_html('<span style="color: green; font-weight: bold;">READY</span>')
                return format_html('<span style="color: red;">NOT READY</span>')
        except Exception as e:
            return format_html(f'<span style="color: orange;">Error: {str(e)[:50]}</span>')
        return format_html('<span style="color: gray;">N/A</span>')
    
    can_claim_display.short_description = 'Claim Status'


# =======================
# INVESTMENT ADMIN
# =======================


@admin.register(Investment)
class InvestmentAdmin(admin.ModelAdmin):
    list_display = ('customer', 'invested_on', 'amount', 'daily_profit_rate', 
                    'calculate_profit_display')
    list_filter = ('invested_on',)
    search_fields = ('customer__user__username',)
    readonly_fields = ('invested_on', 'calculate_profit_display')
    
    def calculate_profit_display(self, obj):
        try:
            profit = obj.calculate_profit()
        except TypeError:
            profit = 0  # fallback if amount or daily_profit_rate is None
        return f"ETB {profit:,.2f}"
    
    calculate_profit_display.short_description = 'Current Profit'


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
from django.utils.html import format_html
from django.urls import reverse
from .models import PaymentMethod

@admin.register(PaymentMethod)
class PaymentMethodAdmin(admin.ModelAdmin):
    list_display = [
        'name',
        'get_payment_type_display',
        'account_number',
        'get_status_display',
        'is_active',
        'priority',
        'min_amount',
        'max_amount',
        'action_buttons',  # Fixed: renamed from 'actions'
    ]
    
    list_filter = ['payment_type', 'status', 'is_active', 'created_at']
    search_fields = ['name', 'account_name', 'account_number', 'bank_name', 'phone_number']
    list_editable = ['priority', 'is_active']
    ordering = ['priority', '-created_at']
    
    # CORRECT: actions is a list attribute
    actions = ['activate_selected', 'deactivate_selected', 'export_to_csv']
    
    # CORRECT: Renamed method to avoid conflict with actions attribute
    def action_buttons(self, obj):
        # Use the correct URL pattern name
        # Format: 'admin:{app_label}_{model_name}_change'
        url = reverse('admin:cat_paymentmethod_change', args=[obj.id])
        return format_html(
            '<a href="{}" class="btn btn-sm btn-info">Edit</a>',
            url
        )
    action_buttons.short_description = 'Actions'
    
    # Custom admin actions
    def activate_selected(self, request, queryset):
        queryset.update(is_active=True, status='active')
        self.message_user(request, f"Activated {queryset.count()} payment method(s).")
    activate_selected.short_description = "Activate selected"
    
    def deactivate_selected(self, request, queryset):
        queryset.update(is_active=False, status='inactive')
        self.message_user(request, f"Deactivated {queryset.count()} payment method(s).")
    deactivate_selected.short_description = "Deactivate selected"
    
    def export_to_csv(self, request, queryset):
        import csv
        from django.http import HttpResponse
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="payment_methods.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'Name', 'Type', 'Account Name', 'Account Number',
            'Bank', 'Phone', 'Min Amount', 'Max Amount',
            'Status', 'Active', 'Priority', 'Processing Time'
        ])
        
        for obj in queryset:
            writer.writerow([
                obj.name,
                obj.get_payment_type_display(),
                obj.account_name,
                obj.account_number,
                obj.bank_name or '',
                obj.phone_number or '',
                obj.min_amount,
                obj.max_amount,
                obj.get_status_display(),
                'Yes' if obj.is_active else 'No',
                obj.priority,
                obj.processing_time
            ])
        
        self.message_user(request, f"Exported {queryset.count()} payment methods to CSV")
        return response
    export_to_csv.short_description = "Export to CSV"
    
    # Form field configuration
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'name',
                'payment_type',
                'icon',
                ('is_active', 'status'),
                'priority',
            )
        }),
        ('Account Details', {
            'fields': (
                'account_name',
                'account_number',
                'bank_name',
                'branch',
                'phone_number',
            )
        }),
        ('Payment Configuration', {
            'fields': (
                ('min_amount', 'max_amount'),
                'processing_time',
                'instructions',
            )
        }),
        ('QR Code', {
            'fields': ('qr_code',),
            'classes': ('collapse',),
        }),
    )
    
    # Optional: Add help text
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        form.base_fields['priority'].help_text = 'Higher number = displayed first'
        form.base_fields['icon'].help_text = 'FontAwesome icon class (e.g., fa-bank, fa-mobile-alt, fa-wallet)'
        return form