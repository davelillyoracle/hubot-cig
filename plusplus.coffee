# Description:
#   Give or take away points. Keeps track and even prints out graphs.
#
# Dependencies:
#   "underscore": ">= 1.0.0"
#   "clark": "0.0.6"
#
# Configuration:
#
# Commands:
#   <name>++ - add points to a user
#   <name>-- - subtract points from a user
#   hubot scores - get the leaderboard
#   hubot reset - (admin only) reset the scoreboard
#
# Author:
#   davelilly!

users = [ 'dave lilly', 'brian celenza', 'rich meyer', 'johnny crivello' ]
nicknames = {}

_ = require("underscore")
clark = require("clark")

class ScoreKeeper
  constructor: (@robot) ->
    for name in users
      nicknames[name] = name

      # first name
      nicknames[name.split(" ")[0]] = name

      # last name
      nicknames[name.split(" ")[1]] = name

      # firstlast name
      nicknames[name.replace(" ", "")] = name

      # first initial last name
      nicknames[name.slice(0, 1) + name.split(" ")[1]] = name

      # first initial last initial
      nicknames[name.slice(0, 1) + name.split(" ")[1].slice(0, 1)] = name

    @cache =
      scoreLog: {}
      scores: {}

    @robot.brain.on 'loaded', =>
      @robot.brain.data.scores ||= {}
      @robot.brain.data.scoreLog ||= {}

      @cache.scores = @robot.brain.data.scores
      @cache.scoreLog = @robot.brain.data.scoreLog

  clear: ->
      @robot.brain.data.scores = {}
      @robot.brain.data.scoreLog = {}

      @cache.scores = @robot.brain.data.scores
      @cache.scoreLog = @robot.brain.data.scoreLog    

      for name in users
        @getUser(name)

  getUser: (nick) ->
    user = nicknames[nick]
    @cache.scores[user] ||= 0
    user

  saveUser: (user, from) ->
    @saveScoreLog(user, from)
    @robot.brain.data.scores[user] = @cache.scores[user]
    @robot.brain.data.scoreLog[from] = @cache.scoreLog[from]
    @robot.brain.emit('save', @robot.brain.data)

    @cache.scores[user]

  add: (user, from, numpoints) ->
    if @validate(user, from)
      user = @getUser(user)
      @cache.scores[user] = parseInt(@cache.scores[user]) + parseInt(numpoints)
      @saveUser(user, from)

  subtract: (user, from, numpoints) ->
    if @validate(user, from)
      user = @getUser(user)
      @cache.scores[user] = parseInt(@cache.scores[user]) - parseInt(numpoints)
      @saveUser(user, from)

  scoreForUser: (user) -> 
    user = @getUser(user)
    @cache.scores[user]

  saveScoreLog: (user, from) ->
    unless typeof @cache.scoreLog[from] == "object"
      @cache.scoreLog[from] = {}

    @cache.scoreLog[from][user] = new Date()

  isSpam: (user, from) ->
    @cache.scoreLog[from] ||= {}

    if !@cache.scoreLog[from][user]
      return false

    dateSubmitted = @cache.scoreLog[from][user]

    date = new Date(dateSubmitted)
    messageIsSpam = date.setSeconds(date.getSeconds() + 30) > new Date()

    if !messageIsSpam
      delete @cache.scoreLog[from][user] #clean it up

    messageIsSpam

  validate: (user, from) ->
    user != from && user != "" && !@isSpam(user, from)

  length: () ->
    @cache.scoreLog.length

  scores: ->
    scores = []

    for name, score of @cache.scores
      scores.push(name: name.split(" ")[0], score: score)

    scores.sort((a,b) -> b.score - a.score)

  username: (nick) ->
    nicknames[nick]

  shortname: (nick) ->
    nicknames[nick].split(" ")[0]

module.exports = (robot) ->
  scoreKeeper = new ScoreKeeper(robot)

  robot.hear /([\w\S]+)([\W\s]*)?(\+\+)([0-9]*)$/i, (msg) ->
    name = msg.match[1].trim().toLowerCase()
    from = msg.message.user.name.toLowerCase()
    numpoints = 1

    if (msg.match[4].length > 0)
      numpoints = parseInt(msg.match[4])

    newScore = scoreKeeper.add(name, from, numpoints)

    if newScore? then msg.send "#{scoreKeeper.shortname(name)} has #{newScore} points."

  robot.hear /([\w\S]+)([\W\s]*)?(\-\-)([0-9]*)$/i, (msg) ->
    name = msg.match[1].trim().toLowerCase()
    from = msg.message.user.name.toLowerCase()
    numpoints = 1

    if (msg.match[4].length > 0)
      numpoints = parseInt(msg.match[4])

    newScore = scoreKeeper.subtract(name, from, numpoints)

    if newScore? then msg.send "#{scoreKeeper.shortname(name)} has #{newScore} points."

  robot.respond /scores/i, (msg) ->
    scores = scoreKeeper.scores()

    scorelist = []
    message = []
    for own place, val of scores
      message.push("#{parseInt(place) + 1}. #{val['name']} (#{val['score']} points)")
      scorelist.push(val)

    message.splice(0, 0, clark(_.pluck(scorelist, "score"), scores.length))
    msg.send message.join("\n")

  robot.respond /reset/i, (msg) ->
    from = msg.message.user.name.toLowerCase()

    if (from == "dave lilly")
      scoreKeeper.clear()
      msg.send('Scores cleared.')
