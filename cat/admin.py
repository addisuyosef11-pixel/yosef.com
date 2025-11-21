from django.contrib import admin
from django.db.models import Sum
from .models import (
    Profile, Task, Transaction, Balance, Investment, Withdrawal,
    VIP, UserVIP, CustomerMessage, OTP, Message, Order, PaymentProof,
    Commission, Bank
)

# =======================
# PROFILE ADMIN
# =======================
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'vip_level', 'get_invite_code', 'get_inviter', 'coins', 'gold')
    search_fields = ('user__username', 'invite_code')
    list_filter = ('vip_level',)

    def get_invite_code(self, obj):
        return obj.invite_code
    get_invite_code.short_description = "Invite Code"

    def get_inviter(self, obj):
        return obj.inviter.username if obj.inviter else "-"
    get_inviter.short_description = "Inviter"


# =======================
# TASK ADMIN
# =======================
@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('name', 'description', 'price', 'min_vip_level', 'active', 'priority', 'created_at')
    list_filter = ('active', 'min_vip_level')
    search_fields = ('name', 'description')
    ordering = ('-created_at',)


# =======================
# TRANSACTION ADMIN
# =======================
@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('customer_display', 'type', 'amount', 'status', 'bank', 'date')
    list_filter = ('type', 'status', 'bank', 'date')
    search_fields = ('customer__username', 'account_number', 'phone_number')
    ordering = ('-date',)

    def customer_display(self, obj):
        return obj.customer.username
    customer_display.short_description = "Customer"


# =======================
# BALANCE ADMIN
# =======================
@admin.register(Balance)
class BalanceAdmin(admin.ModelAdmin):
    list_display = ('customer_display', 'amount', 'updated_at')
    search_fields = ('customer__username',)
    ordering = ('-updated_at',)

    def customer_display(self, obj):
        return obj.customer.username
    customer_display.short_description = "Customer"


# =======================
# WITHDRAWAL ADMIN
# =======================
@admin.register(Withdrawal)
class WithdrawalAdmin(admin.ModelAdmin):
    list_display = ('user_display', 'amount', 'status', 'date_requested')
    list_filter = ('status', 'date_requested')
    search_fields = ('user__username',)
    ordering = ('-date_requested',)

    def user_display(self, obj):
        return obj.user.username
    user_display.short_description = "User"


# =======================
# VIP ADMIN
# =======================
@admin.register(VIP)
class VIPAdmin(admin.ModelAdmin):
    list_display = ('title', 'price', 'daily_income', 'income_days', 'upgrade', 'total_earning_display')
    search_fields = ('title',)
    ordering = ('upgrade',)

    def total_earning_display(self, obj):
        return obj.total_earning()
    total_earning_display.short_description = "Total Earning"


# =======================
# USERVIP ADMIN
# =======================
@admin.register(UserVIP)
class UserVIPAdmin(admin.ModelAdmin):
    list_display = ('user_display', 'vip', 'invested', 'last_claim_time', 'can_claim_display')
    search_fields = ('user__username',)
    ordering = ('-last_claim_time',)

    def user_display(self, obj):
        return obj.user.username
    user_display.short_description = "User"

    def can_claim_display(self, obj):
        return obj.can_claim()
    can_claim_display.boolean = True
    can_claim_display.short_description = "Can Claim?"


# =======================
# INVESTMENT ADMIN
# =======================
@admin.register(Investment)
class InvestmentAdmin(admin.ModelAdmin):
    list_display = ('customer_display', 'amount', 'invested_on', 'daily_profit_rate', 'calculated_profit')
    list_filter = ('invested_on',)
    ordering = ('-invested_on',)

    def customer_display(self, obj):
        return obj.customer.user.username
    customer_display.short_description = "Customer"

    def calculated_profit(self, obj):
        return f"{obj.calculate_profit():.2f}"
    calculated_profit.short_description = "Calculated Profit"


# =======================
# OTP ADMIN
# =======================
@admin.register(OTP)
class OTPAdmin(admin.ModelAdmin):
    list_display = ('user_display', 'otp_code', 'is_verified', 'created_at', 'expires_at')
    list_filter = ('is_verified',)
    search_fields = ('user__username',)

    def user_display(self, obj):
        return obj.user.username
    user_display.short_description = "User"


# =======================
# CUSTOMER MESSAGE ADMIN
# =======================
@admin.register(CustomerMessage)
class CustomerMessageAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'created_at')
    readonly_fields = ('created_at',)
    search_fields = ('name', 'phone')


# =======================
# MESSAGE ADMIN
# =======================
class ReplyInline(admin.TabularInline):
    model = Message
    extra = 1
    fk_name = "parent"

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('sender', 'short_content', 'timestamp', 'parent')
    list_filter = ('timestamp',)
    search_fields = ('sender', 'content')
    ordering = ('-timestamp',)
    inlines = [ReplyInline]

    def short_content(self, obj):
        return obj.content[:50] + ('...' if len(obj.content) > 50 else '')
    short_content.short_description = "Message Preview"


# =======================
# ORDER & PAYMENT PROOF ADMIN
# =======================
@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'customer_display', 'total_amount', 'payment_method', 'is_paid', 'created_at')
    list_filter = ('payment_method', 'is_paid')
    search_fields = ('customer__username',)

    def customer_display(self, obj):
        return obj.customer.username
    customer_display.short_description = "Customer"


@admin.register(PaymentProof)
class PaymentProofAdmin(admin.ModelAdmin):
    list_display = ('order', 'transaction_id', 'verified', 'submitted_at')
    list_filter = ('verified',)
    actions = ['mark_as_verified']

    def mark_as_verified(self, request, queryset):
        for proof in queryset:
            proof.verified = True
            proof.order.is_paid = True
            proof.order.save()
            proof.save()
        self.message_user(request, "Selected payments marked as verified.")


# =======================
# COMMISSION ADMIN
# =======================
@admin.register(Commission)
class CommissionAdmin(admin.ModelAdmin):
    list_display = ('user_display', 'level', 'amount', 'created_at')
    list_filter = ('level', 'created_at')
    search_fields = ('user__username',)
    ordering = ('-created_at',)
    actions = ['calculate_total_commission']

    def user_display(self, obj):
        return obj.user.username
    user_display.short_description = "User"

    @admin.action(description="Calculate total commissions")
    def calculate_total_commission(self, request, queryset):
        report = queryset.values("user__username").annotate(total=Sum("amount"))
        for r in report:
            self.message_user(request, f"{r['user__username']}: ${r['total']}")


# =======================
# BANK ADMIN
# =======================
@admin.register(Bank)
class BankAdmin(admin.ModelAdmin):
    list_display = ('name', 'account_name', 'account_number', 'branch')


# =======================
# ADMIN SITE BRANDING
# =======================
admin.site.site_header = "Trust Investment Admin Panel"
admin.site.site_title = "Trust Investment Admin"
admin.site.index_title = "Welcome to the Admin Dashboard"







