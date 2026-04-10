// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Media;

/// <summary>
/// MSN video player
/// </summary>
controladdin VideoPlayer
{
    RequestedHeight = 500;
    RequestedWidth = 100;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts = 'Resources\VideoPlayer\js\VideoPlayer.js';
    StartupScript = 'Resources\VideoPlayer\js\Startup.js';
    StyleSheets = 'Resources\VideoPlayer\stylesheets\VideoPlayer.css';

    /// <summary>
    /// Raised when addin is ready
    /// </summary>
    event AddInReady();

    /// <summary>
    /// Used to set the attribute to control how video is played
    /// </summary>
    /// <param name="AttributeName">
    /// The name of the attribute
    /// </param>
    /// <param name="AttributeValue">
    /// Value of the attribute
    /// </param>
    procedure SetFrameAttribute(AttributeName: Text; AttributeValue: Text);

    /// <summary>
    /// Removes specified attribute
    /// </summary>
    /// <param name="AttributeName">
    /// The name of the attribute
    /// </param>
    procedure RemoveAttribute(AttributeName: Text);

    /// <summary>
    /// Set prefered video width
    /// </summary>
    /// <param name="VideoWidth">
    /// Width of the video
    /// </param>
    procedure SetWidth(VideoWidth: Integer);

    /// <summary>
    /// Set Video Height
    /// </summary>
    /// <param name="videoHeight">Video Height</param>
    procedure SetHeight(VideoHeight: Integer);
}