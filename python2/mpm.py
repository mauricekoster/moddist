# mpm.py
import sys
from Repository import GetRepositories, GetDefaultRepository
from ModuleManagement import GetModuleList
from ModuleInstaller import InstallModule

def main():
	print "Hello"

def repolist():
	repolist = GetRepositories()

	print "Repository name(s):"
	print " Nr  %-25s %-45s%-3s" % ( "Name", "URL", "Def" )
	print '=' * 79
	if repolist:
		for repoinfo in repolist:
			print repoinfo
	else:
		print "No repositories defined!"
	print '=' * 79

def modulelist(url):
	print "Module list"
	print "=" * 60
	print "%-20s %-30s" % ("Name", "Description")
	modules = GetModuleList(url)

	print "-" * 60
	if modules:
		for module in modules:
			print "%-20s %-30s" % (module.name, module.description)
	else:
		print "*** No modules found ***"

	print "=" * 60

def moduleinstall(name, url):
	modules = GetModuleList(url)
	for m in modules:
		if m.name.lower() == name.lower():
			InstallModule(m.name, url + m.url)
			return
	print "No module %s found." % name

if __name__ == '__main__':
	argc = len(sys.argv) - 1

	if not argc:
		main()
		sys.exit(0)

	if sys.argv[1]=='repo':
		if sys.argv[2]=='list':
			repolist()

		else:
			print "Huh?"

	elif sys.argv[1]=='module':
		repo = GetDefaultRepository()
		if sys.argv[2]=='list':
			modulelist(repo.url)
		elif sys.argv[2]=='install':
			if len(sys.argv)<4:
				print "Invalid number of arguments!\nUsage: mpm module install <name>"
			else:
				moduleinstall(sys.argv[3], repo.url)
	else:
		print "Huh?"
