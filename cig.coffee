module.exports = (robot) ->
    robot.respond /debbie$/i, (msg) ->
        msg.send "http://memecrunch.com/meme/1F11V/womp-womp/image.png"
