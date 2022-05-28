import os
import logging
from requests import post

from tinydb import Query
import arrow
from arrow import Arrow

from .dbconnector import db


logger = logging.getLogger(__name__)

DUCKLING_BASE_URL = os.environ['RASA_DUCKLING_HTTP_URL']
PARSING_URL = DUCKLING_BASE_URL + '/parse'

def duckling_parse(expression, dim):
  """
  r = post('http://duckling:8000/parse', data={"locale": "en_GB", "text": "3 days"})
  r.json()
  # [{'body': '3 days', 'start': 0, 'value': {'value': 3, 'day': 3, 'type': 'value', 'unit': 'day', 'normalized': {'value': 259200, 'unit': 'second'}}, 'end': 6, 'dim': 'duration', 'latent': False}]
  """
  _expression = expression.replace('night', 'day')
  _expression = _expression.replace('nights', 'days')
  data = {
        'locale': 'en_US',
        'text': _expression,
        'dims': [dim]
      }
  r = post(PARSING_URL, data=data)
  r.raise_for_status()

  logger.info('[INFO] duckling_parse, expression: %s, dimention: %s, result: %s', expression, dim, r.text)

  return r.json()[0]


# def extract_date(time_obj: dict) -> str:
#   """
#     Because duckling returns inconsisten format due to dramatic variation of its input
#     We need extra step to regularize the date value:
#       1) Expression has absent year, say "May 21st", the value attribute is a dict instead of a str
#   """

#   # Handle 1)
#   if isinstance(time_obj['value'], dict):
#     return time_obj['value']['value']
#   else:
#     return time_obj['value']


def query_available_rooms(area, room_type, checkin_time, duration):
  logger.info('[INFO] querying parameter: (%s, %s, %s, %s)', area, room_type, checkin_time, duration)
  DATE_FORMAT = 'YYYY-MM-DD'

  parsed_checkin_time = duckling_parse(expression=checkin_time, dim='time')
  parsed_checkin_time = parsed_checkin_time['value']['value']
  parsed_duration = duckling_parse(expression=duration, dim='duration')
  parsed_duration = parsed_duration['value']['value']

  arrobj_now = arrow.now()
  arrobj_checkin = arrow.get(parsed_checkin_time)
  if arrobj_now.timestamp() > arrobj_checkin.timestamp():
    return []

  arrobj_checkout = arrobj_checkin.shift(days=parsed_duration - 1)

  booked_dates = []
  for r in arrow.Arrow.range('day', arrobj_checkin, arrobj_checkout):
    booked_dates.append(r.format(DATE_FORMAT))

  logger.info('[INFO] booked_dates: %s', str(booked_dates))

  RoomQuery = Query()
  rooms = db.search((RoomQuery.area==area) & (RoomQuery.room_type==room_type))

  logger.info('[INFO] Found %s room in %s', len(rooms), area)

  available = []
  for room in rooms:
    if all([date not in room['occupied_dates'] for date in booked_dates]):
      available.append(room)

  return available

