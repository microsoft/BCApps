// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

/// <summary>
/// A reusable rich text (HTML) editor control add-in that allows developers to embed an
/// in-page HTML editor in their Business Central pages.
///
/// Usage in a page:
///   usercontrol(MyEditor; HtmlEditor)
///   {
///       ApplicationArea = All;
///
///       trigger AddInReady()
///       begin
///           CurrPage.MyEditor.SetContent(HtmlText);
///           CurrPage.MyEditor.SetEditable(true);
///       end;
///
///       trigger ContentChanged(Html: Text)
///       begin
///           HtmlText := Html;
///       end;
///   }
/// </summary>
controladdin HtmlEditor
{
    RequestedHeight = 300;
    MinimumHeight = 180;
    RequestedWidth = 400;
    MinimumWidth = 200;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'Resources\HtmlEditor\js\HtmlEditor.js';
    StartupScript = 'Resources\HtmlEditor\js\Startup.js';
    RecreateScript = 'Resources\HtmlEditor\js\Recreate.js';
    RefreshScript = 'Resources\HtmlEditor\js\Refresh.js';
    StyleSheets = 'Resources\HtmlEditor\stylesheets\HtmlEditor.css';

    /// <summary>
    /// Raised when the control add-in has loaded and is ready to receive API calls.
    /// Use this event to load initial HTML content and configure the editable state.
    /// </summary>
    event AddInReady();

    /// <summary>
    /// Raised when the HTML content of the editor has changed.
    /// This event fires when the editor loses focus or when GetContent() is called.
    /// </summary>
    /// <param name="Html">The current HTML content of the editor.</param>
    event ContentChanged(Html: Text);

    /// <summary>
    /// Sets the HTML content displayed in the editor.
    /// Call this from the AddInReady event handler to populate the editor with existing content.
    /// </summary>
    /// <param name="Html">The HTML string to load into the editor.</param>
    procedure SetContent(Html: Text);

    /// <summary>
    /// Requests the current HTML content of the editor.
    /// The content is returned asynchronously via the ContentChanged event.
    /// </summary>
    procedure GetContent();

    /// <summary>
    /// Controls whether the editor content can be edited by the user.
    /// When set to false, the toolbar is disabled and the editing area becomes read-only.
    /// </summary>
    /// <param name="Editable">True to allow editing; false to make the editor read-only.</param>
    procedure SetEditable(Editable: Boolean);
}
