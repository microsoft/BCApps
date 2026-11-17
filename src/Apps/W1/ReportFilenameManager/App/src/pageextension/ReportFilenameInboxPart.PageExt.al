// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;

pageextension 8126 "Report Filename Inbox Part" extends "Report Inbox Part"
{
    // Shows the stored file name on the Role Center part, as on the full Report Inbox page.

    layout
    {
        addlast(Group)
        {
            field("File Name"; Rec."File Name")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
}
