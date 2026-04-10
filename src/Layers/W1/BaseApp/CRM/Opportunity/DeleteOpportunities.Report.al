// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Comment;

report 5182 "Delete Opportunities"
{
    Caption = 'Delete Opportunities';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Opportunity; Opportunity)
        {
            DataItemTableView = where(Closed = const(true));
            RequestFilterFields = "No.", "Date Closed", "Salesperson Code", "Campaign No.", "Contact No.", "Sales Cycle Code";

            trigger OnAfterGetRecord()
            begin
                RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::Opportunity);
                RMCommentLine.SetRange("No.", "No.");
                RMCommentLine.DeleteAll();

                OppEntry.SetRange("Opportunity No.", "No.");
                OppEntry.DeleteAll();

                Delete();
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
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        OppEntry: Record "Opportunity Entry";
}

