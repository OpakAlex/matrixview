class @MatrixView
  constructor: (@element, params={}) ->
    @selectHandler   = params['selectHandler']
    @deselectHandler = params['deselectHandler']
    @openHandler     = params['openHandler']
    @deleteHandler   = params['deleteHandler']
    @selectedItems   = new Array()
#    @element.first().parent().prepend('<div id="selectionArea" style="display: none"></div>')
    @init_event_click()
    @init_event_mousedown_click()
    @init_mouse_click()

  init_event_click: ->
    $(document).unbind('keydown')
    self = @
    document.onkeydown = (event) ->
      # Meta/Control
      if event.metaKey
        if (event.keyCode == 65) # Shift-A (Select All)
          self.selectAll()
          event.stop()
          return false
        return
      else if event.shiftKey
        if (event.keyCode == 37 || event.keyCode == 63234) # Left Arrow
          self.expandSelectionLeft(event)
        if (event.keyCode == 40 || event.keyCode == 63232) # Up Arrow
          self.expandSelectionUp(event)
        if (event.keyCode == 39 || event.keyCode == 63235) # Right Arrow
          self.expandSelectionRight(event)
        if (event.keyCode == 38 || event.keyCode == 63233) # Down Arrow
          self.expandSelectionDown(event)
        if (event.keyCode == 32) # Space
          event.stop()
        if (event.keyCode == Event.KEY_TAB) # Tab
          if (self.selectedItems.size() > 0)
            self.moveLeft(event)
        return

      if (event.keyCode == Event.KEY_RETURN) # Enter (Open Item)
        if (self.selectedItems.size() == 1)
          self.open(self.selectedItems.first())
      if (event.keyCode == Event.KEY_BACKSPACE || event.keyCode == Event.KEY_DELETE || event.keyCode == 63272) # Delete/Backspace
        self.destroy(self.selectedItems)
        event.stop()

      if (event.keyCode == Event.KEY_LEFT || event.keyCode == 63234) # Left Arrow
        self.moveLeft(event)
      if (event.keyCode == Event.KEY_UP || event.keyCode == 63232) # Up Arrow
        self.moveUp(event)
      if (event.keyCode == Event.KEY_RIGHT || event.keyCode == 63235) # Right Arrow
        self.moveRight(event)
      if (event.keyCode == Event.KEY_DOWN || event.keyCode == 63233) # Down Arrow
        self.moveDown(event)
      if (event.keyCode == 32) # Space
        event.stop()
      if (event.keyCode == Event.KEY_TAB) # Tab
        if (self.selectedItems.size() > 0)
          self.moveRight(event)

  init_event_mousedown_click: ->
    self = @
    $(document).unbind('mousedown')
    $(document).mousedown (event) ->
      element = $(event.target)
      # For Safari, since it passes thru clicks on the scrollbar, exclude 15 pixels from the click area
      unless $(element).is 'div'
        self.select(element, event)
      else
        self.deselectAll()
        window.dragging = true
        window.originX = event.pageX
        window.originY = event.pageY
        $('#selectionArea').css({ width:'0px', height:'0px', border:"black 1px solid", left:event.pageX - 0, top:event.pageY - 0 }).show()

      event.preventDefault()

  init_mouse_click: ->
    self = @
    $(document).unbind('mouseup')
    $(document).mouseup (event) ->
      window.dragging = false
      $('#selectionArea').hide()
      $('#selectionArea').css({ width:'0px', height:'0px' })
      if (self.selectHandler)
        self.selectHandler(self.selectedItems)

    $(document).unbind('mousemove')
    $(document).mousemove (event) ->
      if window.dragging
        $('.selectionArea').show()
        width  = event.pageX - window.originX
        height = event.pageY - window.originY
        if (width < 0)
          width = -width
          left = event.pageX
        else
          left = window.originX

        if (height < 0)
          height = -height
          top = event.pageY
        else
          top = window.originY
        left = left - 0
        top  = top  - 0

        $('#selectionArea').css({
          "z-index": 1000,
          border: "2px rgba(208,208,234,0.8) solid",
          background: "rgba(208,208,234,0.5)",
          position: "absolute",
          left: left + 'px',
          top: top + 'px',
          width: width + 'px',
          height: height + 'px'
        })

        for el in self.element
          element = $(el)
          offset = element.offset()
          left = offset.left
          top = offset.top
          right = left + element.width()
          bottom = top + element.height()
          center_x = left + element.width() / 2
          center_y = top + element.height() / 2
          left_x = $('#selectionArea').offset().left
          right_x = $('#selectionArea').offset().left + $('#selectionArea').width()
          top_y = $('#selectionArea').offset().top
          bottom_y = $('#selectionArea').offset().top + $('#selectionArea').height()
          if parseInt(center_x) in [parseInt(left_x)..parseInt(right_x)] and parseInt(center_y) in [parseInt(top_y)..parseInt(bottom_y)]
            element.addClass('selected')
