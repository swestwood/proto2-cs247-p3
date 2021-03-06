# Initial code by Borui Wang, updated by Graham Roth,
# refactored and converted to Coffeescript by Sophia Westwood.
#
# Compile by running coffee -wc *.coffee to generate main.js and compile other .coffee files in the directory.
# For CS247, Spring 2014


# Drawn from http://en.wikipedia.org/wiki/List_of_emoticons
window.EMOTICON_MAP =
  "angry": [">:(", ">_<"]  # Sort roughly so that the full emoticon is captured, ie ">:(" does not first match ":("
  "crying": [":'-(", ":'("]
  "surprise": [">:O", ":-O", ":O", ":-o", ":o", "8-0", "O_O", "o-o", "O_o", "o_O", "o_o", "O-O"]
  "tongue": [">:P", ":-P", ":P", "X-P", "x-p", "xp", "XP", ":-p", ":p", "=p", ":-b", ":b", "d:"]
  "laughing": [":-D", ":D", "8-D", "8D", "x-D", "xD", "X-D", "XD", "=-D", "=D", "=-3", "=3"]
  "happy": [":-)", ":)", ":o)", ":]", ":3", ":c)", ":>", "=]", "8)", "=)", ":}"]
  "sad": [">:[", ":-(", ":(", ":-c", ":c", ":-<", ":<", ":-[", ":[", ":{"]
  "wink": [";-)", ";)", "*-)", "*)", ";-]", ";]", ";D", ";^)", ":-,"]
  "uneasy": [">:\\", ">:/", ":-/", ":-.", ":/", ":\\", "=/", "=\\", ":L", "=L", ":S", ">.<"]
  "expressionless": [":|", ":-|"]
  "embarrassed": [":$"]
  "secretive": [":-X", ":X"]
  "heart": ["<3"]
  "broken": ["</3"]

window.VIDEO_LENGTH_MS = 3000  # The length of time that the snippets are recorded  # TODO make longer after testing

class window.FirebaseInteractor
  """Connects to Firebase and connects to chatroom variables."""
  constructor: ->
    @fb_instance = new Firebase("https://proto2-cs247-p3-fb.firebaseio.com")

  init: =>
    # set up variables to access firebase data structure
    @fb_chat_room_id = window.get_fb_chat_room_id()
    @fb_new_chat_room = @fb_instance.child('chatrooms').child(@fb_chat_room_id)
    @fb_instance_users = @fb_new_chat_room.child('users')
    @fb_instance_stream = @fb_new_chat_room.child('stream')
    @fb_user_video_list = @fb_new_chat_room.child('user_video_list')
    @fb_memory = @fb_new_chat_room.child('memory')
    @fb_memories = @fb_instance.child('memories')

  initMemoryVersion: =>
    @fb_memories = @fb_instance.child('memories')


class window.EmotionVideoStore
  """Stores a map from each user to a list of that user's emotion videos"""

  constructor: ->
    @videos = {}
    @fbResults = {}  # Store the result of pushing on the data so that we can remove it later

  addVideoSnapshot: (data) =>
    if data.fromUser not of @videos
      @videos[data.fromUser] = []
    data.videoUrl = URL.createObjectURL(BlobConverter.base64_to_blob(data.v))
    @videos[data.fromUser].push(data)

  addUser: (username) =>
    if username of @videos
      return
    @videos[username] = []

  storePushedFb: (pushedFb, quickId) =>
    @fbResults[quickId] = pushedFb  # Store a mapping

  removeVideoSnapshot: (data) =>
    if data.fromUser not of @videos
      return
    @videos[data.fromUser] =
    @videos[data.fromUser] = _.reject @videos[data.fromUser], (item) =>
      return item.quickId == data.quickId

  sampleRandomVideos: (sampleSize) =>
    allVideos = _.flatten(_.values(@videos)) # One list of all the videos
    if _.isEmpty(allVideos)
      console.error "Cannot get random video URL, no videos exist"
      return undefined
    sampled = _.sample(allVideos, sampleSize)
    while _.size(sampled) < sampleSize
      sampled.push(_.sample(allVideos))  # Add on random videos until we have enough videos, if there are fewer than sampleSize total.
    return sampled

  removeVideoItem: (video, fb_video_list) =>
    if video.quickId not of @fbResults
      return
    pushedFb = @fbResults[video.quickId]
    if _.isUndefined(pushedFb)
      delete @fbResults[video.quickId]
      return
    pushedFb.remove()
    delete @fbResults[video.quickId]  # Remove from storing locally
    # Will be removed from local video store in the callback after deleting from Firebase.

