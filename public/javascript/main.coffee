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

window.VIDEO_LENGTH_MS = 1000  # The length of time that the snippets are recorded  # TODO make longer after testing

class window.FirebaseInteractor
  """Connects to Firebase and connects to chatroom variables."""
  constructor: ->
    @fb_instance = new Firebase("https://proto1-cs247-p3-fb.firebaseio.com")

  init: =>
    # set up variables to access firebase data structure
    @fb_chat_room_id = window.get_fb_chat_room_id()
    @fb_new_chat_room = @fb_instance.child('chatrooms').child(@fb_chat_room_id)
    @fb_instance_users = @fb_new_chat_room.child('users')
    @fb_instance_stream = @fb_new_chat_room.child('stream')
    @fb_user_video_list = @fb_new_chat_room.child('user_video_list')


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
    console.log "videos: "
    console.log @videos

  addUser: (username) =>
    if username of @videos
      return
    @videos[username] = []

  storePushedFb: (pushedFb, quickId) =>
    @fbResults[quickId] = pushedFb  # Store a mapping
    console.log quickId
    console.log @fbResults

  removeVideoSnapshot: (data) =>
    if data.fromUser not of @videos
      return
    @videos[data.fromUser] =
    @videos[data.fromUser] = _.reject @videos[data.fromUser], (item) =>
      return item.quickId == data.quickId
    console.log "((((((((( VIDEO REMOVED! videos: ))))))))) "
    console.log @videos
    console.log data

  getRandomVideo: =>
    allVideos = _.flatten(_.values(@videos)) # One list of all the videos
    if _.isEmpty(allVideos)
      console.error "Cannot get random video URL, no videos exist"
      return undefined
    return _.sample(allVideos)


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

  constructor: (@elem, @emotionVideoStore) ->
    $("#make_memory_button").on("click", @randomlyMakeMemory)

  randomlyMakeMemory: =>
    console.log "randomly making memory"
    context =
      panels: []
    for panelIndex in ["first", "second", "third", "fourth"]
      chosenVideo = @emotionVideoStore.getRandomVideo()
      console.log "got a random memory"
      context.panels.push({"video": chosenVideo, "panelIndex": panelIndex})
    console.log "html: "
    Templates["memoryBuilder"](context)
    console.log $("#memory_builder_container")
    $("#memory_builder_container").html(Templates["memoryBuilder"](context))
    console.log context


class window.ChatRoom
  """Main class to control the chat room UI of messages and video"""
  constructor: (@fbInteractor, @videoRecorder) ->
    context = []
    $("#entire_memory_wrapper").html(Templates["memoryWrapper"](context))
    @lastPoster = null
    @backgroundColor = "#ffddc7"
    @emotionVideoStore = new EmotionVideoStore()
    @messageBefore = ""
    @memoryBuilder = new MemoryBuilder($("#memory_builder_container"), @emotionVideoStore)

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

    @fbInteractor.fb_user_video_list.on "child_removed", (snapshot) =>
      @emotionVideoStore.removeVideoSnapshot(snapshot.val())

    @submissionEl = $("#submission input")

  init: =>
    url = document.location.origin+"/#"+@fbInteractor.fb_chat_room_id
    @displayMessage({m: "Share this url with your friend to join this chat: <a href='" + url + "' target='_blank'>" + url+"</a>", c: "darkred"})
    # Block until user name entered
    if not @username
      @username = "anonymous"+Math.floor(Math.random()*1111)
    @userColor = "#"+((1<<24)*Math.random()|0).toString(16) # Choose random color

    @fbInteractor.fb_instance_users.push({ name: @username,c: @userColor})
    $("#waiting").remove()
    @setupSubmissionBox()

  setupSubmissionBox: =>
    # bind submission box
    $("#submission input").on "keydown", (event) =>
      if event.which == 13  # ENTER
        message = @submissionEl.val()
        messageWithUser = @username + ": " + message
        console.log(message)
        emoticon = EmotionProcessor.getEmoticon(message)
        if emoticon
          videoToPush =
            fromUser: @username
            c: @userColor
            v: @videoRecorder.curVideoBlob
            emoticon: emoticon
            messageCurrent: messageWithUser
            messageBefore: @messageBefore
            quickId: Math.floor(Math.random()*1111)
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
      #chatElem.scrollTop = chatElem.scrollHeight
      $("html,body").animate({ scrollTop: $(document).height() }, 200)
      return
    setTimeout =>
      #chatElem.scrollTop = chatElem.scrollHeight
      $("html,body").animate({ scrollTop: $(document).height() }, 200)
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
        if @backgroundColor == "#f8ede6"
          @backgroundColor = "#ffddc7"
        else @backgroundColor = "#f8ede6"
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


# Start everything!
$(document).ready ->
  fbInteractor = new FirebaseInteractor()
  fbInteractor.init()
  videoRecorder = new VideoRecorder()
  chatRoom = new ChatRoom(fbInteractor, videoRecorder)
  chatRoom.init()
  videoRecorder.connectWebcam()



