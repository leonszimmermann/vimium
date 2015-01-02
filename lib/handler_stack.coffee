root = exports ? window

class HandlerStack

  constructor: ->
    @stack = []
    @counter = 0
    @passDirectlyToPage = new Object() # Used only as a constant, distinct from any other value.

  genId: -> @counter = ++@counter

  # Adds a handler to the stack. Returns a unique ID for that handler that can be used to remove it later.
  push: (handler) ->
    handler.id = @genId()
    @stack.push handler
    handler.id

  # Called whenever we receive a key event. Each individual handler has the option to stop the event's
  # propagation by returning a falsy value.
  bubbleEvent: (type, event) ->
    for i in [(@stack.length - 1)..0] by -1
      handler = @stack[i]
      # We need to check for existence of handler because the last function call may have caused the release
      # of more than one handler.
      if handler && handler[type]
        @currentId = handler.id
        passThrough = handler[type].call(@, event)
        if not passThrough
          DomUtils.suppressEvent(event) if @isChromeEvent event
          return false
        # If the constant @passDirectlyToPage is returned, then discontinue further bubbling and pass the
        # event through to the underlying page.  The event is not suppresssed.
        if passThrough == @passDirectlyToPage
          return false
    true

  remove: (id = @currentId) ->
    for i in [(@stack.length - 1)..0] by -1
      handler = @stack[i]
      if handler.id == id
        @stack.splice(i, 1)
        break

  # The handler stack handles chrome events (which may need to be suppressed) and internal (fake) events.
  # This checks whether that the event at hand is a chrome event.
  isChromeEvent: (event) ->
    event?.preventDefault? and event?.stopImmediatePropagation?

  # Convenience wrapper for handlers which always continue propagation.
  alwaysPropagate: (handler) ->
    handler()
    true

root.HandlerStack = HandlerStack
root.handlerStack = new HandlerStack
