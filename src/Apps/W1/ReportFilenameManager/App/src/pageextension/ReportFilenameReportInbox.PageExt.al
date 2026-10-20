// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;

pageextension 43000 "Report Filename Report Inbox" extends "Report Inbox"
{
    // Shows the name a scheduled report's output will download under.

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
