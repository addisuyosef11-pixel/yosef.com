



from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from .models import Profile, Balance, Recharge, InviteReward
import random

# ---------------------------------
# Create Profile and Balance on User creation
# ---------------------------------
@receiver(post_save, sender=User)
def create_profile_and_balance(sender, instance, created, **kwargs):
    if created:
        # Create Profile
        profile = Profile.objects.create(user=instance)

        # Generate 6-digit invite code for this user
        profile.invite_code = ''.join(random.choices("0123456789", k=6))
        profile.save()

        # Create Balance
        Balance.objects.create(customer=instance)

# Ensure Profile is saved whenever User is saved
@receiver(post_save, sender=User)
def save_profile(sender, instance, **kwargs):
    if hasattr(instance, 'profile'):
        instance.profile.save()


