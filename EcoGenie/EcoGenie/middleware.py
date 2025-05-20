class RemoveServerHeaderMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        # Strip identifying headers
        response.headers.pop('Server', None)
        response.headers.pop('X-Powered-By', None)

        return response
