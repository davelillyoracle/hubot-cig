# Commands:
# hubot womp - Womp womp

module.exports = (robot) ->
    robot.respond /womp$/i, (msg) ->
        msg.send "http://memecrunch.com/meme/1F11V/womp-womp/image.png"
