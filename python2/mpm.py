# mpm.py
import sys
from Repository import GetRepositories, GetDefaultRepository
from ModuleManagement import GetModuleList

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
	print "List"
	print "=" * 60
	modules = GetModuleList(url)

	print "=" * 60
	if modules:
		for module in modules:
			print " %-20s %-30s" % (module.name, module.description)
	else:
		print "No modules"

	print "=" * 60

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
		if sys.argv[2]=='list':
			repo = GetDefaultRepository()
			modulelist(repo.url)

	else:
		print "Huh?"
