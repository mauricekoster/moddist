import urllib.request
url="http://www.mauricekoster.com/Modules/module_list.txt"
response = urllib.request.urlopen(url)
text = response.read().decode('utf-8')

print(text)
