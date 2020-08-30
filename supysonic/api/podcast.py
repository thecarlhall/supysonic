# coding: utf-8
#
# This file is part of Supysonic.
# Supysonic is a Python implementation of the Subsonic server API.
#
# Copyright (C) 2020 Alban 'spl0k' Féron
#
# Distributed under terms of the GNU AGPLv3 license.

from datetime import datetime
import os

from flask import request
from pony.orm import db_session
from pony.orm.core import TransactionIntegrityError

from ..db import PodcastChannel, PodcastEpisode, PodcastStatus
from ..managers.podcast import PodcastManager

from . import api, get_entity, require_podcast
from .exceptions import Forbidden, MissingParameter, NotFound


@api.route("/getPodcasts.view", methods=["GET", "POST"])
def get_podcasts():
    include_episodes, channel_id = map(request.values.get, ["includeEpisodes", "id"])

    if channel_id:
        channels = (get_entity(PodcastChannel),)
    else:
        channels = PodcastChannel \
            .select(lambda chan: chan.status != PodcastStatus.deleted.value) \
            .sort_by(PodcastChannel.title)

    return request.formatter(
        "podcasts",
        dict(channel=[ch.as_subsonic_channel(include_episodes) for ch in channels]),
    )


@api.route("/createPodcastChannel.view", methods=["GET", "POST"])
@require_podcast
def create_podcast_channel():
    url = request.values["url"]

    channel = PodcastChannel.get(url=url)
    if channel is not None:
        return request.formatter.error(0, 'podcast with that url already exists')

    try:
        feed = PodcastManager.fetch_feed(url)
        channel = PodcastManager.add_channel(url, feed)
    except ValueError as ve:
        return request.formatter.error(10, str(ve))
    except Exception as ex:
        return request.formatter.error(0, str(ex))

    try:
        PodcastManager.refresh_channel(channel, feed)
        return request.formatter.empty
    except Exception as ex:
        channel.status = PodcastStatus.error.value
        channel.error_message = str(ex)
        return request.formatter.error(0, str(ex))


@api.route("/deletePodcastChannel.view", methods=["GET", "POST"])
@require_podcast
def delete_podcast_channel():
    res = get_entity(PodcastChannel)
    res.soft_delete()

    return request.formatter.empty


@api.route("/deletePodcastEpisode.view", methods=["GET", "POST"])
@require_podcast
def delete_podcast_episode():
    res = get_entity(PodcastEpisode)
    res.soft_delete()

    return request.formatter.empty

