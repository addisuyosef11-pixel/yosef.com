from django.urls import path

from chat import views
from . import api_views  # make sure you have api_views.py in the same folder

urlpatterns = [
    path('auth/login/', api_views.login_api, name='api_login'),
    path('auth/signup/', api_views.signup_api, name='api_signup'),
    path('auth/logout/', api_views.logout_api, name='api_logout'),

    path('profile/', api_views.profile_api, name='api_profile'),
    path('balance/', api_views.balance_api, name='api_balance'),

    path('withdraw/', api_views.withdraw_api, name='api_withdraw'),
    path('withdraw-history/', api_views.withdraw_history_api, name='api_withdraw_history'),

    path('recharge/', api_views.recharge_api, name='api_recharge'),
    path('vip-packages/', api_views.vip_packages_api, name='api_vip_packages'),
    path('vip/buy/', api_views.buy_vip_api, name='api_buy_vip'),

    path('chat/', api_views.chat_api, name='api_chat'),
    path('chat/save/', api_views.save_message_api, name='api_save_message'),

    path('orders/', api_views.user_orders_api, name='api_orders'),
    path('orders/process/', api_views.process_order_api, name='api_process_order'),
    path('account_number/update/', api_views.update_account_number, name='api_update_account_number'),
    path('set_withdraw_password/', api_views.set_withdraw_password_api, name='api_set_withdraw_password'),
    path('commissions/', api_views.commissions_api, name='api_commissions'),
    
   
    path('vip/claim/', api_views.claim_vip_income_api, name='api_claim_vip_income'),
    path('invite/use/', api_views.use_invite_code, name='use_invite_code'),
    path('invite/my-code/', api_views.get_my_invite_code, name='get_my_invite_code'),
    path('gift/redeem/', api_views.redeem_gift_code, name='redeem_gift_code'),
    path('gift/info/', api_views.get_gift_code_info, name='get_gift_code_info'),
    path('main-projects/', api_views.get_main_projects, name='main-projects'),
    path('main-projects/featured/', api_views.get_featured_projects, name='featured-projects'),
    path('main-projects/available/', api_views.get_main_projects, name='available-projects'),
    path('recharge/history/',api_views.recharge_history, name='recharge_history'),
    path("payment-methods/", api_views.get_payment_methods, name="payment-methods"),
    path('user/investments/', api_views.get_user_investments, name='user-investments'),
    path('api/vips/<int:vip_id>/claim/', api_views.claim_vip_income_api, name='claim-vip-income'),
    path('api/main-projects/<int:project_id>/claim/', api_views.claim_main_project_income, name='claim-project-income'),

    

]
