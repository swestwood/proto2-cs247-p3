# Initial code by Borui Wang, updated by Graham Roth,
# refactored and converted to Coffeescript by Sophia Westwood.
#
# Compile by running coffee -wc main.coffee to generate main.js
# For CS247, Spring 2014

class FirebaseInteractor
  """Connects to Firebase and connects to chatroom variables."""
  constructor: ->
    @fb_instance = new Firebase("https://proto1-cs247-p3-fb.firebaseio.com")

  # generate new chatroom id or use existing id
  get_fb_chat_room_id: =>
      url_segments = document.location.href.split("/#")
      if url_segments[1]
        return url_segments[1]
      return Math.random().toString(36).substring(7)

  init: =>
    @fb_chat_room_id = @get_fb_chat_room_id()
    # set up variables to access firebase data structure
    @fb_new_chat_room = @fb_instance.child('chatrooms').child(@fb_chat_room_id)
    @fb_instance_users = @fb_new_chat_room.child('users')
    @fb_instance_stream = @fb_new_chat_room.child('stream')


class ChatRoom
  """Main class to control the chat room display of messages and video"""
  constructor: (@fbInteractor, @videoRecorder) ->
    # Listen to Firebase events
    @fbInteractor.fb_instance_users.on "child_added", (snapshot) =>
      @displayMessage({m: snapshot.val().name + " joined the room", c: snapshot.val().c})

    @fbInteractor.fb_instance_stream.on "child_added", (snapshot) =>
      @displayMessage(snapshot.val())

    @submissionEl = $("#submission input")

  init: =>
    @displayMessage({m: "Share this url with your friend to join this chat: "+ document.location.origin+"/#"+@fbInteractor.fb_chat_room_id, c: "red"})
    # Block until user name entered
    @username = window.prompt("Welcome, warrior! please declare your name?")
    if not @username
      @username = "anonymous"+Math.floor(Math.random()*1111)
    @userColor = "#"+((1<<24)*Math.random()|0).toString(16) # Choose random color

    @fbInteractor.fb_instance_users.push({ name: @username,c: @userColor})
    $("#waiting").remove()
    @setupSubmissionBox()

  setupSubmissionBox: =>
    # bind submission box
    $("#submission input").on "keydown", (event) =>
      if (event.which == 13)
        console.log(@submissionEl.val())
        if (@hasEmotions(@submissionEl.val()))
          @fbInteractor.fb_instance_stream.push({m: @username + ": " + @submissionEl.val(), v: @videoRecorder.curVideoBlob, c: @userColor})
        else
          @fbInteractor.fb_instance_stream.push({m: @username + ": " + @submissionEl.val(), c: @userColor})
        @submissionEl.val("")


  # check to see if a message qualifies to be replaced with video.
  hasEmotions: (msg) =>
    emoticons = ["lol", ":)", ":("]
    for emoticon in emoticons
      if msg.indexOf(emoticon) != -1
        return true
    return false

  scrollToBottom: (wait_time) =>
    # scroll to bottom of div
    setTimeout =>
      $("html, body").animate({ scrollTop: $(document).height() }, 200)
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
    $("#conversation").append("<div class='msg' style='color:"+data.c+"'>"+data.m+"</div>")
    if data.v
      [source, video] = @createVideoElem(data.v)
      video.appendChild(source)
      document.getElementById("conversation").appendChild(video)
    # Scroll to the bottom every time we display a new message
    @scrollToBottom(0);

class VideoRecorder
  """Handles the mechanics of recording videos every 3 seconds."""
  constructor: ->
    @curVideoBlob = null

  connectWebcam: =>
    # we're only recording video, not audio
    mediaConstraints =
      video: true,
      audio: false
    # callback for when we get video stream from user.
    onMediaSuccess = @mediaSuccessCallback
    # callback if there is an error when we try and get the video stream
    onMediaError = (e) =>
      console.error('media error', e)
    # get video stream from user. see https://github.com/streamproc/MediaStreamRecorder
    navigator.getUserMedia(mediaConstraints, onMediaSuccess, onMediaError)

  mediaSuccessCallback: (stream) =>
    # create video element, attach webcam stream to video element
    video_width= 160
    video_height= 120
    webcam_stream = document.getElementById('webcam_stream')
    video = document.createElement('video')
    webcam_stream.innerHTML = ""
    # adds these properties to the video
    video = mergeProps(video, {
        controls: false,
        width: video_width,
        height: video_height,
        src: URL.createObjectURL(stream)
    })
    video.play()
    webcam_stream.appendChild(video)

    # counter
    time = 0
    second_counter = document.getElementById('second_counter')
    second_counter_update = setInterval =>
      second_counter.innerHTML = time++
    , 1000

    # now record stream in 5 seconds interval
    video_container = document.getElementById('video_container')
    mediaRecorder = new MediaStreamRecorder(stream)
    index = 1

    mediaRecorder.mimeType = 'video/webm'
    # mediaRecorder.mimeType = 'image/gif'
    # make recorded media smaller to save some traffic (80 * 60 pixels, 3*24 frames)
    mediaRecorder.video_width = video_width/2
    mediaRecorder.video_height = video_height/2

    mediaRecorder.ondataavailable = @dataAvailableCallback

    setInterval =>
      mediaRecorder.stop()
      mediaRecorder.start(3000)
    , 3000
    console.log("connect to media stream!")

  dataAvailableCallback: (blob) =>
    video_container.innerHTML = ""
    # convert data into base 64 blocks
    BlobConverter.blob_to_base64 blob, (b64_data) =>
      @curVideoBlob = b64_data

class BlobConverter
  """Static methods for converting blob to base 64 and vice versa
  for performance bench mark, please refer to http://jsperf.com/blob-base64-conversion/5
  note useing String.fromCharCode.apply can cause callstack error"""

  # Leading @ marks as static method.
  @blob_to_base64: (blob, callback) =>
    reader = new FileReader()
    reader.onload = =>
      dataUrl = reader.result
      base64 = dataUrl.split(',')[1]
      callback(base64)
    reader.readAsDataURL(blob)

  @base64_to_blob: (base64) =>
    binary = atob(base64)
    len = binary.length
    buffer = new ArrayBuffer(len)
    view = new Uint8Array(buffer)
    for i in [0...len]
      view[i] = binary.charCodeAt(i)
    blob = new Blob([view])
    return blob


# Start everything!
$(document).ready ->
  fbInteractor = new FirebaseInteractor()
  fbInteractor.init()
  videoRecorder = new VideoRecorder()
  chatRoom = new ChatRoom(fbInteractor, videoRecorder)
  chatRoom.init()
  videoRecorder.connectWebcam()

