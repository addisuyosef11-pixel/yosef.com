from django import forms
from django.contrib.auth import get_user_model

User = get_user_model()

class SignupForm(forms.ModelForm):
    password = forms.CharField(widget=forms.PasswordInput)

    class Meta:
        model = User
        fields = ['username', 'email', 'password']  # corrected fields
    def clean_email(self):
        email = self.cleaned_data['email']
        if User.objects.filter(email=email).exists():
            raise forms.ValidationError("Email is already registered.")
        return email


class LoginForm(forms.Form):
    username = forms.CharField(
        max_length=150,
        widget=forms.TextInput(attrs={
            "class": "form-control",
            "placeholder": "Enter your username"
        })
    )
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={
            "class": "form-control",
            "placeholder": "Enter your password"
        })
    )


class TransactionForm(forms.Form):
    BANK_CHOICES = [
        ('cbe', 'CBE'),
        ('telebirr', 'Telebirr'),
        ('abay', 'Abay Bank'),
        ('dashen', 'Dashen Bank'),
    ]

    amount = forms.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=0.01,
        widget=forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'Enter amount'}),
        label='Amount'
    )
    bank = forms.ChoiceField(
        choices=BANK_CHOICES,
        widget=forms.Select(attrs={'class': 'form-control'}),
        label='Bank'
    )
    account_number = forms.CharField(
        required=False,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Account Number'}),
        label='Account Number'
    )
    phone_number = forms.CharField(
        required=False,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Phone Number'}),
        label='Phone Number'
    )

    def clean(self):
        cleaned_data = super().clean()
        bank = cleaned_data.get('bank')
        account_number = cleaned_data.get('account_number')
        phone_number = cleaned_data.get('phone_number')

        if bank == 'telebirr':
            if not phone_number:
                self.add_error('phone_number', 'Phone number is required for Telebirr.')
        else:
            if not account_number:
                self.add_error('account_number', 'Account number is required for banks.')







class OTPForm(forms.Form):
    otp = forms.CharField(
        max_length=6,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter OTP'
        }),
        label='One Time Password'
    )

  

 
from django import forms

class ContactForm(forms.Form):
    name = forms.CharField(max_length=100, label="Your Name")
    phone = forms.CharField(max_length=20, label="Your Phone Number")
    message = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 4}),
        label="Your Message",
        max_length=1000
    )


# dog/cat/forms.py
from django import forms
from .models import Message

class MessageForm(forms.ModelForm):
    class Meta:
        model = Message
        fields = ['content']
        widgets = {
            'content': forms.Textarea(attrs={
                'rows': 2,
                'placeholder': 'Type your message...',
                'class': 'form-control'
            }),
        }



from django import forms
from django.contrib.auth.models import User
from .models import Profile  # Adjust the import to match your project

class UserSettingsForm(forms.ModelForm):
    class Meta:
        model = Profile
        fields = ['phone', 'address', 'profile_image']
        widgets = {
            'phone': forms.TextInput(attrs={'class': 'form-control'}),
            'address': forms.TextInput(attrs={'class': 'form-control'}),
            'profile_image': forms.FileInput(attrs={'class': 'form-control'}),
        }

# users/forms.py
from django import forms
from .models import Profile

class ProfileForm(forms.ModelForm):
    class Meta:
        model = Profile
        fields = ['avatar', 'coins', 'gold', 'vip']  # adjust fields as needed
