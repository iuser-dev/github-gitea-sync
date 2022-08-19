#!/usr/bin/env coffee

> zx/globals:
  fs > existsSync
  os > homedir
  path > join
  await-sleep:sleep

{GITEA_TOKEN} = process.env

GITEA_URL = 'https://git.iuser.link/api/v1/'

errlog = (err, ...args)=>
  console.trace()
  console.error err
  for i from args
    console.error i
  return

fjson = (url, opt)=>
  console.log url
  n = 5
  loop
    try
      return (await fetch(url,opt)).json()
    catch err
      if --n
        errlog err,url
        sleep 3000
      else
        throw err

gitea_post = (url,data)=>
  console.log '>',url, data
  r = await fetch(
    url
    method: 'POST'
    body: JSON.stringify data
    headers:
      'content-type': 'application/json'
      authorization: 'token '+GITEA_TOKEN
  )
  if r.status != 200
    console.log r.status, r.statusText
  r.text()

sync = (kind, github_user, gitea_user)=>
  gitea_user = gitea_user or github_user

  exist = new Map()
  for {name, ssh_url} from await fjson GITEA_URL+"#{kind}s/#{gitea_user}/repos"
    exist.set(name,ssh_url)

  github_url = "https://api.github.com/#{kind}s/#{github_user}/repos?type=public&per_page=1000"
  for {ssh_url, name} from await fjson github_url
    if not exist.has name
      console.log name
      url = GITEA_URL+kind+'/'
      if kind == 'org'
        url += "#{gitea_user}/"
      console.log await gitea_post(url+'repos', {name})
  # curl -k -X POST "https://<gitea-url>/api/v1/org/<organization>/repos" -H "content-type: application/json" -H "Authorization: token 45647956a7434b47c04b47c69579fb0123456789" --data '{"name":"<repo-name>"}'

  [
    github_user
    exist
  ]

sync_li = (kind, args)=>
  args = args.split(' ')
  Promise.all (sync(kind, ...i.split(':')) for i from args)

HOMEDIR = homedir()

for [github_user, map] from await sync_li 'org','iuser-dev:dev iuser-link:iuser'
  dir = join HOMEDIR, github_user
  await $"mkdir -p #{dir}"
  cd dir
  for [git, ssh] from map.entries()
    if not existsSync git
      await $"git clone git@github.com:#{github_user}/#{git}.git"

process.exit()
