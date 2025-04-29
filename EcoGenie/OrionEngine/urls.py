from django.urls import path
from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path("sudip/", views.sudip, name="sudip"),  # Specific path first
    path("index.html/", views.home, name= "home"),
    path("aboutus.html/", views.aboutus, name="aboutus"),
    # path("<str:name>/", views.greet, name="greet")  # General pattern last
]