class window.MemoryBuilder

  constructor: (@elem, @emotionVideoStore, @fbInteractor) ->
    @elem.html(Templates["memoryBuilder"]({"waitingForVideo": true}))
    $("#make_memory_button").on("click", @randomlyMakeMemory)


  randomlyMakeMemory: =>
    console.log "randomly making memory"
    context =
      panels: []
    panelNames = ["first", "second", "third", "fourth"]
    effects = ["sepia", "brightness", "highcontrast", "highsaturate", "huerotate", "tint", "", "invert"]
    chosenVideos = @emotionVideoStore.sampleRandomVideos(_.size(panelNames))
    chosenEffects = _.sample(effects, _.size(panelNames))
    for panelI in [0..._.size(panelNames)]
      chosenVideo = chosenVideos[panelI]
      context.panels.push({"video": chosenVideo, "panelIndex": panelNames[panelI], "effect": chosenEffects[panelI]})
    memoryId = "memory-" +  _.sample(window.listOfAdjectives) + "-" + _.sample(window.listOfAnimals)  + "-" + _.random(1, 1000)
    savedMemory = @fbInteractor.fb_memories.child(memoryId)
    savedMemoryContext = savedMemory.child("context")
    savedMemoryContext.set(context)
    context.memoryUrl = document.location.origin+"/#&" + memoryId
    $("#memory_builder_container").html(Templates["memoryBuilder"](context))
    $("#keep_memory_link").html("Keep this memory forever: " + "<a href=" + context.memoryUrl + " target='_blank'>" + context.memoryUrl + "</a>")
    $("#make_memory_button").on("click", @randomlyMakeMemory)
    console.log context.memoryUrl
    @fbInteractor.fb_memory.set(context)
    console.log context

  respondToSetMemory: (context) =>
    console.log "respondToSetMemory"
    console.log context.memoryUrl
    for panel in context.panels
      panel.video.videoUrl = URL.createObjectURL(BlobConverter.base64_to_blob(panel.video.v))  # Make a new local URL for the video to show up
    $("#memory_builder_container").html(Templates["memoryBuilder"](context))
    $("#make_memory_button").on("click", @randomlyMakeMemory)




