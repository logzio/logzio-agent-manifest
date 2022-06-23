import os, requests, json, sys

url = 'https://app.logz.io/telemetry-agent/public/manifest/validate'

with open("manifest.json", mode='r', encoding='utf-8') as f:
  manifest = json.load(f)

  response = requests.post(url, json = manifest)

isValid = response.json()['valid']

if isValid != True:
  message = (response.json()['message'])
  sys.exit(message)