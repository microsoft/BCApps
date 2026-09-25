// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 8201 "Expense Agent Module Setup"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Expense Agent Module Setup';
    SourceTable = "Expense Agent Module Setup";
    Extensible = false;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Create entries in Job Queue"; Rec."Create entries in Job Queue")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InitRecord();
    end;
}