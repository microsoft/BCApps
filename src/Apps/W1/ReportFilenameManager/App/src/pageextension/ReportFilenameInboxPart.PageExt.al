// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
pageextension 50111 "Report Filename Inbox Part" extends "Report Inbox Part"
{
    // The same column on the Report Inbox part that sits on the Role Centers. It drills down
    // through the same ShowReport, so it is named by this feature too - and showing the name on
    // one of the two pages and not the other would be the same invisibility the field exists to
    // remove, just in a place people look at more often.
    //
    // This stays in the shipped app, like the extension on the full page.

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
