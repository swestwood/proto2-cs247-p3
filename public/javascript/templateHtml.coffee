"""
This is a hack to avoid having to manually pre-compile the Handlebars templates.
"""

window.buildTemplates = =>

  memoryBuilderHandlebars = """
  <div id="memory_builder">
  {{#each panels}}<div class="panel_wrapper" {{panelIndex}}">
    <div class="panel">  {{!-- {{Comment: the width here needs to match the width in the CSS for .panel_wrapper! }} --}}
      <div class="vid_wrapper"><video autoplay="" loop="" height="100%"><source src="{{video.videoUrl}}" type="video/webm"></video></div>
      <div class="annotation">
        <span class="memory_message">{{video.messageBefore}}</span>
        <span class="memory_message">{{video.messageCurrent}}</span>
      </div>
    </div>
  </div>{{/each}}
  """

  entireMemoryWrapperHandlebars = """
  <div id="build_memory">
    <div><button id="make_memory_button">Build!</button></div>
    <div id="memory_builder_container"></div>
  </div>
  """

  # Add any new templates to this dictionary so that they get compiled.
  handlebarsElems = 
    "memoryBuilder": memoryBuilderHandlebars
    "memoryWrapper": entireMemoryWrapperHandlebars
  return handlebarsElems

# Access templates via window.Templates["quiz"] for example, depending on the name given in
# handlebarsElems
window.Templates = {}
for name, templateStr of window.buildTemplates()
  window.Templates[name] = Handlebars.compile(templateStr)