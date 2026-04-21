/*! Copyright (C) Microsoft Corporation. All rights reserved. */
'use strict';

var editor = null;
var isEditable = true;

var COMMANDS = {
  bold: 'bold',
  italic: 'italic',
  underline: 'underline',
  strikethrough: 'strikeThrough',
  orderedList: 'insertOrderedList',
  unorderedList: 'insertUnorderedList',
  removeFormat: 'removeFormat'
};

// Initializes the DOM structure of the editor.
// Called automatically from Startup.js.
function Initialize() {
  var container = document.getElementById('controlAddIn');
  if (!container) return;

  container.innerHTML = '';
  container.className = 'html-editor-container';

  container.appendChild(createToolbar());

  editor = createEditor();
  container.appendChild(editor);

  raiseAddInReady();
}

function createToolbar() {
  var toolbar = document.createElement('div');
  toolbar.id = 'htmlEditorToolbar';
  toolbar.className = 'html-editor-toolbar';

  var buttons = [
    { title: 'Bold', command: COMMANDS.bold, label: 'B', className: 'html-editor-btn-bold' },
    { title: 'Italic', command: COMMANDS.italic, label: 'I', className: 'html-editor-btn-italic' },
    { title: 'Underline', command: COMMANDS.underline, label: 'U', className: 'html-editor-btn-underline' },
    { title: 'Strikethrough', command: COMMANDS.strikethrough, label: 'S', className: 'html-editor-btn-strikethrough' },
    null,
    { title: 'Ordered List', command: COMMANDS.orderedList, label: '1.', className: '' },
    { title: 'Unordered List', command: COMMANDS.unorderedList, label: '\u2022', className: '' },
    null,
    { title: 'Clear Formatting', command: COMMANDS.removeFormat, label: 'T\u2715', className: '' }
  ];

  buttons.forEach(function (btn) {
    if (btn === null) {
      var sep = document.createElement('span');
      sep.className = 'html-editor-separator';
      toolbar.appendChild(sep);
      return;
    }

    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'html-editor-toolbar-btn ' + btn.className;
    button.title = btn.title;
    button.setAttribute('aria-label', btn.title);
    button.textContent = btn.label;
    button.addEventListener('mousedown', function (e) {
      // Prevent the editor from losing focus when a toolbar button is clicked.
      e.preventDefault();
      if (isEditable) {
        document.execCommand(btn.command, false, null);
      }
    });

    toolbar.appendChild(button);
  });

  return toolbar;
}

function createEditor() {
  var editorDiv = document.createElement('div');
  editorDiv.id = 'htmlEditorBody';
  editorDiv.className = 'html-editor-body';
  editorDiv.contentEditable = 'true';
  editorDiv.spellcheck = true;
  editorDiv.setAttribute('role', 'textbox');
  editorDiv.setAttribute('aria-multiline', 'true');
  editorDiv.setAttribute('aria-label', 'Rich text editor');

  editorDiv.addEventListener('blur', function () {
    raiseContentChanged();
  });

  return editorDiv;
}

// Sets the HTML content of the editor.
// This function is called from AL via CurrPage.<controlname>.SetContent(html).
function SetContent(html) {
  if (editor) {
    editor.innerHTML = html || '';
  }
}

// Requests the current HTML content.
// The result is delivered asynchronously via the ContentChanged event.
// This function is called from AL via CurrPage.<controlname>.GetContent().
function GetContent() {
  raiseContentChanged();
}

// Enables or disables the editor.
// This function is called from AL via CurrPage.<controlname>.SetEditable(editable).
function SetEditable(editable) {
  isEditable = editable;

  if (editor) {
    editor.contentEditable = editable ? 'true' : 'false';
  }

  var toolbar = document.getElementById('htmlEditorToolbar');
  if (toolbar) {
    if (editable) {
      toolbar.classList.remove('html-editor-toolbar--disabled');
    } else {
      toolbar.classList.add('html-editor-toolbar--disabled');
    }
  }
}

// Handles the RecreateScript and RefreshScript lifecycle events.
function Refresh() {
  Initialize();
}

function raiseAddInReady() {
  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddInReady', null);
}

function raiseContentChanged() {
  var html = editor ? editor.innerHTML : '';
  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ContentChanged', [html]);
}
