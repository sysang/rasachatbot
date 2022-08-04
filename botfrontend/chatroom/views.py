import re

from django.conf import settings
from django.shortcuts import render
from django.template.response import TemplateResponse

from services.booking_service import request_room_list_by_hotel


def index(request):
    response = TemplateResponse(request, 'chatroom/index.html', {'socketUrl': settings.BASE_DOMAIN_URL})

    return response

def room_photos(request):
    hotel_id = request.GET.get('hotel_id')
    room_id = request.GET.get('room_id')
    images = []

    room_list = request_room_list_by_hotel(hotel_id=hotel_id)

    if len(room_list) > 0:
        room_list = room_list[0].get('rooms', {})
        room = room_list.get(room_id)

        if room:
            for photo in room.get('photos', []):
                photo_url = photo.get('url_original')
                if photo_url:
                    images.append(photo_url)

    return TemplateResponse(request, 'chatroom/room_photos.html', {'images': images})