#            element.next().css({'clear':'both'})
#            if (window.matrixView.selectedItems.indexOf(element) == -1)
#              window.matrixView.selectedItems.push(element)
          else
#            window.matrixView.selectedItems[window.matrixView.selectedItems.indexOf(element)] = null
            element.removeClass('selected')




  deselectAll: ->
    $('.selected').removeClass('selected')
    # If a custom deselect handler has been defined, call it
    if (this.deselectHandler)
      this.deselectHandler()

  select: (element, event) =>
    element = $(event?.target) || element
    element = element.parent() unless element.is('div')

    self = @
    # Multiple Selection (Shift-Select)
    if event && event.shiftKey
    # Find first selected item
      firstSelectedElement = $(element).parent().find(".selected").first().attr('id')
      firstSelectedElementIndex = @items().indexOf(firstSelectedElement)
      selectedElementIndex      = @items().indexOf(element.attr('id'))
      items = @items()
      # If the first selected element is the element that was clicked on
      # then there's nothing for us to do.
      if firstSelectedElement == element.attr('id')
        return
      # If no elements are selected already, just select the element that
      # was clicked on.
      if (firstSelectedElementIndex == -1)
        @select(element)
        return
      siblings = []
      if (firstSelectedElementIndex < selectedElementIndex)
        i = selectedElementIndex
        while i >= 0
          siblings.push(items[i])
          i = i - 1
      else
        i = firstSelectedElementIndex
        while i >= 0
          siblings.push(items[i])
          i = i - 1
      done = false
      $(element).parent().find(".selected").toggleClass('selected')
      for el in siblings
        if done == false
          $("##{el}").addClass('selected')
          self.selectedItems.push($("##{el}"))
        done = true if element == $("##{el}")
      # Multiple Selection (Meta-Select)
    else if (event && event.metaKey)
      # If the element is already selected, deselect it
      if element.hasClass('selected')
        self.selectedItems = this.selectedItems.without(element)
        element.removeClass('selected')
      # Otherwise, select it
      else
        self.selectedItems.push(element)
        element.addClass('selected')
      # Single Selection (Single Click)
    else
      element.toggleClass('selected')
      self.selectedItems = new Array(element)
    # If a custom select handler has been defined, call it
    if (self.selectHandler)
      self.selectHandler(element)

  open: (element) ->
    this.deselectAll()
    element.addClass('selected')
    # If a custom open handler has been defined, call it
    if (this.openHandler != null)
      this.openHandler(element)

  destroy: (elements) ->
    # If a custom open handler has been defined, call it
    if (this.deleteHandler)
      this.deleteHandler(elements)
  selectAll: ->
    self = @
    this.deselectAll()
    $('#' + this.element.id + ' li').each (el) ->
      $(el).addClass('selected')
      self.selectedItems.push($(el))
    # If a custom select handler has been defined, call it
    if (this.selectHandler)
      this.selectHandler(@selectedItems)

  selectFirst: ->
    element = $('#' + this.element.id + ' li').first()
    this.deselectAll()
    this.select(element)
    this.scrollIntoView(element, 'down')
    # If a custom select handler has been defined, call it
    if (this.selectHandler)
      this.selectHandler(element)

  selectLast: ->
    element = $('#' + this.element.id + ' li').last()
    this.deselectAll()
    this.select(element)
    this.scrollIntoView(element, 'down')
    # If a custom select handler has been defined, call it
    if (this.selectHandler)
      this.selectHandler(element)
  moveLeft: (event) ->
    log 546
    event.stop()
    element = $('#' + this.element.id + ' li.selected').first()
    if (!element)
      return this.selectFirst()
    if (previousElement = element.prev())
      this.select(previousElement)
      this.scrollIntoView(previousElement, 'up')
    else
      this.selectFirst()

  moveRight: (event) ->
    event.stop()
    element = $('#' + this.element.id + ' selected').last()
    if (!element)
      return this.selectFirst()
    if (nextElement = element.next())
      this.select(nextElement)
      this.scrollIntoView(nextElement, 'down')
    else
      this.selectLast()


  moveUp: (event) ->
    self = @
    event?.stop()
    element = $('.selected').first()
    if (!element)
      return this.selectFirst()
    offset = $(element).offset()
    y = Math.floor(offset[1] - element.height())
    previousSiblings = element.previousSiblings()
    if (previousSiblings.size() == 0)
      return this.selectFirst()
    for el in previousSiblings
      if  offset[0] > y
        self.select(el)
        self.scrollIntoView($(el), 'up')

  moveDown: (event) ->
    self = @
    event?.stop()
    element = $('.selected').last()
    return this.selectFirst() if (!element)
    offset = $(element).offset()
    y = Math.floor(offset[1] + element.height() + (element.height() / 2)) + parseInt($(element).css('margin-bottom'))
    nextSiblings = element.nextSiblings()
    return this.selectLast() if nextSiblings.size() == 0
    selected = false
    for el in nextSiblings
      if  offset[0] > y
        self.select($(el))
        self.scrollIntoView($(el), 'down')
        selected = true
    this.selectLast() unless selected

  expandSelectionLeft: (event) ->
    element = $('.selected').last()
    element.toggleClass('selected')
    # If a custom select handler has been defined, call it
    if (this.selectHandler)
      this.selectHandler(element)

  expandSelectionRight: (event) ->
    element = $('.selected').last()
    otherElement = element.next()
    @curr_element = element
    otherElement.addClass('selected')
    this.selectedItems.push(otherElement)
    this.scrollIntoView(element, 'down')
    # If a custom select handler has been defined, call it
    if (this.selectHandler)
      this.selectHandler(element)

  expandSelectionUp: (event) ->
    self = @
    element = $('.selected').last()
    index_to = self.items().indexOf(element.attr('id'))
    items = self.items()
    siblings = []
    i = index_to
    while i <= index_to + 8
      siblings.push(items[i])
      i = i + 1
    for el in siblings
      el = $("##{el}")
      el.addClass('selected')
      self.selectedItems.push(el)
