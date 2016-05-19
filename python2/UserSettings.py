''' Opvragen van de gebruiker settings directory '''
import os
import sys
import tempfile
from os.path import expanduser

xdg_dirs = {}

if sys.platform == 'Win32':
    import registry

    __common_shellfolders = registry.readValues('HKLM',
                                                r'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders')
    __personal_shellfolders = registry.readValues('HKCU',
                                                  r'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders')


    def CommonAppData():
        return __common_shellfolders['Common AppData']


    def MyDocuments():
        return __personal_shellfolders['Personal']


    def user_temp_folder():
        return os.environ['TEMP']


    def user_desktop():
        return __personal_shellfolders['Desktop']


    def user_application_data_folder():
        return __personal_shellfolders['AppData']


    def user_config_folder():
        return __personal_shellfolders['Local AppData']

elif sys.platform == 'linux2':
    # return XDG desktop compliant directories
    # source: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    homedir = os.environ['HOME']
    dirs = {}
    if os.path.exists(os.path.join(homedir, '.config', 'user-dirs.dirs')):
        execfile(os.path.join(homedir, '.config', 'user-dirs.dirs'), dirs)
        xdg_dirs = dict((key, value) for key, value in dirs.iteritems() if key.startswith('XDG'))


    def common_data_folders():
        if 'XDG_DATA_DIRS' in os.environ:
            d = os.environ['XDG_DATA_DIRS']
        else:
            d = '/usr/local/share/:/usr/share/'
        return d.split(':')


    def user_documents_folder():
        if 'XDG_DOCUMENTS_DIR' in dirs:
            return dirs['XDG_DOCUMENTS_DIR'].replace('$HOME', homedir)
        else:
            return os.path.join(homedir, 'Documents')


    def user_desktop():
        if 'XDG_DESKTOP_DIR' in dirs:
            return dirs['XDG_DESKTOP_DIR'].replace('$HOME', homedir)
        else:
            return os.path.join(homedir, 'Desktop')


    def user_config_folder():
        folder = os.path.join(homedir, '.config')
        if 'XDG_CONFIG_HOME' in os.environ:
            folder = os.environ['XDG_CONFIG_HOME']

        return folder


    def user_data_folder():
        folder = os.path.join(homedir, '.local', 'share')
        if 'XDG_DATA_HOME' in os.environ:
            folder = os.environ['XDG_DATA_HOME']

        return folder


    def user_temp_folder():
        return tempfile.gettempdir()

if __name__ == '__main__':
    print 'User config folder: %s' % user_config_folder()
    print 'User data folder: %s' % user_data_folder()
    print "Common data folders: %s" % common_data_folders()
    print "My Documents: %s" % user_documents_folder()
    print "My Desktop: %s" % user_desktop()
    print "Temporary folder: %s" % user_temp_folder()