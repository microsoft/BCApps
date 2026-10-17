// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
pageextension 50110 "Report Filename Report Inbox" extends "Report Inbox"
{
    // Shows the name a scheduled report's output will download under. Without this the name is
    // stored, honoured and invisible: somebody checking whether the feature worked would have
    // to read the table to find out, which is a poor answer to "did it name my file?".
    //
    // This stays in the shipped app: a column the app adds to Base Application's page, for the
    // field the app adds to its table.

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