#    # If a custom select handler has been defined, call it
    if (this.selectHandler)
      this.selectHandler(element)


  expandSelectionDown: (event) ->
    log 666
    self = @
    element = $('.selected').last()
    index_to = self.items().indexOf(element.attr('id'))
    items = self.items()
    siblings = []
    i = index_to - 8
    while i <= index_to
      siblings.push(items[i])
      i = i + 1
    for el in siblings
      el = $("##{el}")
      el.removeClass('selected')
#      self.selectedItems.push(el)
#    self = @
#    event.stop()
#    element = this.element.find('li.selected').last()
#    offset = $(element).offset()
#    y = Math.floor(offset[1] + element.height() + (element.height() / 2)) + parseInt($(element).css('margin-bottom'))
#    done = false
#    for el in element.nextSiblings()
#      el = $(el)
#    if (done == false)
#      el.addClass('selected')
#      self.selectedItems.push(el)
#    if offset[0] > y
#      done = true
#      self.scrollIntoView(el, 'down')
#
#    # If a custom select handler has been defined, call it
#    if (this.selectHandler)
#      this.selectHandler(element)

  items: ->
    ids = []
    for el in $(".styles_accept div")
      ids.push $(el).attr('id')
    ids

  scrollIntoView: (element, direction) ->

  next_siblings: (element) ->
    sibs = []
    @items().indef
(($) ->
  $.fn.down = ->
    $ this[0] and this[0].children and this[0].children[0]
) jQuery

(($) ->
  $.fn.getNextSiblings = (filter) ->
    sibs = []
    element = $(this)
    while element = $(this).nextAll()
      sibs.push element  if not filter or filter(element)
    sibs
) jQuery
(($) ->
  $.fn.previousSiblings = (filter) ->
    sibs = []
    element = $(this)
#    while element = $(this).prev()
#      sibs.push element  if not filter or filter(element)
    sibs
) jQuery

#### Prototype "up" method
(($) ->
  $.fn.up = () ->
    found = ""
    selector = $.trim(selector or "")
    $(this).parents().each ->
      if selector.length is 0 or $(this).is(selector)
        found = this
        false
    $(found)
) jQuery
