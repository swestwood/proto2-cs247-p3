"""
This is a hack to avoid having to manually pre-compile the Handlebars templates.
"""

window.buildTemplates = =>
  
  # Treat these as HTML files
  quizHandlebars = """
  <div class="indiv_quiz_container {{forWhomClass}}">
    <div class="quiz_title">Face off!</div>
    <p>{{challengeMessage}}</p>
    <video autoplay="" loop="" width="320"><source src="{{videoUrl}}" type="video/webm"></video>
    {{#each quizChoices}}
      <button class='quiz-choice {{correct}}'>{{emoticon}}</button>
    {{/each}}
  </div>
  """

  powerupHandlebars = """
  <div class="quiz_title">Use emoticons while chatting to power up for a face off!</div>
  <p>Two users need to have at least {{numRequiredVideos}} emoticon videos available to start!</p>
  <p>Once every user is ready, a quiz will be triggered.</p>
  <div class="powerup_available_videos">

  </div>

  <div class="progress-wrap progress" data-progress-percent="0">
    <div class="progress-bar progress"></div>
  </div>
  <p id="powerup_encouragement"></p>
  """


  powerupAvailableHandlebars = """
  {{#each usersAvailable}}
    <div class="powerup-user-available">
      <span class="powerup-username">{{username}}:</span>
      <span class="powerup-num-available">{{numAvailable}}</span>
      <span class="is-ready">
      {{#if enoughVideos}}
        <span class="powerup-user-ready">
          (Ready!)
        </span>
      {{else}}
        <span class="powerup-user-not-ready">
          (Keep using emoticons!)
        </span
      {{/if}}
      </span>
    </div>
  {{/each}}
  """

  # Add any new templates to this dictionary so that they get compiled.
  handlebarsElems = 
    "quiz": quizHandlebars
    "powerup": powerupHandlebars
    "powerup_available": powerupAvailableHandlebars
  return handlebarsElems

# Access templates via window.Templates["quiz"] for example, depending on the name given in
# handlebarsElems
window.Templates = {}
for name, templateStr of window.buildTemplates()
  window.Templates[name] = Handlebars.compile(templateStr)