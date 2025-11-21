# middleware.py
class ReferralMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        ref = request.GET.get("refcode")
        if ref:
            request.session["refcode"] = ref
        return self.get_response(request)
