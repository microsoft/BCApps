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
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Check Date"; Rec."Check Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the check date if a check is printed.';
                }
                field("Check No."; Rec."Check No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the check number if a check is printed.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a printing description for the check ledger entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount on the check ledger entry.';
                }
                field("Entry Status"; Rec."Entry Status")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the printing (and posting) status of the check ledger entry.';
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                    Visible = false;
                }
                field("Bank Account Ledger Entry No."; Rec."Bank Account Ledger Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the entry number of the bank account ledger entry from which the check ledger entry was created.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the posting date of the check ledger entry.';
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the document type linked to the check ledger entry. For example, Payment.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the document number on the check ledger entry.';
                    Visible = false;
                }
                field("Original Entry Status"; Rec."Original Entry Status")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the status of the entry before you changed it.';
                    Visible = false;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the bank account used for the check ledger entry.';
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
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
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
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

    procedure Set(NewLastUploadDate: Date; NewUploadCutoffDate: Date; NewBankAcctNo: Code[20])
    begin
        LastUploadDate := NewLastUploadDate;
        UploadCutoffDate := NewUploadCutoffDate;
        Rec.SetRange("Bank Account No.", NewBankAcctNo);
        SetFilters();
        CurrPage.Update(false);
    end;

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

