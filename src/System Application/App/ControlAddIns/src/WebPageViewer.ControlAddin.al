// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

controladdin WebPageViewer
{
    RequestedHeight = 320;
    MinimumHeight = 180;
    RequestedWidth = 300;
    MinimumWidth = 200;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'Resources\WebPageViewer\js\WebPageViewerHelper.js',
              'Resources\WebPageViewer\js\WebPageViewer.js';
    StartupScript = 'Resources\WebPageViewer\js\Startup.js';
    RecreateScript = 'Resources\WebPageViewer\js\Recreate.js';
    RefreshScript = 'Resources\WebPageViewer\js\Refresh.js';
    StyleSheets = 'Resources\WebPageViewer\stylesheets\WebPageViewer.css';
    Images = 'Resources\WebPageViewer\images\Callback.html',
             'Resources\WebPageViewer\images\Loader.gif';

    /// <summary>
    /// Event raised when addin is done loading
    /// </summary>
    event ControlAddInReady(CallbackUrl: Text);

    /// <summary>
    /// Event raised when page is done loading
    /// </summary>
    event DocumentReady();

    /// <summary>
    /// Event raised when callback url is triggered
    /// </summary>
    event Callback(Data: Text);

    /// <summary>
    /// Event will be fired when the control add-in should be refreshed.
    /// </summary>
    event Refresh(CallbackUrl: Text);

    /// <summary>
    /// Function that initializes iframe
    /// Call this before SetContent or Navigate.
    /// </summary>        
    /// <param name="Ratio">The ratio of width to height of iframe. For example "16:9".</param>
    procedure InitializeIFrame(Ratio: Text);

    /// <summary>
    /// Function that initializes iframe, ignoring ratio values
    /// Call this before SetContent or Navigate.
    /// </summary>
    procedure InitializeFullIFrame();

    /// <summary>
    /// Function that sets the content html
    /// </summary>        
    /// <param name="Html">The html content to display.</param>
    procedure SetContent(Html: Text);

    /// <summary>
    /// Function that sets the content html and executes some JavaScript
    /// </summary>        
    /// <param name="Html">The html content to display.</param>
    /// <param name="Javascript">JavaScript to execute.</param>
    procedure SetContent(Html: Text; JavaScript: Text);

    /// <summary>
    /// Function that sets the content url
    /// </summary>        
    /// <param name="Url">Url to display.</param>
    procedure Navigate(Url: Text);

    /// <summary>
    /// Function that sets the content url with parameter data
    /// </summary>        
    /// <param name="Url">Url to display.</param>
    /// <param name="Method">HTTP method to use.</param>
    /// <param name="Data">Data to send (JSON encoded string).</param>
    procedure Navigate(Url: Text; Method: Text; Data: Text);

    /// <summary>
    /// Function to post a message to parent window.
    /// </summary>
    /// <param name="Message">Data to be sent to the other window</param>
    /// <param name="TargetOrigin">Specifies what the origin of otherWindow must be for the event to be dispatched, either as the literal string "*" (indicating no preference) or as a URI.</param>
    /// <param name="ConvertToJson">Flag indicating whether we must convert message to Json or not.</param>
    procedure PostMessage(Message: Text; TargetOrigin: Text; ConvertToJson: Boolean);

    /// <summary>
    /// Function to force hyperlinks to open in a new page
    /// </summary>
    procedure LinksOpenInNewWindow();

    /// <summary>
    /// Function to trigger a WebPageViewerEvent with custom data
    /// </summary>
    /// <param name="Data">The data to pass in the event.</param>
    procedure InvokeEvent(Data: Text);

    /// <summary>
    /// Function to subscribe to window events and trigger a WebPageViewerEvent with
    /// the data provided by the event
    /// </summary>
    /// <param name="EventName">The name of window event</param>
    /// <param name="Origin">Filters event by origin of the publisher</param>
    procedure SubscribeToEvent(EventName: Text; Origin: Text);

    /// <summary>
    /// Function to ignore callbacks occuring due to subscribed events.
    /// This will improve performance by telling client not to send messages back
    /// to server if not required.
    /// </summary>
    /// <param name="eventName">The event name passed to <see cref="SubscribeToEvent(string, string)"/> whose callback need to be ignored.</param>
    /// <param name="callbackResults">The results of the callback that need to be ignored.</param>
    /// <remarks>Send empty callbackResults to undo previous entry.</remarks>
    procedure SetCallbacksFromSubscribedEventToIgnore(EventName: Text; CallbackResults: JsonArray);
}