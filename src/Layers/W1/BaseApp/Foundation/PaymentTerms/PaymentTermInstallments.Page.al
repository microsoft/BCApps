// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using System.Environment.Configuration;

page 8840 "Payment Term Installments"
{
    Caption = 'Payment Term Installments';
    DataCaptionFields = "Payment Terms Code";
    PageType = List;
    SourceTable = "Payment Term Installment";
    AutoSplitKey = true;
    DelayedInsert = true;
    PopulateAllFields = true;
    InstructionalText = 'These rules enable installment schedules on standalone sales invoices. Supported invoices post one receivable per installment. Other document flows and Italy legacy integration are not yet supported.';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Allocation Type"; Rec."Allocation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment %"; Rec."Payment %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec."Allocation Type" = Rec."Allocation Type"::Percentage;
                    ShowMandatory = Rec."Allocation Type" = Rec."Allocation Type"::Percentage;
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field("Discount Date Calculation"; Rec."Discount Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = Rec."Discount %" <> 0;
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateRules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Validate rules';
                Image = Check;
                ToolTip = 'Check that the installment rules form a complete allocation and contain the required date formulas. Calculated dates and amounts are checked when calculating a schedule.';

                trigger OnAction()
                var
                    TempPlanLine: Record "Installment Calculation Line" temporary;
                    InstallmentCalculation: Codeunit "Installment Calculation";
                begin
                    CurrPage.SaveRecord();
                    Rec.TestField("Payment Terms Code");
                    if InstallmentCalculation.CopyPaymentTerms(Rec."Payment Terms Code", CreateGuid(), TempPlanLine) then
                        Message(RulesValidMsg);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureKeyManagement.CheckPaymentInstallmentsEnabled();
    end;

    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
        RulesValidMsg: Label 'The installment rules are valid.';
}
