// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6901 "Expense Rule Card"
{
    Caption = 'Expense Rule Card';
    PageType = Card;
    SourceTable = "Expense Rule Header";
    ApplicationArea = Basic, Suite;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ToolTip = 'Specifies the expense category for this rule.';
                }
                field("Expense Location"; Rec."Expense Location")
                {
                    ToolTip = 'Specifies the expense location for this rule.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ToolTip = 'Specifies when this rule becomes effective.';
                }
                field("Justification Required"; Rec."Justification Required")
                {
                    ToolTip = 'Specifies when justification is required for expenses under this rule.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the required currency code for expenses under this rule. Leave blank if any currency is allowed.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies the required unit of measure code for mileage expenses under this rule (e.g., Miles, Kilometers). Leave blank if any unit of measure is allowed.';
                }
            }

            group(Merchant)
            {
                Caption = 'Merchant Requirements';

                field("Required Specific Merchant"; Rec."Required Specific Merchant")
                {
                    ToolTip = 'Specifies if a specific merchant is required for this expense category and location.';
                }
                field("Specific Merchant Name"; Rec."Specific Merchant Name")
                {
                    ToolTip = 'Specifies the required merchant name.';
                    Enabled = Rec."Required Specific Merchant";
                }
            }

            part("Rule Conditions"; "Expense Rule Conditions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Rule Conditions';
                SubPageLink = "Expense Category Code" = field("Expense Category Code"),
                             "Expense Location" = field("Expense Location"),
                             "Effective Date" = field("Effective Date");
            }
        }
    }
}