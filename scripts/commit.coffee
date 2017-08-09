# Description
#    한국시간(KST) 기준 오전 8시 30분이 되면 등록된 사용자들의 커밋 횟수를 알려준다.
#
# Dependencies:
#    "cheerio"
#    "http"
#    "cron"
#
# Author:
#    Hun Jae Lee (@hunj)
#
# Reference:
#   https://github.com/github/hubot-scripts/blob/master/src/scripts/github-commiters.coffee

cheerio = require 'cheerio'
cronJob = require('cron').CronJob
github = require("githubot")(robot)
github_base_url = process.env.HUBOT_GITHUB_API || 'https://api.github.com'

timeZone = "Asia/Seoul"

module.exports = (robot) ->
  fb = new FirebaseUtil(robot, "brain")

  # 유저 추가하기
  robot.hear /!유저추가 (.*)/i, (msg) ->
    addUser(msg, msg.match[1])

  robot.respond /커밋로그 (.*)$/i, (msg) ->
    read_contributors msg, (commits) ->

          max_length = commits.length
          max_length = 20 if commits.length > 20
          for commit in commits
            msg.send "[#{commit.login}] #{commit.contributions}"
            max_length -= 1
            return unless max_length

  robot.respond /repo top-commiters? (.*)$/i, (msg) ->
      read_contributors msg, (commits) ->
          top_commiter = null
          for commit in commits
            top_commiter = commit if top_commiter == null
            top_commiter = commit if commit.contributions > top_commiter.contributions
          msg.send "[#{top_commiter.login}] #{top_commiter.contributions} :trophy:"

  read_contributors = (msg, response_handler) ->
      repo = github.qualified_repo msg.match[1]
      base_url = process.env.HUBOT_GITHUB_API || 'https://api.github.com'
      url = "#{base_url}/repos/#{repo}/contributors"
      github.get url, (commits) ->
        if commits.message
          msg.send "Achievement unlocked: [NEEDLE IN A HAYSTACK] repository #{commits.message}!"
        else if commits.length == 0
          msg.send "Achievement unlocked: [LIKE A BOSS] no commits found!"
        else
          if process.env.HUBOT_GITHUB_API
            base_url = base_url.replace /\/api\/v3/, ''
          msg.send "#{base_url}/#{repo}"
          response_handler commits



module.exports = (robot) ->
	new cronJob('0 0 20 * * *', sendMessageMethod(robot), null, true, timeZone)
	new cronJob('0 0 22 * * *', sendMessageMethod(robot), null, true, timeZone)
	new cronJob('0 50 23 * * *', sendMessageMethod(robot), null, true, timeZone)

sendMessageMethod = (robot) ->
    -> sendMessage(robot)

sendMessage = (robot) ->
  for username, last_commit_time in commit_list
    robot.messageRoom '#commit', "@#{username}, 오늘 커밋 했어?"

  robot.http(targetUrl).get() (err, res, body) ->
      $ = cheerio.load(body)
      title = $('.dotd-title').text()
      title = title.replace /\n|\t/g, ""

# `!유저추가 <유저명>` 에 들어온 유저명을 깃허브에 존재하는지 확인하고
# 유저목록에 추가한다.
addUser = (msg, username) ->
  # 깃허브에 유저명이 존재하는지 확인한다.
  robot.http("https://api.github.com/users/#{username}/events/public")
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      if res.status is "OK"


      data = JSON.parse body
      res.send "#{data.passenger} taking midnight train going #{data.destination}"


  fb.push(username).then ->

greetNewUser = (robot) ->
  robot.respond /커밋로그 (.*)$/i, (msg) ->
  robot.enter (res) ->
    if res.message.user.room is 'commit'
      robot.messageRoom "#commit", ":commit_fairy: @#{res.message.user.name} 님 어서오세요! `커밋 등록 <깃허브 유저명>`으로 커밋로그 트래킹을 시작해주세요."
