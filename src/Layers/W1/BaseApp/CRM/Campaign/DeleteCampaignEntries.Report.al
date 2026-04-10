// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

report 5189 "Delete Campaign Entries"
{
    Caption = 'Delete Campaign Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Campaign Entry"; "Campaign Entry")
        {
            RequestFilterFields = "Entry No.", "Campaign No.", Date, "Salesperson Code";

            trigger OnAfterGetRecord()
            begin
                NoOfToDos := NoOfToDos + 1;
                Delete(true);
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Canceled, true);
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

    trigger OnPostReport()
    begin
        Message(Text000, NoOfToDos, "Campaign Entry".TableCaption());
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 has been deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NoOfToDos: Integer;
}

