h = require('helpers')

Annotator = require('annotator')
Util = Annotator.Util
Range = Annotator.Range
$ = Util.$


describe 'Annotator', ->
  annotator = null

  beforeEach -> annotator = new Annotator($('<div></div>')[0])
  afterEach  -> $(document).unbind()

  describe "events", ->
    it "should call Annotator#onAdderClick() when adder is clicked", ->
      stub = sinon.stub(annotator, 'onAdderClick')

      annotator.element.find('.annotator-adder button').click()

      assert(stub.calledOnce)

    it "should call Annotator#onAdderMousedown() when mouse button is held down on adder", ->
      stub = sinon.stub(annotator, 'onAdderMousedown')

      annotator.element.find('.annotator-adder button').mousedown()

      assert(stub.calledOnce)


  describe "constructor", ->
    beforeEach ->
      sinon.stub(annotator, '_setupWrapper').returns(annotator)
      sinon.stub(annotator, '_setupViewer').returns(annotator)
      sinon.stub(annotator, '_setupEditor').returns(annotator)
      sinon.stub(annotator, '_setupDocumentEvents').returns(annotator)
      sinon.stub(annotator, '_setupDynamicStyle').returns(annotator)

    it 'should include the default modules', ->
      assert.isObject(annotator['annotations'], 'annotations service exists')
      assert.isObject(annotator['annotations'], 'storage service exists')

    it "should have a jQuery wrapper as @element", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert.instanceOf(annotator.element, $)

    it "should create an empty @plugin object", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert.isTrue(annotator.hasOwnProperty('plugins'))

    it "should create the adder properties from the @html strings", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert.instanceOf(annotator.adder, $)

    it "should call Annotator#_setupWrapper()", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert(annotator._setupWrapper.called)

    it "should call Annotator#_setupViewer()", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert(annotator._setupViewer.called)

    it "should call Annotator#_setupEditor()", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert(annotator._setupEditor.called)

    it "should call Annotator#_setupDocumentEvents()", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert(annotator._setupDocumentEvents.called)

    it "should NOT call Annotator#_setupDocumentEvents() if options.readOnly is true", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0], {
        readOnly: true
      })
      assert.isFalse(annotator._setupDocumentEvents.called)

    it "should call Annotator#_setupDynamicStyle()", ->
      Annotator.prototype.constructor.call(annotator, annotator.element[0])
      assert(annotator._setupDynamicStyle.called)

  describe "#destroy()", ->
    it "should unbind Annotator's events from the page", ->
      stub = sinon.stub(annotator, 'checkForStartSelection')

      annotator._setupDocumentEvents()
      annotator.destroy()
      $(document).mousedown()

      assert.isFalse(stub.called)
      $(document).unbind('mousedown')

    it "should remove Annotator's elements from the page", ->
      annotator.destroy()
      assert.equal(annotator.element.find('[class^=annotator-]').length, 0)

  describe "_setupDocumentEvents", ->
    beforeEach: ->
      $(document).unbind('mouseup').unbind('mousedown')

    it "should call Annotator#checkForStartSelection() when mouse button is pressed", ->
      stub = sinon.stub(annotator, 'checkForStartSelection')
      annotator._setupDocumentEvents()
      $(document).mousedown()
      assert(stub.calledOnce)

    it "should call Annotator#checkForEndSelection() when mouse button is lifted", ->
      stub = sinon.stub(annotator, 'checkForEndSelection')
      annotator._setupDocumentEvents()
      $(document).mouseup()
      assert(stub.calledOnce)

  describe "_setupWrapper", ->
    it "should wrap children of @element in the @html.wrapper element", ->
      annotator.element = $('<div><span>contents</span></div>')
      annotator._setupWrapper()
      assert.equal(annotator.wrapper.html(), '<span>contents</span>')

    it "should remove all script elements prior to wrapping", ->
      div = document.createElement('div')
      div.appendChild(document.createElement('script'))

      annotator.element = $(div)
      annotator._setupWrapper()

      assert.equal(annotator.wrapper[0].innerHTML, '')

  describe "_setupViewer", ->
    mockViewer = null

    beforeEach ->
      element = $('<div />')

      mockViewer =
        fields: []
        element: element

      mockViewer.on = -> mockViewer
      mockViewer.hide = -> mockViewer
      mockViewer.addField = (options) ->
        mockViewer.fields.push options
        mockViewer

      sinon.spy(mockViewer, 'on')
      sinon.spy(mockViewer, 'hide')
      sinon.spy(mockViewer, 'addField')
      sinon.stub(element, 'bind').returns(element)
      sinon.stub(element, 'appendTo').returns(element)
      sinon.stub(Annotator, 'Viewer').returns(mockViewer)

      annotator._setupViewer()

    afterEach ->
      Annotator.Viewer.restore()

    it "should create a new instance of Annotator.Viewer and set Annotator#viewer", ->
      assert.strictEqual(annotator.viewer, mockViewer)

    it "should hide the annotator on creation", ->
      assert(mockViewer.hide.calledOnce)

    it "should setup the default text field", ->
      args = mockViewer.addField.lastCall.args[0]

      assert(mockViewer.addField.calledOnce)
      assert.equal(typeof args.load, "function")

    it "should set the contents of the field on load", ->
      field = document.createElement('div')
      annotation = {text: "test"}

      annotator.viewer.fields[0].load(field, annotation)
      assert.equal($(field).html(), "test")

    it "should set the contents of the field to placeholder text when empty", ->
      field = document.createElement('div')
      annotation = {text: ""}

      annotator.viewer.fields[0].load(field, annotation)
      assert.equal($(field).html(), "<i>No Comment</i>")

    it "should setup the default text field to publish an event on load", ->
      field = document.createElement('div')
      annotation = {text: "test"}
      callback = sinon.spy()

      annotator.on('annotationViewerTextField', callback)
      annotator.viewer.fields[0].load(field, annotation)
      assert(callback.calledWith(field, annotation))

    it "should subscribe to custom events", ->
      assert.equal('edit', mockViewer.on.args[0][0])
      assert.equal('delete', mockViewer.on.args[1][0])

    it "should bind to browser mouseover and mouseout events", ->
      assert(mockViewer.element.bind.calledWith({
        'mouseover': annotator.clearViewerHideTimer
        'mouseout':  annotator.startViewerHideTimer
      }))

    it "should append the Viewer#element to the Annotator#wrapper", ->
      assert(mockViewer.element.appendTo.calledWith(annotator.wrapper))

  describe "_setupEditor", ->
    mockEditor = null

    beforeEach ->
      element = $('<div />')

      mockEditor = {
        element: element
      }
      mockEditor.on = -> mockEditor
      mockEditor.hide = -> mockEditor
      mockEditor.addField = -> document.createElement('li')

      sinon.spy(mockEditor, 'on')
      sinon.spy(mockEditor, 'hide')
      sinon.spy(mockEditor, 'addField')
      sinon.stub(element, 'appendTo').returns(element)
      sinon.stub(Annotator, 'Editor').returns(mockEditor)

      annotator._setupEditor()

    afterEach ->
      Annotator.Editor.restore()

    it "should create a new instance of Annotator.Editor and set Annotator#editor", ->
      assert.strictEqual(annotator.editor, mockEditor)

    it "should hide the annotator on creation", ->
      assert(mockEditor.hide.calledOnce)

    it "should add the default textarea field", ->
      options = mockEditor.addField.lastCall.args[0]

      assert(mockEditor.addField.calledOnce)
      assert.equal(options.type, 'textarea')
      assert.equal(options.label, 'Comments\u2026')
      assert.typeOf(options.load, 'function')
      assert.typeOf(options.submit, 'function')

    it "should subscribe to custom events", ->
      assert(mockEditor.on.calledWith('hide', annotator.onEditorHide))
      assert(mockEditor.on.calledWith('save', annotator.onEditorSubmit))

    it "should append the Editor#element to the Annotator#wrapper", ->
      assert(mockEditor.element.appendTo.calledWith(annotator.wrapper))

  describe "_setupDynamicStyle", ->
    $fix = null

    beforeEach ->
      h.addFixture 'annotator'
      $fix = $(h.fix())

    afterEach -> h.clearFixtures()

    it 'should ensure Annotator z-indices are larger than others in the page', ->
      $fix.show()

      $adder = $('<div style="position:relative;" class="annotator-adder">&nbsp;</div>').appendTo($fix)
      $filter = $('<div style="position:relative;" class="annotator-filter">&nbsp;</div>').appendTo($fix)

      check = (minimum) ->
        adderZ = parseInt($adder.css('z-index'), 10)
        filterZ = parseInt($filter.css('z-index'), 10)
        assert.isTrue(adderZ > minimum)
        assert.isTrue(filterZ > minimum)
        assert.isTrue(adderZ > filterZ)

      check(1000)

      $fix.append('<div style="position: relative; z-index: 2000"></div>')
      annotator._setupDynamicStyle()
      check(2000)

      $fix.append('<div style="position: relative; z-index: 10000"></div>')
      annotator._setupDynamicStyle()
      check(10000)

      $fix.hide()

  describe "getSelectedRanges", ->
    mockGlobal = null
    mockSelection = null
    mockRange = null
    mockBrowserRange = null

    beforeEach ->
      mockBrowserRange = {
        cloneRange: sinon.stub()
      }
      mockBrowserRange.cloneRange.returns(mockBrowserRange)

      # This mock pretends to be both NormalizedRange and BrowserRange.
      mockRange = {
        limit: sinon.stub()
        normalize: sinon.stub()
        toRange: sinon.stub().returns('range')
      }
      mockRange.limit.returns(mockRange)
      mockRange.normalize.returns(mockRange)

      # https://developer.mozilla.org/en/nsISelection
      mockSelection = {
        getRangeAt: sinon.stub().returns(mockBrowserRange)
        removeAllRanges: sinon.spy()
        addRange: sinon.spy()
        rangeCount: 1
      }
      mockGlobal = {
        getSelection: sinon.stub().returns(mockSelection)
      }
      sinon.stub(Util, 'getGlobal').returns(mockGlobal)
      sinon.stub(Range, 'BrowserRange').returns(mockRange)

    afterEach ->
      Util.getGlobal.restore()
      Range.BrowserRange.restore()

    it "should retrieve the global object and call getSelection()", ->
      annotator.getSelectedRanges()
      assert(mockGlobal.getSelection.calledOnce)

    it "should retrieve the global object and call getSelection()", ->
      ranges = annotator.getSelectedRanges()
      assert.deepEqual(ranges, [mockRange])

    it "should remove any failed calls to NormalizedRange#limit(), but re-add them to the global selection", ->
      mockRange.limit.returns(null)
      ranges = annotator.getSelectedRanges()
      assert.deepEqual(ranges, [])
      assert.isTrue(mockSelection.addRange.calledWith(mockBrowserRange))

    it "should return an empty array if selection.isCollapsed is true", ->
      mockSelection.isCollapsed = true
      ranges = annotator.getSelectedRanges()
      assert.deepEqual(ranges, [])

    it "should deselect all current ranges", ->
      ranges = annotator.getSelectedRanges()
      assert(mockSelection.removeAllRanges.calledOnce)

    it "should reassign the newly normalized ranges", ->
      ranges = annotator.getSelectedRanges()
      assert(mockSelection.addRange.calledOnce)
      assert.isTrue(mockSelection.addRange.calledWith('range'))

  describe "setupAnnotation", ->
    annotation = null
    quote = null
    comment = null
    element = null
    annotationObj = null
    normalizedRange = null
    sniffedRange = null

    beforeEach ->
      quote   = 'This is some annotated text'
      comment = 'This is a comment on an annotation'
      element = $('<span />')

      normalizedRange = {
        text: sinon.stub().returns(quote)
        serialize: sinon.stub().returns({})
      }
      sniffedRange = {
        normalize: sinon.stub().returns(normalizedRange)
      }
      sinon.stub(Range, 'sniff').returns(sniffedRange)
      sinon.spy(annotator, 'publish')

      annotationObj = {
        text: comment,
        ranges: [1]
      }
      annotation = annotator.setupAnnotation(annotationObj)

    afterEach ->
      Range.sniff.restore()

    it "should return the annotation object with a comment", ->
      assert.equal(annotation.text, comment)

    it "should return the annotation object with the quoted text", ->
      assert.equal(annotation.quote, quote)

    it "should trim whitespace from start and end of quote", ->
      normalizedRange.text.returns('\n\t   ' + quote + '   \n')
      annotation = annotator.setupAnnotation(annotationObj)
      assert.equal(annotation.quote, quote)

    it "should set the annotation.ranges", ->
      assert.deepEqual(annotation.ranges, [{}])

    it "should exclude any ranges that could not be normalized", ->
      e = new Range.RangeError("typ", "msg")
      sniffedRange.normalize.throws(e)
      annotation = annotator.setupAnnotation({
        text: comment,
        ranges: [1]
      })

      assert.deepEqual(annotation.ranges, [])

    it "should trigger rangeNormalizeFail for each range that can't be normalized", ->
      e = new Range.RangeError("typ", "msg")
      sniffedRange.normalize.throws(e)
      annotator.publish = sinon.spy()
      annotation = annotator.setupAnnotation({
        text: comment,
        ranges: [1]
      })

      assert.isTrue(annotator.publish.calledWith('rangeNormalizeFail', [annotation, 1, e]))

  describe "loadAnnotations", ->
    beforeEach ->
      sinon.stub(annotator, 'setupAnnotation')
      sinon.spy(annotator, 'publish')

    it "should call Annotator#setupAnnotation for each annotation in the Array", ->
      annotations = [{}, {}, {}, {}]
      annotator.loadAnnotations(annotations)
      assert.equal(annotator.setupAnnotation.callCount, 4)

    it "should publish the annotationsLoaded event with all loaded annotations", ->
      annotations = [{}, {}, {}, {}]
      annotator.loadAnnotations(annotations.slice())
      assert.isTrue(annotator.publish.calledWith('annotationsLoaded', [annotations]))

    it "should break the annotations into blocks of 10", ->
      clock = sinon.useFakeTimers()
      annotations = [{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}]

      annotator.loadAnnotations(annotations)
      assert.equal(annotator.setupAnnotation.callCount, 10)

      while annotations.length > 0
        clock.tick(10)

      assert.equal(annotator.setupAnnotation.callCount, 13)
      clock.restore()

  describe "dumpAnnotations", ->
    it "returns false and prints a warning if no Store plugin is active", ->
      sinon.stub(console, 'warn')
      assert.isFalse(annotator.dumpAnnotations())
      assert(console.warn.calledOnce)

    it "returns the results of the Store plugins dumpAnnotations method", ->
      annotator.store = { dumpAnnotations: -> [1,2,3] }
      assert.deepEqual(annotator.dumpAnnotations(), [1,2,3])

  describe "addPlugin", ->
    plugin = null
    Foo = null

    beforeEach ->
      plugin = {
        pluginInit: sinon.spy()
      }
      Foo = sinon.stub().returns(plugin)
      Annotator.Plugin.register('Foo', Foo)

    it "should add and instantiate a plugin of the specified name", ->
      annotator.addPlugin('Foo')
      assert.isTrue(Foo.calledWith(annotator.element[0], undefined))

    it "should pass on the provided options", ->
      options = {foo: 'bar'}
      annotator.addPlugin('Foo', options)
      assert.isTrue(Foo.calledWith(annotator.element[0], options))

    it "should attach the Annotator instance", ->
      annotator.addPlugin('Foo')
      assert.equal(plugin.annotator, annotator)

    it "should call Plugin#pluginInit()", ->
      annotator.addPlugin('Foo')
      assert(plugin.pluginInit.calledOnce)

    it "should complain if you try and instantiate a plugin that doesn't exist", ->
      sinon.stub(console, 'error')
      annotator.addPlugin('Bar')
      assert.isFalse(annotator.plugins['Bar']?)
      assert(console.error.calledOnce)
      console.error.restore()

  describe "showEditor", ->
    beforeEach ->
      sinon.spy(annotator, 'publish')
      sinon.spy(annotator.editor, 'load')
      sinon.spy(annotator.editor.element, 'css')

    it "should call Editor#load() on the Annotator#editor", ->
      annotation = {text: 'my annotation comment'}
      annotator.showEditor(annotation, {})
      assert.isTrue(annotator.editor.load.calledWith(annotation))

    it "should set the top/left properties of the Editor#element", ->
      location = {top: 20, left: 20}
      annotator.showEditor({}, location)
      assert.isTrue(annotator.editor.element.css.calledWith(location))

    it "should publish the 'annotationEditorShown' event passing the editor and annotations", ->
      annotation = {text: 'my annotation comment'}
      annotator.showEditor(annotation, {})
      assert(annotator.publish.calledWith('annotationEditorShown', [annotator.editor, annotation]))

  describe "onEditorHide", ->
    it "should publish the 'annotationEditorHidden' event and provide the Editor and annotation", ->
      sinon.spy(annotator, 'publish')
      annotator.onEditorHide()
      assert(annotator.publish.calledWith('annotationEditorHidden', [annotator.editor]))

    it "should set the Annotator#ignoreMouseup property to false", ->
      annotator.ignoreMouseup = true
      annotator.onEditorHide()
      assert.isFalse(annotator.ignoreMouseup)

  describe "onEditorSubmit", ->
    annotation = null

    beforeEach ->
      annotation = {"text": "bah"}
      sinon.spy(annotator, 'publish')
      sinon.spy(annotator, 'setupAnnotation')

    it "should publish the 'annotationEditorSubmit' event and pass the Editor and annotation", ->
      annotator.onEditorSubmit(annotation)
      assert(annotator.publish.calledWith('annotationEditorSubmit', [annotator.editor, annotation]))

  describe "showViewer", ->
    beforeEach ->
      sinon.spy(annotator, 'publish')
      sinon.spy(annotator.viewer, 'load')
      sinon.spy(annotator.viewer.element, 'css')

    it "should call Viewer#load() on the Annotator#viewer", ->
      annotations = [{text: 'my annotation comment'}]
      annotator.showViewer(annotations, {})
      assert.isTrue(annotator.viewer.load.calledWith(annotations))

    it "should set the top/left properties of the Editor#element", ->
      location = {top: 20, left: 20}
      annotator.showViewer([], location)
      assert.isTrue(annotator.viewer.element.css.calledWith(location))

    it "should publish the 'annotationViewerShown' event passing the viewer and annotations", ->
      annotations = [{text: 'my annotation comment'}]
      annotator.showViewer(annotations, {})
      assert(annotator.publish.calledWith('annotationViewerShown', [annotator.viewer, annotations]))

  describe "startViewerHideTimer", ->
    beforeEach ->
      sinon.spy(annotator.viewer, 'hide')

    it "should call Viewer.hide() on the Annotator#viewer after 250ms", ->
      clock = sinon.useFakeTimers()
      annotator.startViewerHideTimer()
      clock.tick(250)
      assert(annotator.viewer.hide.calledOnce)
      clock.restore()

    it "should NOT call Viewer.hide() on the Annotator#viewer if @viewerHideTimer is set", ->
      clock = sinon.useFakeTimers()
      annotator.viewerHideTimer = 60
      annotator.startViewerHideTimer()
      clock.tick(250)
      assert.isFalse(annotator.viewer.hide.calledOnce)
      clock.restore()

  describe "clearViewerHideTimer", ->
    it "should clear the @viewerHideTimer property", ->
      annotator.viewerHideTimer = 456
      annotator.clearViewerHideTimer()
      assert.isFalse(annotator.viewerHideTimer)

  describe "checkForStartSelection", ->
    beforeEach ->
      sinon.spy(annotator, 'startViewerHideTimer')
      annotator.mouseIsDown = false
      annotator.checkForStartSelection()

    it "should call Annotator#startViewerHideTimer()", ->
      assert(annotator.startViewerHideTimer.calledOnce)

    it "should NOT call #startViewerHideTimer() if mouse is over the annotator", ->
      annotator.startViewerHideTimer.reset()
      annotator.checkForStartSelection({target: annotator.viewer.element})
      assert.isFalse(annotator.startViewerHideTimer.called)

    it "should set @mouseIsDown to true", ->
      assert.isTrue(annotator.mouseIsDown)

  describe "checkForEndSelection", ->
    mockEvent = null
    mockOffset = null
    mockRanges = null

    beforeEach ->
      mockEvent = { target: document.createElement('span') }
      mockOffset = {top: 0, left: 0}
      mockRanges = [{}]

      sinon.stub(Util, 'mousePosition').returns(mockOffset)
      sinon.stub(annotator.adder, 'show').returns(annotator.adder)
      sinon.stub(annotator.adder, 'hide').returns(annotator.adder)
      sinon.stub(annotator.adder, 'css').returns(annotator.adder)
      sinon.stub(annotator, 'getSelectedRanges').returns(mockRanges)

      annotator.mouseIsDown    = true
      annotator.selectedRanges = []
      annotator.checkForEndSelection(mockEvent)

    afterEach ->
      Util.mousePosition.restore()

    it "should get the current selection from Annotator#getSelectedRanges()", ->
      assert(annotator.getSelectedRanges.calledOnce)

    it "should set @mouseIsDown to false", ->
      assert.isFalse(annotator.mouseIsDown)

    it "should set the Annotator#selectedRanges property", ->
      assert.equal(annotator.selectedRanges, mockRanges)

    it "should display the Annotator#adder if valid selection", ->
      assert(annotator.adder.show.calledOnce)
      assert.isTrue(annotator.adder.css.calledWith(mockOffset))
      assert.isTrue(Util.mousePosition.calledWith(mockEvent, annotator.wrapper[0]))

    it "should hide the Annotator#adder if NOT valid selection", ->
      annotator.adder.hide.reset()
      annotator.adder.show.reset()
      annotator.getSelectedRanges.returns([])

      annotator.checkForEndSelection(mockEvent)
      assert(annotator.adder.hide.calledOnce)
      assert.isFalse(annotator.adder.show.called)

    it "should hide the Annotator#adder if target is part of the annotator", ->
      annotator.adder.hide.reset()
      annotator.adder.show.reset()

      mockNode = document.createElement('span')
      mockEvent.target = annotator.viewer.element[0]

      sinon.stub(annotator, 'isAnnotator').returns(true)
      annotator.getSelectedRanges.returns([{commonAncestor: mockNode}])

      annotator.checkForEndSelection(mockEvent)
      assert.isTrue(annotator.isAnnotator.calledWith(mockNode))

      assert.isFalse(annotator.adder.hide.called)
      assert.isFalse(annotator.adder.show.called)

    it "should return if @ignoreMouseup is true", ->
      annotator.getSelectedRanges.reset()
      annotator.ignoreMouseup = true
      annotator.checkForEndSelection(mockEvent)
      assert.isFalse(annotator.getSelectedRanges.called)

  describe "isAnnotator", ->
    it "should return true if the element is part of the annotator", ->
      elements = [
        annotator.viewer.element
        annotator.adder
        annotator.editor.element.find('ul')
      ]

      for element in elements
        assert.isTrue(annotator.isAnnotator(element))

    it "should return false if the element is NOT part of the annotator", ->
      elements = [
        null
        annotator.element.parent()
        document.createElement('span')
        annotator.wrapper
      ]
      for element in elements
        assert.isFalse(annotator.isAnnotator(element))

  describe "onAdderMousedown", ->
    it "should set the @ignoreMouseup property to true", ->
      annotator.ignoreMouseup = false
      annotator.onAdderMousedown()
      assert.isTrue(annotator.ignoreMouseup)

  describe "onAdderClick", ->
    annotation = null
    mockOffset = null
    mockSubscriber = null
    quote = null
    element = null
    normalizedRange = null
    sniffedRange = null

    beforeEach ->
      annotation =
        text: "test"
      quote = 'This is some annotated text'
      element = $('<span />').addClass('annotator-hl')

      mockOffset = {top: 0, left:0}

      normalizedRange = {
        text: sinon.stub().returns(quote)
        serialize: sinon.stub().returns({})
      }
      sniffedRange = {
        normalize: sinon.stub().returns(normalizedRange)
      }

      sinon.stub(annotator.adder, 'hide')
      sinon.stub(annotator.adder, 'position').returns(mockOffset)
      sinon.spy(annotator, 'setupAnnotation')
      sinon.spy(annotator.annotations, 'create')
      sinon.stub(annotator, 'showEditor')
      sinon.stub(Range, 'sniff').returns(sniffedRange)
      sinon.spy(element, 'addClass')
      annotator.selectedRanges = ['foo']
      annotator.onAdderClick()

    afterEach ->
      Range.sniff.restore()

    it "should hide the adder", ->
      assert(annotator.adder.hide.calledOnce)

    it "should set up the annotation", ->
      assert(annotator.setupAnnotation.calledOnce)

    it "should display the editor", ->
      assert(annotator.showEditor.calledOnce)

    it "should create the annotation if the edit is saved", ->
      annotator.onEditorSubmit(annotation)
      assert(annotator.annotations.create.calledOnce)

    it "should not create the annotation if editing is cancelled", ->
      do annotator.onEditorHide
      do annotator.onEditorSubmit
      assert.isFalse(annotator.annotations.create.called)

  describe "onEditAnnotation", ->
    annotation = null
    mockOffset = null
    mockSubscriber = null

    beforeEach ->
      annotation = {id: 123, text: "my mock annotation"}
      mockOffset = {top: 0, left: 0}
      mockSubscriber = sinon.spy()
      sinon.spy(annotator, "showEditor")
      sinon.spy(annotator.annotations, "update")
      sinon.spy(annotator.viewer, "hide")
      sinon.stub(annotator.viewer.element, "position").returns(mockOffset)
      annotator.onEditAnnotation(annotation)

    it "should hide the viewer", ->
      assert(annotator.viewer.hide.calledOnce)

    it "should show the editor", ->
      assert(annotator.showEditor.calledOnce)

    it "should update the annotation if the edit is saved", ->
      annotator.onEditorSubmit(annotation)
      assert(annotator.annotations.update.calledWith(annotation))

    it "should not update the annotation if editing is cancelled", ->
      do annotator.onEditorHide
      annotator.onEditorSubmit(annotation)
      assert.isFalse(annotator.annotations.update.calledWith(annotation))


describe 'Annotator.Factory', ->
  it "should use Annotator as the default core constructor", ->
    factory = new Annotator.Factory()
    a = factory.getInstance()
    assert.instanceOf(a, Annotator)


describe "Annotator.noConflict()", ->
  _Annotator = null

  beforeEach ->
    _Annotator = Annotator

  afterEach ->
    window.Annotator = _Annotator

  it "should restore the value previously occupied by window.Annotator", ->
    Annotator.noConflict()
    assert.isUndefined(window.Annotator)

  it "should return the Annotator object", ->
    result = Annotator.noConflict()
    assert.equal(result, _Annotator)

describe "Annotator.supported()", ->

  beforeEach ->
    window._Selection = window.getSelection

  afterEach ->
    window.getSelection = window._Selection

  it "should return true if the browser has window.getSelection method", ->
    window.getSelection = ->
    assert.isTrue(Annotator.supported())

  xit "should return false if the browser has no window.getSelection method", ->
    # The method currently checks for getSelection on load and will always
    # return that result.
    window.getSelection = undefined
    assert.isFalse(Annotator.supported())
