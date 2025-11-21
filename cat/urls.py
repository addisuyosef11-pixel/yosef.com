from django.urls import path
from . import api_views

urlpatterns = [
    path('auth/login/', api_views.login_api, name='api_login'),
    path('auth/signup/', api_views.signup_api, name='api_signup'),
    path('auth/verify-otp/', api_views.verify_otp_api, name='api_verify_otp'),
    path('auth/resend-otp/', api_views.resend_otp_api, name='api_resend_otp'),

    path('profile/', api_views.profile_api, name='api_profile'),
    path('profile/edit/', api_views.edit_profile_api, name='api_edit_profile'),

    path('balance/', api_views.balance_api, name='api_balance'),
    path('withdraw/', api_views.withdraw_api, name='api_withdraw'),
    path('withdraw/history/', api_views.withdraw_history_api, name='api_withdraw_history'),

    path('vip/packages/', api_views.vip_packages_api, name='api_vip_packages'),
    path('vip/buy/', api_views.buy_vip_api, name='api_buy_vip'),
    path('vip/claim/', api_views.claim_vip_income_api, name='api_claim_vip_income'),

    path('transactions/', api_views.transactions_api, name='api_transactions'),
    path('transactions/export/', api_views.export_transactions_api, name='api_export_transactions'),

    path('chat/', api_views.chat_api, name='api_chat'),
    path('notifications/', api_views.notifications_api, name='api_notifications'),

    path('task/', api_views.task_api, name='api_task'),
    path('daily-income/', api_views.daily_income_api, name='api_daily_income'),
    path('invest/', api_views.invest_api, name='api_invest'),
    path('dashboard/', api_views.dashboard_api, name='api_dashboard'),
    path('commissions/', api_views.commissions_api, name='api_commissions'),
    path('api/account_number/update/', api_views.update_account_number, name='api_update_account_number'),
    path('set_withdraw_password/', api_views.Set_Withdraw_Password_api, name='api_set_withdraw_password'),
]
