// Generated by CoffeeScript 1.7.1
(function() {
  "This is a hack to avoid having to manually pre-compile the Handlebars templates.";
  var name, templateStr, _ref;

  window.buildTemplates = (function(_this) {
    return function() {
      var entireMemoryWrapperHandlebars, handlebarsElems, memoryBuilderHandlebars;
      memoryBuilderHandlebars = "<div id=\"memory_builder\">\n  <div class=\"first-panel\">\n    <div class=\"first-panel-contents\">\n      {{#if standalone}}\n        <h3 class=\"memory-builder-header\">Our memory...</h3>\n      {{else}}\n        <h3 class=\"memory-builder-header\">Build a memory together!</h3>\n          {{#if waitingForVideo}}\n            <div class=\"instructions-memory\">You need at least 1 emoticon video to build a memory, the more the better!</div>\n          {{/if}}\n        <div>\n          {{#if waitingForVideo}}\n            <button id=\"make_memory_button\" style=\"visibility:hidden\">Make us a memory!</button>\n          {{else}}\n            <button id=\"make_memory_button\">Make us a memory!</button>\n          {{/if}}\n          </div>\n        {{#if memoryUrl}}\n            <h5>Keep this memory forever: <a href=\"{{memoryUrl}}\" target=\"_blank\">{{memoryUrl}}</a></h5>\n        {{/if}}\n      {{/if}}\n    </div>\n  </div>\n\n{{#if waitingForVideo}}\n\n{{else}}\n  {{#each panels}}<div class=\"panel_wrapper\" {{panelIndex}}\">\n    <div class=\"panel\">  {{!-- {{Comment: the width here needs to match the width in the CSS for .panel_wrapper! }} --}}\n      <div class=\"vid_wrapper\"><video autoplay=\"\" loop=\"\" class=\"effect {{effect}}\"><source src=\"{{video.videoUrl}}\" type=\"video/webm\"></video></div>\n      <div class=\"annotation\">\n        <span class=\"memory_message\">{{video.messageBefore}}</span>\n        <span class=\"memory_message\">{{video.messageCurrent}}</span>\n      </div>\n    </div>\n  </div>{{/each}}\n{{/if}}";
      entireMemoryWrapperHandlebars = "<div id=\"build_memory\">\n  <div id=\"memory_builder_container\"></div>\n</div>";
      handlebarsElems = {
        "memoryBuilder": memoryBuilderHandlebars,
        "memoryWrapper": entireMemoryWrapperHandlebars
      };
      return handlebarsElems;
    };
  })(this);

  window.Templates = {};

  _ref = window.buildTemplates();
  for (name in _ref) {
    templateStr = _ref[name];
    window.Templates[name] = Handlebars.compile(templateStr);
  }

}).call(this);
