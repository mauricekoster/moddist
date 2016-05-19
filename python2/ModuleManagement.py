# ModuleManagement.py
import urllib2
import logging

logger = logging.getLogger(__name__)


class Module:
    def __init__(self, name, description, url):
        self.name = name
        self.description = description
        self.url = url


def get_module_list(url):
    logger.info("start get_module_list")
    data = urllib2.urlopen(url + '/module_list.txt')
    lines = data.read().split('\n')[2:]
    ret = []
    for line in lines:
        l = line.split('|')
        m = Module(l[0], l[1], l[2])
        ret.append(m)
    return ret
