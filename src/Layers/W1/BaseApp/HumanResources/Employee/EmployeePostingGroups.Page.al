// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Setup;

page 5224 "Employee Posting Groups"
{
    ApplicationArea = BasicHR;
    Caption = 'Employee Posting Groups';
    PageType = List;
    SourceTable = "Employee Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies an identifier for the employee posting group.';
                }
                field("Payables Account"; Rec."Payables Account")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the general ledger account to use when you post payables to employees in this posting group.';
                }
                field("Debit Curr. Appln. Rndg. Acc."; Rec."Debit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                }
                field("Credit Curr. Appln. Rndg. Acc."; Rec."Credit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                }
                field("Debit Rounding Account"; Rec."Debit Rounding Account")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the general ledger account number to use when you post rounding differences from a remaining amount.';
                }
                field("Credit Rounding Account"; Rec."Credit Rounding Account")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the general ledger account number to use when you post rounding differences from a remaining amount.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Posting Group")
            {
                Caption = '&Posting Group';
                action(Alternative)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Alternative Groups';
                    Image = Relationship;
                    RunObject = Page "Alt. Employee Posting Groups";
                    RunPageLink = "Employee Posting Group" = field(Code);
                    ToolTip = 'Specifies alternative employee posting groups.';
                    Visible = AltPostingGroupsVisible;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        HumanResourcesSetup.Get();
        AltPostingGroupsVisible := HumanResourcesSetup."Allow Multiple Posting Groups";
    end;

    var
        HumanResourcesSetup: Record "Human Resources Setup";
        AltPostingGroupsVisible: Boolean;
}

