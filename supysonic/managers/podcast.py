# coding: utf-8
#
# This file is part of Supysonic.
# Supysonic is a Python implementation of the Subsonic server API.
#
# Copyright (C) 2020 Alban 'spl0k' Féron
#
# Distributed under terms of the GNU AGPLv3 license.

from datetime import datetime
from time import mktime
from urllib.parse import urlparse

from pony.orm import db_session, desc
import feedparser

from ..config import get_current_config
from ..db import PodcastChannel, PodcastEpisode, PodcastStatus


class PodcastManager:
    @staticmethod
    def fetch_feed(url):
        parsed_url = urlparse(url)

        has_scheme_and_location = parsed_url.scheme and (parsed_url.netloc or parsed_url.path)
        if not has_scheme_and_location:
            raise ValueError('unexpected url: missing schema, location or path')

        # can raise exception; let it bubble up
        feed = feedparser.parse(url)

        if feed.status != 200:
            raise Exception('http:' + feed.status)

        if feed.bozo:
            raise Exception('{}: {}'.format(feed.bozo_exception.getMessage(), feed.bozo_exception))

        if not hasattr(feed.feed, 'title'):
            raise ValueError('title missing')

        return feed

    @staticmethod
    def add_channel(url, feed):
        if url is None or feed is None:
            return

        channel = PodcastChannel(
            url=url,
            title=feed.feed.title,
            description = feed.feed.description,
        )
        image = feed.get("image")
        if image:
            channel.cover_art = image["title"]
            channel.original_image_url = image["href"]

        return channel

    @staticmethod
    def refresh_channel(channel, feed):
        if channel is None or feed is None:
            return

        for item in feed.entries:
            # NOTE: 'suffix' and 'bitrate' will be set when downloading to local file

            # skip episodes if they were published before we last fetched
            publish_date = datetime.fromtimestamp(mktime(item.published_parsed))
            if channel.last_fetched is not None and channel.last_fetched >= publish_date:
                continue

            fields = {
                'title': item.title,
                'description': item['description'],
                'year': item.published_parsed.tm_year,
                'publish_date': datetime.fromtimestamp(mktime(item.published_parsed)),
                'status': PodcastStatus.skipped.value,
            }

            audio_link = next((link for link in item.links if link.type.startswith('audio') or link.type.startswith('video')), None)
            if audio_link:
                fields['stream_url'] = audio_link.href
                fields['size'] = audio_link.length
                fields['content_type'] = audio_link.type
            else:
                fields['stream_url'] = '::missing::'
                fields['status'] = PodcastStatus.error.value
                fields['error_message'] = 'Media link not found in episode xml'

            if item['itunes_duration']:
                fields['duration'] = item.itunes_duration

            if feed.feed['image'] and feed.feed.image['href']:
                fields['cover_art'] = feed.feed.image.href

            if feed.feed['tags']:
                fields['genre'] = ",".join([tag['term'] for tag in feed.feed.tags])

            # only create if this record doesn't exist
            existing_episode = PodcastEpisode.get(
                channel=channel,
                title=fields['title'],
                stream_url=fields['stream_url']
            )
            if existing_episode is None:
                channel.episodes.create(**fields)

        # check maximum number of episodes
        config = get_current_config()
        retention_count = config.PODCAST['episode_retention_count']
        top_newest = channel.episodes.select().order_by(desc(PodcastEpisode.publish_date))
        ids = [ep.id for ep in top_newest]

        if len(ids) > retention_count:
            top_ids = ids[:retention_count]
            PodcastEpisode.select(lambda ep: ep.id not in top_ids).delete()

        channel.last_fetched = datetime.now()
