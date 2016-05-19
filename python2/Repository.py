import os
import ConfigParser

import UserSettings


class NoRepositories(Exception): pass


__repositories = None
__repository_default = 0
__repoindex = {}


def mpm_config_path():
    appdata = UserSettings.user_config_folder()
    path = os.path.join(appdata, 'mpm')
    if not os.path.exists(path):
        os.mkdir(path)

    return path


class Repository:
    def __init__(self, nr, name, url, host, user, password, basedir):
        self.nr = nr
        self.name = name
        self.url = url
        self.host = host
        self.user = user
        self.password = password
        self.basedir = basedir

    def __str__(self):
        if GetDefaultRepositoryNr() == self.nr:
            extra = "(*)"
        else:
            extra = "   "
        return "[%2d] %-25s %-45s%-3s" % (self.nr, self.name, self.url, extra)


def __ReadRepositoryInfo():
    """
    Internally used function.
    Used to get repository information from .ini file to internal structure.
    """

    global __repositories
    global __repository_default
    global __repoindex

    cfg = ConfigParser.ConfigParser()
    fn = os.path.join(mpm_config_path(), 'repositories.ini')
    try:
        cfg.readfp(open(fn))
    except:
        return

    host = user = passwd = ''

    try:
        host_count = int(cfg.get('Repository', 'hostcount'))
    except:
        host_count = 0

    try:
        __repository_default = int(cfg.get('Repository', 'default'))
    except:
        __repository_default = 0

    if host_count == 0:
        raise NoRepositories

    else:
        __repositories = []
        __repoindex = {}
        for i in range(host_count):
            d = {}
            d['nr'] = i + 1
            for k in ('name', 'url', 'host', 'user', 'password', 'basedir'):
                d[k] = cfg.get('Repo' + str(i + 1), k)

            __repoindex[d['name']] = len(__repositories)
            __repositories.append(
                Repository(d['nr'], d['name'], d['url'], d['host'], d['user'], d['password'], d['basedir']))


def GetDefaultRepositoryNr():
    return __repository_default


def GetDefaultRepository():
    # print __repositories
    return __repositories[__repository_default - 1]


def GetRepositories():
    return __repositories


def GetRepository(reponame):
    idx = __repoindex[reponame]
    return __repositories[idx]


if not __repositories:
    __ReadRepositoryInfo()

if __name__ == '__main__':
    if __repositories:
        for k in __repositories:
            print k
    else:
        print "No repostories found!"
