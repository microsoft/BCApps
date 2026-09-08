// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

page 7135 "Travel Request Details API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Travel Request Detail';
    EntitySetCaption = 'Travel Request Details';
    DelayedInsert = true;
    EntityName = 'travelRequestDetail';
    EntitySetName = 'travelRequestDetails';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Spend Request Detail";
    AboutText = 'Provides access to data from the Travel Request Detail table';
    AutoSplitKey = true;
    Permissions = tabledata "Spend Request Detail" = rimd,
                  tabledata "Spend Request" = rm;

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
                field(travelRequestNo; Rec."Spend Request No.")
                {
                    Caption = 'Travel Request No.';
                    ToolTip = 'Specifies the travel request for the detail line.';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the travel request detail.';
                }
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                    ToolTip = 'Specifies the expense category for the travel request detail.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(currencyCode; CurrencyCodeDisplay)
                {
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the currency used for estimation. The local currency is represented by its currency code in the API.';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Currency Code", CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay));
                    end;
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

    trigger OnOpenPage()
    begin
        Rec.AddLoadFields("Currency Code");
    end;

    trigger OnAfterGetRecord()
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Currency Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(CurrencyCodeDisplay);
    end;

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        CurrencyCodeDisplay: Code[10];
}
