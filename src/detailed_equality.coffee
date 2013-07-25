difflet = require 'difflet'
charm   = require 'charm'
should  = require 'should'
AssertionError = require('assert').AssertionError

detailedDifferenceMatcher = (expected) ->
  actual = @obj
  differenceMap =
    inserted:
      color: 'green'
      count: 0
    updated:  
      color: 'blue'
      count: 0
    deleted: 
      color: 'red'
      count: 0
    comment:
      color: 'cyan'
      count: 0

  colorForDifference = (type, stream, incrementCounter = true) =>
    @c ?= charm(stream)
    differenceMap[type].count += 1 if incrementCounter
    @c.foreground differenceMap[type].color
    @c.display 'bright'

  resetColor = (type, stream) =>
    @c.display 'reset'

  differenceFound = ->
    diff = difflet(comment: true, indent: 2, start: colorForDifference, stop: resetColor)
    diffStr = diff.compare actual, expected
    for type, val of differenceMap
      return diffStr if val.count > 0
    false

  constructStream = ->
    Stream = require('stream').Stream
    stream = new Stream
    stream.readable = true
    stream.writable = true

    stream.write = (buf) -> @emit('data', buf)
    stream.end = -> @emit('end')
    stream

  printDifferences = (diffString) =>
    differenceSummary = =>
      str = 'Total differences: '
      stream = constructStream()
      stream.on 'data', (data) -> str += data
      
      delete @c
      for type, val of differenceMap
        continue if type == 'comment'

        colorForDifference type, stream, false
        stream.emit 'data', "\t#{type}: #{val.count}\t"
        resetColor type, stream
      str

    "\n\u001b[0m#{diffString}\n\n#{differenceSummary()}\n\n"

  differences = differenceFound()
  @assert !differences, (-> console.log(printDifferences(differences)); "The Objects differ"), (-> 'The Objects are identical')
  this

unchainedDetailedDifferenceMatcher = (expected, actual) ->
  actual.should.equalObject expected

should.Assertion.prototype.equalArray  = detailedDifferenceMatcher
should.Assertion.prototype.equalObject = detailedDifferenceMatcher
should.Assertion.prototype.equalObj    = detailedDifferenceMatcher
should.equalObject = unchainedDetailedDifferenceMatcher
should.equalObj    = unchainedDetailedDifferenceMatcher
should.equalArray  = unchainedDetailedDifferenceMatcher
module.exports = should