// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

/// <summary>
/// Configuration page for payroll import settings and default journal assignments.
/// Provides setup interface for user accounts and journal template preferences.
/// </summary>
/// <remarks>
/// Source Table: Payroll Setup (1660). Environment-specific visibility controlled by PayrollManagement codeunit.
/// </remarks>
page 1660 "Payroll Setup"
{
    Caption = 'Payroll Setup';
    PageType = Card;
    SourceTable = "Payroll Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user account.';
                }
                field("General Journal Template Name"; Rec."General Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the general journal template that is used for import.';
                }
                field("General Journal Batch Name"; Rec."General Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Show;
                    ToolTip = 'Specifies the name of the general journal batch that is used for import.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        PayrollManagement: Codeunit "Payroll Management";
    begin
        Show := PayrollManagement.ShowPayrollForTestInNonSaas();
        if not Show then
            Show := true
    end;

    var
        Show: Boolean;
}

