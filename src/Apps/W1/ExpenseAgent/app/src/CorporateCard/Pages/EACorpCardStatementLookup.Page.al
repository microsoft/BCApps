// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7440 "EA Corp Card Statement Lookup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Statements';
    Editable = false;
    PageType = List;
    SourceTable = "EA Corp Card Statement";
    SourceTableView = sorting("Statement Date") order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Statement Entry No."; Rec."Statement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period End Date"; Rec."Period End Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement Total"; Rec."Statement Total")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}
