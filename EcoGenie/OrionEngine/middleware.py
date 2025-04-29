from .utils import log_user_ip

class LogUserIPMiddleware:
    """
    Middleware to log IP address and endpoint for authenticated users.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        # Log only if authenticated and it's not an admin panel request
        if request.user.is_authenticated and not request.path.startswith('/admin/'):
            try:
                log_user_ip(request)
            except Exception as e:
                # Avoid crashing even if logging fails
                print(f"IP logging failed: {e}")
        return response
