from django.shortcuts import render

def home(request):
    return render(request, 'archapp/index.html')

def masonry(request):
    return render(request, 'archapp/masonry.html')

def grid(request):
    return render(request, 'archapp/grid.html')

def about(request):
    return render(request, 'archapp/about.html')

def blog(request):
    return render(request, 'archapp/blog.html')

def single_post(request):
    return render(request, 'archapp/single-post.html')