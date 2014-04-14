"""
This is a hack to avoid having to manually pre-compile the Handlebars templates.
"""

window.buildTemplates = =>

  memoryBuilderHandlebars = """
  <div id="memory_builder">
  <h3>Panels:</h3>
  {{#if memoryUrl}}
    <h5>Keep this memory forever: <a href="{{memoryUrl}}" target="_blank">{{memoryUrl}}</a></h5>
  {{/if}}
  {{#each panels}}<div class="panel_wrapper" {{panelIndex}}">
    <div class="panel">  {{!-- {{Comment: the width here needs to match the width in the CSS for .panel_wrapper! }} --}}
      <video autoplay="" loop="" width="200"><source src="{{video.videoUrl}}"></video>
      <span class="memory_message">{{video.messageBefore}}</span>
      <span class="memory_message">{{video.messageCurrent}}</span>
    </div>
  </div>{{/each}}
  """

  # Add any new templates to this dictionary so that they get compiled.
  handlebarsElems = 
    "memoryBuilder": memoryBuilderHandlebars
  return handlebarsElems

# Access templates via window.Templates["quiz"] for example, depending on the name given in
# handlebarsElems
window.Templates = {}
for name, templateStr of window.buildTemplates()
  window.Templates[name] = Handlebars.compile(templateStr)