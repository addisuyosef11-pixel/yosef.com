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

    
    path('vip-packages/', api_views.vip_packages_api, name='api_vip_packages'),
    path('vip/buy/', api_views.buy_vip_api, name='api_buy_vip'),

    path('chat/', api_views.chat_api, name='api_chat'),
    path('chat/save/', api_views.save_message_api, name='api_save_message'),
    path('vip/claim/', api_views.claim_vip_income, name='claim_vip'),
    path('orders/', api_views.user_orders_api, name='api_orders'),
    path('orders/process/', api_views.process_order_api, name='api_process_order'),
    path('account_number/update/', api_views.update_account_number, name='api_update_account_number'),
    path('set_withdraw_password/', api_views.set_withdraw_password_api, name='api_set_withdraw_password'),
    path('commissions/', api_views.commissions_api, name='api_commissions'),
    
    
   
    path('invite/use/', api_views.use_invite_code, name='use_invite_code'),
    path('invite/my-code/', api_views.get_my_invite_code, name='get_my_invite_code'),
    path('gift/redeem/', api_views.redeem_gift_code, name='redeem_gift_code'),
    path('gift/info/', api_views.get_gift_code_info, name='get_gift_code_info'),
    path('main-projects/', api_views.get_main_projects, name='main-projects'),
    path('main-projects/invest/', api_views.invest_in_project, name='invest-in-main-project'),
    path('main-projects/featured/', api_views.get_featured_projects, name='featured-projects'),
    path('main-projects/available/', api_views.get_main_projects, name='available-projects'),
    path('recharge/history/',api_views.recharge_history, name='recharge_history'),
    path("payment-methods/", api_views.get_payment_methods, name="payment-methods"),
    path('user/investments/', api_views.get_user_investments, name='user-investments'),
    path('api/vips/<int:vip_id>/claim/', api_views.claim_vip_income_api, name='claim-vip-income'),
    path('main-projects/claim/', api_views.claim_main_project_income, name='claim-project-income'),
    path('api/team/members/', api_views.get_team_members, name='get-team-members'),
    path('api/team/invite/', api_views.send_invitation, name='send-invitation'),
    path('api/team/commissions/', api_views.get_commission_history, name='get-commission-history'),
    path('api/team/stats/', api_views.get_team_stats, name='get-team-stats'),
    path('api/team/share/', api_views.share_referral_link, name='share-referral-link'),
    path('chat/', api_views.chat_api, name='chat_api'),
    path('chat/save/', api_views.save_message_api, name='save_message_api'),
    path('chat/delete/<int:message_id>/', api_views.delete_message_api, name='delete_message_api'),







    path('videos/', api_views.video_list, name='video-list'),
    path('videos/<int:pk>/', api_views.video_detail, name='video-detail'),

    # ==========================
    # VIDEO INTERACTIONS
    # ==========================
    path('videos/<int:pk>/views/', api_views.increment_views, name='video-views'),
    path('videos/<int:pk>/like/', api_views.like_video, name='video-like'),
    path('videos/<int:pk>/dislike/', api_views.dislike_video, name='video-dislike'),

    # ==========================
    # UPLOAD
    # ==========================
    path('videos/upload/', api_views.upload_video, name='video-upload'),

    # ==========================
    # ADMIN ACTIONS
    # ==========================
    path('admin/videos/<int:pk>/approve/', api_views.approve_video, name='video-approve'),
    path('admin/videos/<int:pk>/reject/', api_views.reject_video, name='video-reject'),
    path('admin/videos/<int:pk>/feature/', api_views.feature_video, name='video-feature'),
    path('admin/videos/<int:pk>/unfeature/',api_views.unfeature_video, name='video-unfeature'),
    

]
