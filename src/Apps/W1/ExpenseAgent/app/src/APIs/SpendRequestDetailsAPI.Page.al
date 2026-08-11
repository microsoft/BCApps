// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

page 7102 "Spend Request Details API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Spend Request Detail';
    EntitySetCaption = 'Spend Request Details';
    DelayedInsert = true;
    EntityName = 'spendRequestDetail';
    EntitySetName = 'spendRequestDetails';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Spend Request Detail";
    AboutText = 'Provides access to data from the Spend Request Detail table';
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
                    Caption = 'Spend Request No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(expectedAmount; Rec."Expected Amount")
                {
                    Caption = 'Expected Amount';
                }
                field(currencyExchangeRate; Rec."Currency Exchange Rate")
                {
                    Caption = 'Currency Exchange Rate';
                    Editable = false;
                }
                field(expectedAmountLCY; Rec."Expected Amount (LCY)")
                {
                    Caption = 'Expected Amount (LCY)';
                    Editable = false;
                }
                field(glAccountNo; Rec."G/L Account No.")
                {
                    Caption = 'G/L Account No.';
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
