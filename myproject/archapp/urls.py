from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='index'),
    path('about/', views.about, name='about'),
    path('masonry/', views.masonry, name='masonry'),
    path('blog/', views.blog, name='blog'),
    path('grid/', views.grid, name='grid'),
    path('post/', views.single_post, name='single_post'),
]