!function ($) {

  "use strict"; // jshint ;_;


 /* POPOVER PUBLIC CLASS DEFINITION
  * =============================== */

  var Dompopover = function (element, options) {
    this.init('dompopover', element, options)
  }


  /* NOTE: POPOVER EXTENDS BOOTSTRAP-TOOLTIP.js
     ========================================== */

  Dompopover.prototype = $.extend({}, $.fn.tooltip.Constructor.prototype, {

    constructor: Dompopover

  , setContent: function () {
      var $tip = this.tip()
        , title = this.getTitle()
        , content = this.getContent()

      $tip.find('.popover-title')[this.options.html ? 'html' : 'text'](title)
      $tip.find('.popover-content').append(content)

      $tip.removeClass('fade top bottom left right in')
    }

  , hasContent: function () {
      return this.getTitle() || this.getContent()
    }

  , getContent: function () {
      var o = this.options

      return o.domcontent
    }

  , tip: function () {
      if (!this.$tip) {
        this.$tip = $(this.options.template)
      }
      return this.$tip
    }

  , destroy: function () {
      this.hide().$element.off('.' + this.type).removeData(this.type)
    }

  })


 /* POPOVER PLUGIN DEFINITION
  * ======================= */

  var old = $.fn.dompopover

  $.fn.dompopover = function (option) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('dompopover')
        , options = typeof option == 'object' && option
      if (!data) $this.data('dompopover', (data = new Dompopover(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  $.fn.dompopover.Constructor = Dompopover

  $.fn.dompopover.defaults = $.extend({} , $.fn.tooltip.defaults, {
    placement: 'right'
  , trigger: 'click'
  , content: ''
  , template: '<div class="popover"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
  })


 /* POPOVER NO CONFLICT
  * =================== */

  $.fn.dompopover.noConflict = function () {
    $.fn.dompopover = old
    return this
  }

}(window.jQuery);
