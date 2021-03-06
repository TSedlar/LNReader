// Loaded via <script> tag, create shortcut to access PDF.js exports.
var PDFJS = window['pdfjs-dist/build/pdf'];

// The workerSrc property shall be specified.
PDFJS.GlobalWorkerOptions.workerSrc = 'pdf.worker.js';

var MIN_HEADER_LINE_COUNT = 5;

function normalizeLine(line) {
  return line.replace(/[0-9]/g, '').trim();
}

function parseSegments(textArgs) {
  var segments = [];
  var currentSegment = '';
  var lastY = -1;
  var lastHeight = -1;
  textArgs.text.items.forEach(function (i) {
    // Track if Y-Coord has changed or the text height has changed largely.
    // We give the height some variance because bold or italic fonts are
    // different glyph sizes.
    if (lastY != i.transform[5] || Math.abs(lastHeight - i.height) > 1.45) {
      // Add segment if it is not a number on its own (page number)
      var trimmed = currentSegment.trim();
      if (trimmed.length > 0 && isNaN(trimmed)) {
        if (lastHeight != i.height) {
          trimmed += '\n';
        }
        segments.push(trimmed + '');
      }
      currentSegment = '';
      lastY = i.transform[5];
      lastHeight = i.height;
    }
    currentSegment += i.str;
  });
  segments.push(currentSegment.trim()); // Make sure to add the last segment
  return segments;
}

function renderPdfToElement(data, container) {
  return PDFJS.getDocument(data).promise.then(function (pdf) {
    // Set promise array that resolves to page texts
    var promises = [];
    var pageCount = pdf.numPages;

    // Fill promises array
    for (var pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
      promises.push(new Promise(function (resolve, reject) {
        pdf.getPage(pageNumber).then(function (page) {
          page.getTextContent().then(function (text) {
            resolve({ page, text });
          });
        });
      }));
    }

    // Reduce promises into this array in order
    var textArray = [];

    // Run in order
    return promises.reduce(function (promise, next) {
      return promise.then(function (x) {
        textArray.push(x);
        return next;
      });
    }).then(function () {
      var segmentsArray = [];

      // Push segments to array
      for (var textArgs of textArray) {
        segmentsArray.push(parseSegments(textArgs));
      }

      // Collect header frequencies
      var segFreq = new Map();
      for (var segments of segmentsArray) {
        for (var i = 0; i < MIN_HEADER_LINE_COUNT && i < segments.length; i++) {
          var segment = normalizeLine(segments[i]);
          if (!segFreq.has(segment)) {
            segFreq.set(segment, 0);
          }
          segFreq.set(segment, segFreq.get(segment) + 1);
        }
      }

      var highFreqs = [];

      // Collect freqs > 0.8 (appear in 80% of pages..)
      segFreq.forEach(function (val, key, map) {
        var freq = val / pageCount;
        if (freq >= 0.8) {
          highFreqs.push(key);
        }
      });

      // Delete high freqs
      for (var segments of segmentsArray) {
        for (var segIdx in segments) {
          var segment = normalizeLine(segments[segIdx]);
          if (highFreqs.includes(segment)) {
            delete segments[segIdx];
          }
        }
      }

      // Display content
      for (var segments of segmentsArray) {
        var pageHTML = '';
        segments.filter(function (seg) {
          return seg.trim().length > 0;
        }).forEach(function (seg) {
          if (!pageHTML.endsWith('\n')) {
            pageHTML += ' ';
          }
          pageHTML += seg;
        });

        // Append ACTUAL pages, not just placeholders/images
        if (pageHTML.length >= 175) {
          pageHTML.split('\n').forEach(function (seg) {
            var p = document.createElement('p');
            p.textContent = seg;
            container.appendChild(p);
          });
        }
      }
      return textArray;
    });
  });
}

function b64ToBinary(b64) {
  var raw = window.atob(b64);
  var rawLength = raw.length;
  var array = new Uint8Array(new ArrayBuffer(rawLength));

  for(var i = 0; i < rawLength; i++) {
    array[i] = raw.charCodeAt(i);
  }
  return array;
}

var params = new URLSearchParams(window.location.search);
var nativeCommunicator = typeof webkit !== 'undefined' ? webkit.messageHandlers.native : window.native;

if (window['b64'] != null) {
  console.log(window['b64'].length);
  var container = document.getElementById('pdfTxt');
  var binary = b64ToBinary(window['b64']);
  renderPdfToElement(binary, container).then(function () {
    nativeCommunicator.postMessage(JSON.stringify({ "source": container.innerHTML }));
  });
} else {
  document.write('window.b64 not found');
  nativeCommunicator.postMessage(JSON.stringify({ "source": 'window.b64 not found' }));
}