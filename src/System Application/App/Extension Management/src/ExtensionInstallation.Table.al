// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps;

/// <summary>
/// The table containing information about an extension install.
/// </summary>
/// <remarks>
/// The casing of the fields is expected to match the casing in the URL filter used when calling the installation page 2503:
/// 'ID' IS '[AppID]' AND 'PreviewKey' IS '[PreviewKey]'
/// </remarks>
table 2503 "Extension Installation"
{
    Access = Internal;
    Caption = 'Extension Installation';
    TableType = Temporary;

    fields
    {
        /// <summary>
        /// The app identifier. Should uniquely identify the application and remains static across versions.
        /// </summary>
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        /// <summary>
        /// The preview key to be used when installing a preview version of an AppSource app.
        /// </summary>
        field(2; PreviewKey; Text[2048])
        {
            Caption = 'Preview Key';
        }
        /// <summary>
        /// The Response URL for the Partner Center ingestion call back to be used when installing a version of an AppSource app.
        /// </summary>
        field(3; ResponseUrl; Text[2048])
        {
            Caption = 'Response URL';
        }
    }
}