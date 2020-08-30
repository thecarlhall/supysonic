# coding: utf-8
#
# This file is part of Supysonic.
# Supysonic is a Python implementation of the Subsonic server API.
#
# Copyright (C) 2020 Alban 'spl0k' Féron
#
# Distributed under terms of the GNU AGPLv3 license.

import logging
import os, os.path
from datetime import datetime, timedelta
from time import mktime
from threading import Thread, Event
import traceback

import feedparser
from pony.orm import db_session, commit
from pony.orm.core import TransactionIntegrityError

from .config import get_current_config
from .db import PodcastChannel, PodcastEpisode, PodcastStatus
from .managers.podcast import PodcastManager

logger = logging.getLogger(__name__)

class Stats(object):
    def __init__(self):
        self.channels = 0
        self.episodes = 0
        self.errors = []
        self.state = PodcastStatus.new.name

class Fetcher(Thread):
    def __init__(
        self,
        force=False,
    ):
        super(Fetcher, self).__init__()

        self.config = get_current_config()
        #self.interval_hours = 24
        #self.episode_retention_count = 100
        #self.episode_download_count = 10
        #self.episode_folder = None

        self.__force = force
        self.__stats = Stats()

    @db_session
    def run(self):
        self.__stats.state = PodcastStatus.downloading.name

        if self.__force:
            channels = PodcastChannel.select()
        else:
            channels = PodcastChannel.select(
                lambda pc: pc.last_fetched is None or pc.last_fetched <= (datetime.now() - timedelta(hours=self.config['check_interval']))
            )

        self.__stats.channels += len(channels)
        for channel in channels:
            error_message = None
            channel.status = PodcastStatus.downloading.value
            try:
                self.fetch_podcast(channel)
                channel.status = PodcastStatus.completed.value
                self.__stats.channels += 1
            except Exception as ex:
                channel.status = PodcastStatus.error.value
                channel.error_message = str(ex)
                self.__stats.errors.append(ex)

        self.__stats.state = PodcastStatus.completed.name

    def fetch_podcast(self, channel):
        print("Fetching", channel.url)

        # fetch the channel.url
        feed = PodcastManager.fetch_feed(channel.url)
        PodcastManager.refresh_channel(channel, feed)
        self.__stats.episodes += len(feed.entries)


    def stats(self):
        return self.__stats
