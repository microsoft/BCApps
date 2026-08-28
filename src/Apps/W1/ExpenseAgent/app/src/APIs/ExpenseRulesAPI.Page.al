// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6923 "Expense Rules API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Rule';
    EntitySetCaption = 'Expense Rules';
    EntityName = 'expenseRule';
    EntitySetName = 'expenseRules';
    PageType = API;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Rule Header";
    AboutText = 'Provides access to the data from the Expense Rule Header table';

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
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                }
                field(expenseLocation; Rec."Expense Location")
                {
                    Caption = 'Expense Location';
                }
                field(effectiveDate; Rec."Effective Date")
                {
                    Caption = 'Effective Date';
                }
                field(requiredSpecificMerchant; Rec."Required Specific Merchant")
                {
                    Caption = 'Required Specific Merchant';
                }
                field(specificMerchantName; Rec."Specific Merchant Name")
                {
                    Caption = 'Specific Merchant Name';
                }
                field(justificationRequired; Rec."Justification Required")
                {
                    Caption = 'Justification Required';
                }
                field(currencyCode; CurrencyCodeDisplay)
                {
                    Caption = 'Currency Code';

                    trigger OnValidate()
                    begin
                        Rec."Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay);
                    end;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }

                part(ruleConditions; "Expense Rule Conditions API")
                {
                    Caption = 'Rule Conditions';
                    EntityName = 'expenseRuleCondition';
                    EntitySetName = 'expenseRuleConditions';
                    SubPageLink = "Expense Category Code" = field("Expense Category Code"),
                                "Expense Location" = field("Expense Location"),
                                "Effective Date" = field("Effective Date");
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
        // Avoid JIT load consistency errors by ensuring fields read in OnAfterGetRecord are included in the initial record buffer.
        Rec.AddLoadFields("Currency Code");
    end;

    trigger OnAfterGetRecord()
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Currency Code");
    end;

    trigger OnNewRecord(Belowx: Boolean)
    begin
        CurrencyCodeDisplay := '';
    end;

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        CurrencyCodeDisplay: Code[10];
}