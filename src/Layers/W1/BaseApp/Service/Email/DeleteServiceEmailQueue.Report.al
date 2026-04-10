// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Email;

report 6006 "Delete Service Email Queue"
{
    Caption = 'Delete Service Email Queue';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Email Queue"; "Service Email Queue")
        {
            DataItemTableView = sorting(Status, "Sending Date");
            RequestFilterFields = Status, "Sending Date";

            trigger OnAfterGetRecord()
            begin
                i := i + 1;
                Delete();
            end;

            trigger OnPostDataItem()
            begin
                if i > 1 then
                    Message(Text000, i)
                else
                    Message(Text001, i);
            end;

            trigger OnPreDataItem()
            begin
                i := 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 entries were deleted.';
        Text001: Label '%1 entry was deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        i: Integer;
}

