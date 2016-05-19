from UserSettings import user_data_folder
import logging
import os
import urllib2

logger = logging.getLogger(__name__)
mpm_version_ext = '.mpm'


def mpm_install_path():
    appdata = user_data_folder()
    path = os.path.join(appdata, 'mpm')
    if not os.path.exists(path):
        os.mkdir(path)

    return path

def _message(arr):
    logger.info(':'.join(arr[1:]))


def install_module(module_name, url):
    logger.info("Install module '%s' from '%s'", module_name, url)
    mpm_path = mpm_install_path()
    the_url = url + '/' + module_name + mpm_version_ext
    fn = os.path.join(mpm_path, module_name + mpm_version_ext)

    logger.debug("url : " + the_url)
    logger.debug("fn  : " + fn)

    response = urllib2.urlopen(the_url)

    lines = response.read().split('\n')

    if not lines[0].startswith('# MPM'):
        logger.warning('no valid mpm file found')
        return False

    for line in lines:
        arr = line.split(':')
        if line.startswith('#'):
            continue
        if line.strip():
            if arr[0] == 'message':
                _message(arr)

            else:
                logger.warning('unhandled: ' + line)

    return True
