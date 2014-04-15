"""
This is a hack to avoid having to manually pre-compile the Handlebars templates.
"""

window.buildTemplates = =>

  memoryBuilderHandlebars = """
  <div id="memory_builder">
    <div class="first-panel">
      <div class="first-panel-contents">
        {{#if standalone}}
          <h3 id="standalone-title" class="memory-builder-header">Our memory</h3>
        {{else}}
          <h3 id="in-strip-title" class="memory-builder-header">Build a memory together!</h3>
            {{#if waitingForVideo}}
              <div class="instructions-memory">You need at least 1 emoticon video to build a memory, the more the better!</div>
            {{/if}}
          <div>
            {{#if waitingForVideo}}
              <button id="make_memory_button" style="visibility:hidden">Make us a memory!</button>
            {{else}}
              <button id="make_memory_button">Make us a memory!</button>
            {{/if}}
            </div>
          {{#if memoryUrl}}
              <!--<h5>Keep this memory forever: <a href="{{memoryUrl}}" target="_blank">{{memoryUrl}}</a></h5>-->
          {{/if}}
        {{/if}}
      </div>
    </div>

  {{#if waitingForVideo}}

  {{else}}
    {{#each panels}}<div class="panel_wrapper" {{panelIndex}}">
      <div class="panel">  {{!-- {{Comment: the width here needs to match the width in the CSS for .panel_wrapper! }} --}}
        <div class="vid_wrapper"><video autoplay="" loop="" class="effect {{effect}}"><source src="{{video.videoUrl}}" type="video/webm"></video></div>
        <div class="annotation">
          <span class="memory_message">{{video.messageBefore}}</span>
          <span class="memory_message">{{video.messageCurrent}}</span>
        </div>
      </div>
    </div>{{/each}}
  {{/if}}
  """

  entireMemoryWrapperHandlebars = """
  <div id="build_memory">
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