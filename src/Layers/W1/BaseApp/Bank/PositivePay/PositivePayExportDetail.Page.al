// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using System.Security.User;

/// <summary>
/// Displays detailed check information available for positive pay export in a list part format.
/// This page shows check ledger entries that can be included in positive pay file generation.
/// </summary>
/// <remarks>
/// The Positive Pay Export Detail page is typically used as a subform within the main export interface
/// to show users which checks are available for export. It displays check ledger entry information
/// including check numbers, amounts, payees, and dates in a read-only format. The page allows users
/// to review the checks that will be included in the positive pay file before proceeding with the export.
/// Filtering and sorting capabilities help users identify specific checks within large datasets.
/// </remarks>
page 1234 "Positive Pay Export Detail"
{
    Caption = 'Positive Pay Export Detail';
    DelayedInsert = true;
    Editable = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Check Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                }
                field("Check Date"; Rec."Check Date")
                {
                    ApplicationArea = Suite;
                }
                field("Check No."; Rec."Check No.")
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                }
                field("Entry Status"; Rec."Entry Status")
                {
                    ApplicationArea = Suite;
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bank Account Ledger Entry No."; Rec."Bank Account Ledger Entry No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Original Entry Status"; Rec."Original Entry Status")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Suite;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetFilters();
    end;

    var
        LastUploadDate: Date;
        UploadCutoffDate: Date;

    /// <summary>
    /// Sets the filter parameters for displaying check ledger entries within the specified date range and bank account.
    /// </summary>
    /// <param name="NewLastUploadDate">The last upload date for filtering check entries.</param>
    /// <param name="NewUploadCutoffDate">The cutoff date for filtering check entries.</param>
    /// <param name="NewBankAcctNo">The bank account number to filter check entries.</param>
    procedure Set(NewLastUploadDate: Date; NewUploadCutoffDate: Date; NewBankAcctNo: Code[20])
    begin
        LastUploadDate := NewLastUploadDate;
        UploadCutoffDate := NewUploadCutoffDate;
        Rec.SetRange("Bank Account No.", NewBankAcctNo);
        SetFilters();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Applies bank payment type filter to the check ledger entries displayed in the page.
    /// </summary>
    /// <param name="BankPaymentType">The bank payment type to filter by, or blank to show all types.</param>
    procedure SetBankPaymentType(BankPaymentType: Enum "Bank Payment Type")
    begin
        if BankPaymentType = Enum::"Bank Payment Type"::" " then
            Rec.SetRange("Bank Payment Type")
        else
            Rec.SetRange("Bank Payment Type", BankPaymentType);
        SetFilters();
        CurrPage.Update(false);
    end;

    local procedure SetFilters()
    begin
        Rec.SetRange("Check Date", LastUploadDate, UploadCutoffDate);
        Rec.SetRange("Positive Pay Exported", false);
    end;
}

