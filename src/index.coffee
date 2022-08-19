#!/usr/bin/env coffee

{GITEA_TOKEN} = process.env

GITEA_URL = 'https://git.iuser.link/api/v1/'

fjson = (url, opt)=>
  console.log url
  (await fetch(url,opt)).json()

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

  return

sync_li = (kind, args)=>
  args = args.split(' ')
  Promise.all (sync(kind, ...i.split(':')) for i from args)

#"https://api.github.com/orgs/iuser-dev/repos?type=public"


#await sync_li 'user','i-user-link:iuser.link'
await sync_li 'org','iuser-dev:dev iuser-link:iuser'
#console.log 'End'
#process.exit()