class window.ChatRoom
  """Main class to control the chat room UI of messages and video"""
  constructor: (@fbInteractor, @videoRecorder) ->
    context = []
    $("#entire_memory_wrapper").html(Templates["memoryWrapper"](context))
    @lastPoster = null
    @backgroundColor = "#a7dae7"
    @emotionVideoStore = new EmotionVideoStore()
    @messageBefore = ""
    @memoryBuilder = new MemoryBuilder($("#memory_builder_container"), @emotionVideoStore, @fbInteractor)

    # Listen to Firebase events
    @fbInteractor.fb_instance_users.on "child_added", (snapshot) =>
      @displayMessage({m: " joined the room", c: snapshot.val().c, u: snapshot.val().name, j: "joined"})
      @emotionVideoStore.addUser(snapshot.val().name)

    @fbInteractor.fb_instance_stream.on "child_added", (snapshot) =>
      msg = snapshot.val().m
      username = msg.substr(0, msg.indexOf(":"))
      spliced_message = msg.substr(msg.indexOf(":") + 1)
      @displayMessage({m: spliced_message, c: snapshot.val().c, u: username})

    @fbInteractor.fb_user_video_list.on "child_added", (snapshot) =>
      @emotionVideoStore.addVideoSnapshot(snapshot.val())
      $("#make_memory_button").css({"visibility": "visible"})
      $("#make_memory_button").on("click", @randomlyMakeMemory)
      $(".instructions-memory").hide()

    @fbInteractor.fb_user_video_list.on "child_removed", (snapshot) =>
      @emotionVideoStore.removeVideoSnapshot(snapshot.val())

    @fbInteractor.fb_memory.on "value", (snapshot) =>
      if not snapshot or not snapshot.val()
        return
      @memoryBuilder.respondToSetMemory(snapshot.val())

    @submissionEl = $("#submission input")

  init: =>
    url = document.location.origin+"/#"+@fbInteractor.fb_chat_room_id
    @displayMessage({m: "Share this url with your friend to join this chat: <a href='" + url + "' target='_blank'>" + url+"</a>", c: "darkred", s: "share"})
    # Block until user name entered
    @username = window.prompt("Welcome! What's your name?")  # Commented out for faster testing.
    if not @username
      @username = "anonymous"+Math.floor(Math.random()*1111)
    @userColor = "#"+((1<<24)*Math.random()|0).toString(16) # Choose random color
    @userColor = @userColor.substr(0,1) + '3' + @userColor.substr(2)
    @userColor = @userColor.substr(0,3) + '3' + @userColor.substr(4)

    @fbInteractor.fb_instance_users.push({ name: @username,c: @userColor})
    $("#waiting").remove()
    @setupSubmissionBox()

  setupSubmissionBox: =>
    # bind submission box
    $("#submission input").on "keydown", (event) =>
      if event.which == 13  # ENTER
        message = @submissionEl.val()

        messageWithUser = @username + ": " + message
        console.log messageWithUser
        emoticon = EmotionProcessor.getEmoticon(message)
        if emoticon
          videoToPush =
            fromUser: @username
            c: @userColor
            v: @videoRecorder.curVideoBlob
            emoticon: emoticon
            messageCurrent: messageWithUser
            messageBefore: @messageBefore
            quickId: _.random(1, 1000000)
          pushedFb = @fbInteractor.fb_user_video_list.push()
          pushedFb.set(videoToPush)
          # We need to store the name so that we can retrieve it and remove the video
          # from the video list later on
          @emotionVideoStore.storePushedFb(pushedFb, videoToPush.quickId)
        @fbInteractor.fb_instance_stream.push
          m: messageWithUser
          c: @userColor
        @submissionEl.val("")

  scrollToBottom: (wait_time) =>
    # scroll to bottom of div
    chatElem = document.getElementById('conversation')
    if wait_time == 0
      chatElem.scrollTop = chatElem.scrollHeight
      # $("html,body").animate({ scrollTop: $(document).height() }, 200)
      return
    setTimeout =>
      chatElem.scrollTop = chatElem.scrollHeight
      # $("html,body").animate({ scrollTop: $(document).height() }, 200)
    , wait_time

  createVideoElem: (video_data) =>
    # for gif instead, use this code below and change mediaRecorder.mimeType in onMediaSuccess below
    # var video = document.createElement("img")
    # video.src = URL.createObjectURL(BlobConverter.base64_to_blob(data.v))

    # for video element
    video = document.createElement("video")
    video.autoplay = true
    video.controls = false # optional
    video.loop = true
    video.width = 120

    source = document.createElement("source")
    source.src =  URL.createObjectURL(BlobConverter.base64_to_blob(video_data))
    source.type =  "video/webm"
    return [source, video]

  # creates a message node and appends it to the conversation
  displayMessage: (data) =>
    @messageBefore = data.m
    changePoster = false
    if @lastPoster == null
      @lastPoster = data.u
    else
      if (@lastPoster != data.u)
        @lastPoster = data.u
        if @backgroundColor == "#d8a2ee"
          @backgroundColor = "#a7dae7"
        else @backgroundColor = "#d8a2ee"
        changePoster = true
    if changePoster
      if data.j == "joined"
        # poster just joined the room
        newHeader = $("<div class='msg' style='color:"+data.c+"'>"+data.u+data.m+"</div>")
        newMessage = null
      else
        newHeader = $("<div class='msg' style='color:"+data.c+"'>"+data.u+"</div>")
        newMessage = $("<div class='msgtext' style='color:"+data.c+"'>"+data.m+"</div>")
    else 
      newHeader = null
      newMessage = $("<div class='msgtext' style='color:"+data.c+"'>"+data.m+"</div>")
    
    if newHeader != null
      newHeader.css("font-weight", "bold")
      newHeader.css("font-style", "16px")
      newHeader.css("background-color", @backgroundColor)
      $("#conversation").append(newHeader)
    if newMessage != null
      newMessage.css("background-color", @backgroundColor)
      $("#conversation").append(newMessage)
    if data.v
      [source, video] = @createVideoElem(data.v)
      video.appendChild(source)
      document.getElementById("conversation").appendChild(video)
    # Scroll to the bottom every time we display a new message
    @scrollToBottom(0);

class StandAloneMemory

  constructor: (@memoryId, @fbInteractor) ->
    @memoryItem = @fbInteractor.fb_instance.child('memories').child(@memoryId).child("context")
    if not @memoryItem
      console.error "memory item not found.. "
      $("body").html("<h3>Sorry, memory could not be found</h3>")
      return

    @memoryItem.on "value", (snapshot) =>
      context = snapshot.val()
      console.log context
      if not context
        $("body").html("<h3>Sorry, this memory could not be found. Check the URL. Or make a new memory!</h3>")
        return
      for panel in context.panels
        panel.video.videoUrl = URL.createObjectURL(BlobConverter.base64_to_blob(panel.video.v))
      context.standalone = true
      $("body").html(Templates["memoryWrapper"]())
      $("#memory_builder_container").html(Templates["memoryBuilder"](context))


# Start everything!
$(document).ready ->
  fbInteractor = new FirebaseInteractor()
  memoryId = window.get_memory_id()
  if memoryId
    $("#waiting").remove()
    fbInteractor.initMemoryVersion()
    standAloneMemory = new StandAloneMemory(memoryId, fbInteractor)
  else
    fbInteractor.init()
    videoRecorder = new VideoRecorder()
    chatRoom = new ChatRoom(fbInteractor, videoRecorder)
    chatRoom.init()
    videoRecorder.connectWebcam()



