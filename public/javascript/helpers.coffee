"""
Helper classes, moved out of the main folder for ease of navigation. Each should really go in its own file if
  the project becomes large.

Compile by running coffee -wc *.coffee to generate main.js and compile other .coffee files in the directory.
"""

class window.EmotionProcessor
  @makeQuizChoices: (actualEmoticon) =>
    """Creates a list of emoticon quiz choices, where the other emoticon choices do not express the
    same emotion as the actual emoticon, or the same emotion as each other."""
    @wrongChoices = EmotionProcessor.chooseEmotionsExcept(actualEmoticon, NUMBER_WRONG_CHOICES)
    allChoices = _.clone(@wrongChoices)
    allChoices.push(actualEmoticon)
    allChoices = _.shuffle(allChoices)
    choiceContext = ({"emoticon": choice, "correct": if choice == actualEmoticon then "correct" else "wrong"} for choice in allChoices)
    return choiceContext

  # check to see if a message qualifies to be replaced with video.
  @getEmoticon: (msg) =>
    emoticons = []
    for emotion, faces of EMOTICON_MAP
      for face in faces
        if msg.indexOf(face) != -1
          emoticons.push(face) if emoticons.length == 0 or face.length > emoticons[emoticons.length - 1]  # Last face in an array will be longest
    # Choose the max-length face so that '>:(' isn't just ':('
    if emoticons.length == 0
      return null
    return emoticons[emoticons.length - 1]

  @countEmoticons: (msg) =>
    [msg, count] = EmotionProcessor.redactEmoticons(msg)
    return count

  @redactEmoticons: (msg) =>
    console.log "redacting msg"
    count = 0
    while true
      face = EmotionProcessor.getEmoticon(msg)
      if face == null
        console.log msg
        return [msg, count]
      count += 1
      msg = msg.slice(0, msg.indexOf(face)) + "[?]" + msg.slice(msg.indexOf(face) + face.length)

  @numberOfEmotions: =>
    return Object.keys(EMOTICON_MAP).length

  @chooseEmotionsExcept: (illegalFaceEmotion, numberToChoose) =>
    """Returns a list of numberToChoose emoticons, none of which express the same emotion as illegalFaceEmotion emoticon,
    nor the same emotion as each other."""
    # Gather the keys (emotion names) that do not express the same emotion as the illegal face
    legalKeys = (key for key in Object.keys(EMOTICON_MAP) when illegalFaceEmotion not in EMOTICON_MAP[key])
    # Choose a random set of emotion names
    chosenEmotions = _.sample(legalKeys, numberToChoose)  # ie ["happy", "sad", ...]
    # Choose random emoticons from the lists of faces corresponding to each emotion name
    chosenFaces = (_.sample(EMOTICON_MAP[key], 1)[0] for key in chosenEmotions)  # ie [":-)", ":[", ...]
    return chosenFaces

class window.VideoRecorder
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

  mediaSuccessCallback: (videoStream) =>
    # create video element, attach webcam videoStream to video element
    video_width = 160
    video_height = 120
    webcam_stream = document.getElementById('webcam_stream')
    video = document.createElement('video')
    webcam_stream.innerHTML = ""
    # adds these properties to the video
    video = mergeProps(video, {
        controls: false,
        width: video_width,
        height: video_height,
        src: URL.createObjectURL(videoStream)
    })
    video.play()
    webcam_stream.appendChild(video)

    # counter
    time = 0
    second_counter = document.getElementById('second_counter')
    second_counter_update = setInterval =>
      second_counter.innerHTML = time++
    , 1000

    # now record videoStream in seconds interval
    # video_container = document.getElementById('video_container')
    mediaRecorder = new MediaStreamRecorder(videoStream)

    mediaRecorder.mimeType = 'video/webm'
    # mediaRecorder.mimeType = 'image/gif'
    # make recorded media smaller to save some traffic (80 * 60 pixels, 3*24 frames)
    mediaRecorder.video_width = video_width/2
    mediaRecorder.video_height = video_height/2

    mediaRecorder.ondataavailable = @dataAvailableCallback

    setInterval =>
      mediaRecorder.stop()
      mediaRecorder.start(VIDEO_LENGTH_MS)
    , VIDEO_LENGTH_MS
    console.log("connect to media videoStream!")

  dataAvailableCallback: (blob) =>
    # video_container.innerHTML = ""
    # convert data into base 64 blocks
    _this = this;
    BlobConverter.blob_to_base64 blob, (b64_data) =>
      @curVideoBlob = b64_data

class window.BlobConverter
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
