from .models import UserIPLog

def log_user_ip(request):
    if request.user.is_authenticated:
        ip = get_client_ip(request)
        endpoint = request.path

        ipv4 = None
        ipv6 = None

        if ":" in ip:
            ipv6 = ip
        else:
            ipv4 = ip

        UserIPLog.objects.create(
            user=request.user,
            ipv4_address=ipv4,
            ipv6_address=ipv6,
            endpoint=endpoint
        )

def get_client_ip(request):
    """Helper to extract client IP address, even behind proxies."""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip
