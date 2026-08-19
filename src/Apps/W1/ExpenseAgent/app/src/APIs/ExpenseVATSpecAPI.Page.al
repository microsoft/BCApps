// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Telemetry;

page 7085 "Expense VAT Spec. API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense VAT Specification';
    EntitySetCaption = 'Expense VAT Specifications';
    DelayedInsert = true;
    EntityName = 'expenseVATSpecification';
    EntitySetName = 'expenseVATSpecifications';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense VAT Specification";
    AboutText = 'Provides access to data from the Expense VAT Specification table';
    ModifyAllowed = false;
    DeleteAllowed = false;
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
                field(expenseNo; Rec."Expense No.")
                {
                    Caption = 'Expense No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(vatPercent; Rec."VAT %")
                {
                    Caption = 'VAT %';
                }
                field(vatBaseAmount; Rec."VAT Base Amount")
                {
                    Caption = 'VAT Base Amount';
                }
                field(vatAmount; Rec."VAT Amount")
                {
                    Caption = 'VAT Amount';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(vatDifference; Rec."VAT Difference")
                {
                    Caption = 'VAT Difference';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    Caption = 'VAT Prod. Posting Group';
                }
                field(vatAmountLCY; Rec."VAT Amount (LCY)")
                {
                    Caption = 'VAT Amount (LCY)';
                }
                field(vatBaseAmountLCY; Rec."VAT Base Amount (LCY)")
                {
                    Caption = 'VAT Base Amount (LCY)';
                }
                field(amountLCY; Rec."Amount (LCY)")
                {
                    Caption = 'Amount (LCY)';
                }
                field(expenseCategory; Rec."Expense Category")
                {
                    Caption = 'Expense Category';
                }
                field(expenseSubcategory; Rec."Expense Subcategory")
                {
                    Caption = 'Expense Subcategory';
                }
                field(source; Rec.Source)
                {
                    Caption = 'Source';
                }
                field(confidence; Rec.Confidence)
                {
                    Caption = 'Confidence';
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        VerifyExpenseAgentCaller();
        Rec.Source := Rec.Source::Agent;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InsertVATSpecification(Rec);
        exit(false);
    end;

    internal procedure InsertVATSpecification(var ExpenseVATSpecification: Record "Expense VAT Specification")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        VerifyExpenseAgentCaller();
        ExpenseVATSpecification.Source := ExpenseVATSpecification.Source::Agent;
        BindSubscription(ExpenseAgentAPIValidation);
        ExpenseVATSpecification.Insert(true);
        UnbindSubscription(ExpenseAgentAPIValidation);

        TelemetryDimensions.Add('HasExpenseCategory', Format(ExpenseVATSpecification."Expense Category" <> ''));
        TelemetryDimensions.Add('HasExpenseSubcategory', Format(ExpenseVATSpecification."Expense Subcategory" <> ''));
        TelemetryDimensions.Add('HasVATProductPostingGroup', Format(ExpenseVATSpecification."VAT Prod. Posting Group" <> ''));
        FeatureTelemetry.LogUptake('0000UZ7', ExpenseAgentSetup.GetFeatureName(), Enum::"Feature Uptake Status"::Used, TelemetryDimensions);
    end;

    var
        ExpenseAgentCallerRequiredErr: Label 'Only the Expense Agent application can create agent-authored VAT specifications.';

    local procedure VerifyExpenseAgentCaller()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        if not ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then
            Error(ExpenseAgentCallerRequiredErr);
    end;
}
