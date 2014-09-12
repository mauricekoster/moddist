from shellfolders import CommonAppData
from Log import LogInfo, LogDebug, LogError, LogWarning
import os
import urllib2

mpm_version_ext = '.versieinfo'

def mpm_install_path():
  appdata = CommonAppData()
  path = os.path.join(appdata, 'mpm')
  if not os.path.exists(path):
    os.mkdir(path)

  return path

def InstallModule(module_name, url):
  print "YO!"
  LogInfo("Install module : " + module_name + " from " + url)
  mpm_path = mpm_install_path()
  the_url = url + '/' + module_name + mpm_version_ext
  fn = os.path.join(mpm_path, module_name  + mpm_version_ext)

  LogDebug( "url : " + the_url )
  LogDebug( "fn  : " + fn )

  response = urllib2.urlopen(the_url)
  print response.read()
