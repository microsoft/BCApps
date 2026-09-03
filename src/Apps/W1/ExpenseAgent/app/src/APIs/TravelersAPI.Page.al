// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7103 "Travelers API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Traveler';
    EntitySetCaption = 'Travelers';
    DelayedInsert = true;
    EntityName = 'traveler';
    EntitySetName = 'travelers';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = Traveler;
    AboutText = 'Provides access to data from the Traveler table';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(spendRequestNo; Rec."Spend Request No.")
                {
                    Caption = 'Travel Request No.';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(expenseUserNo; Rec."Expense User No.")
                {
                    Caption = 'Expense User No.';
                }
                field(expenseUserName; Rec."Expense User Name")
                {
                    Caption = 'Expense User Name';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}
