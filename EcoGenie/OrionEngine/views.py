from django.http import HttpResponse
from django.shortcuts import render

# Create your views here.
def index(request):
    return render(request, "OrionEngine/index.html")

def home(request):
    return render(request, "OrionEngine/index.html")

def aboutus(request):
    return render(request, "OrionEngine/aboutus.html")

def sudip(request):
    return HttpResponse("Hello, Sudip")

# def greet(request, name):
#     return HttpResponse(f"Hello, {name.capitalize()}!")
