from django.core.management.base import BaseCommand
from cat.models import Investment, Transaction, Balance
from django.utils import timezone

class Command(BaseCommand):
    help = 'Generate daily profit for all investments'

    def handle(self, *args, **kwargs):
        today = timezone.now().date()
        for investment in Investment.objects.all():
            days = (today - investment.invested_on.date()).days
            if days > 0:
                profit = investment.calculate_profit()
                Transaction.objects.create(
                    customer=investment.customer,
                    amount=profit,
                    type='profit'
                )
                balance, created = Balance.objects.get_or_create(customer=investment.customer)
                balance.update_balance()
        self.stdout.write(self.style.SUCCESS('Daily profits generated.'))
