// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

/// <summary>
/// Provides confirmation dialog for financial voiding of posted checks with void date and type selection.
/// Allows users to specify void date and choose between unapply+void or void-only operations.
/// </summary>
/// <remarks>
/// Confirmation dialog for CheckManagement.FinancialVoidCheck operations.
/// Validates void date against original check date and provides void type options.
/// </remarks>
page 695 "Confirm Financial Void"
{
    Caption = 'Confirm Financial Void';
    PageType = ConfirmationDialog;

    layout
    {
        area(content)
        {
            label(Control19)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(VoidCheckQst);
                Editable = false;
                ShowCaption = false;
            }
            field(VoidDate; VoidDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Void Date';
                ToolTip = 'Specifies the date that the void entry will be posted regardless of the void type that is selected. All of the unapply postings will also use the Void Date, if the Unapply and Void Check type is selected.';

                trigger OnValidate()
                begin
                    if VoidDate < CheckLedgerEntry."Check Date" then
                        Error(VoidDateBeforeOriginalErr, CheckLedgerEntry.FieldCaption("Check Date"));
                end;
            }
            field(VoidType; VoidType)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Type of Void';
                OptionCaption = 'Unapply and void check,Void check only';
                ToolTip = 'Specifies how checks are voided. Unapply and Void Check: The payment will be unapplied so that the vendor ledger entry for the invoice will be open, and the payment will be reversed by the voided check. Void Check Only: The vendor ledger entry will still be closed by the payment entry, and the voided check entry will be open.';
            }
            group(Details)
            {
                Caption = 'Details';
#pragma warning disable AA0100
                field("CheckLedgerEntry.""Bank Account No."""; CheckLedgerEntry."Bank Account No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    Editable = false;
                    ToolTip = 'Specifies the bank account.';
                }
#pragma warning disable AA0100
                field("CheckLedgerEntry.""Check No."""; CheckLedgerEntry."Check No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check No.';
                    Editable = false;
                    ToolTip = 'Specifies the check number to be voided.';
                }
#pragma warning disable AA0100
                field("CheckLedgerEntry.""Bal. Account No."""; CheckLedgerEntry."Bal. Account No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(NoLbl, CheckLedgerEntry."Bal. Account Type"));
                    Editable = false;
                }
                field("CheckLedgerEntry.Amount"; CheckLedgerEntry.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount to be voided.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        OnBeforeOnOpenPage(CheckLedgerEntry, VoidDate);

        VoidDate := CheckLedgerEntry."Check Date";
        if CheckLedgerEntry."Bal. Account Type" in [CheckLedgerEntry."Bal. Account Type"::Vendor, CheckLedgerEntry."Bal. Account Type"::Customer, CheckLedgerEntry."Bal. Account Type"::Employee] then
            VoidType := VoidType::"Unapply and void check"
        else
            VoidType := VoidType::"Void check only";
    end;

    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        VoidDate: Date;
        VoidType: Option "Unapply and void check","Void check only";
#pragma warning disable AA0470
        VoidDateBeforeOriginalErr: Label 'Void Date must not be before the original %1.';
        NoLbl: Label '%1 No.';
#pragma warning restore AA0470
        VoidCheckQst: Label 'Do you want to void this check?';

    /// <summary>
    /// Initializes the page with check ledger entry data for void confirmation.
    /// </summary>
    /// <param name="NewCheckLedgerEntry">Check ledger entry to be voided</param>
    procedure SetCheckLedgerEntry(var NewCheckLedgerEntry: Record "Check Ledger Entry")
    begin
        CheckLedgerEntry := NewCheckLedgerEntry;
    end;

    /// <summary>
    /// Returns the void date selected by the user for void processing.
    /// </summary>
    /// <returns>Date to use for void operations</returns>
    procedure GetVoidDate(): Date
    begin
        exit(VoidDate);
    end;

    /// <summary>
    /// Returns the void type option selected by the user.
    /// </summary>
    /// <returns>Void type: 0=Unapply and void, 1=Void only</returns>
    procedure GetVoidType(): Integer
    begin
        exit(VoidType);
    end;

    /// <summary>
    /// Sets initial values for void date and type when opening the dialog.
    /// </summary>
    /// <param name="VoidCheckdate">Default void date to display</param>
    /// <param name="VoiceCheckType">Default void type option</param>
    procedure InitializeRequest(VoidCheckdate: Date; VoiceCheckType: Option)
    begin
        VoidDate := VoidCheckdate;
        VoidType := VoiceCheckType;
    end;

    /// <summary>
    /// Integration event raised before opening the Confirm Financial Void page.
    /// Enables custom initialization or preprocessing before void confirmation dialog display.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry being considered for financial void</param>
    /// <param name="VoidDate">Date when the void operation will be performed</param>
    /// <remarks>
    /// Raised during page OnOpenPage trigger before standard void confirmation setup.
    /// </remarks>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var CheckLedgerEntry: Record "Check Ledger Entry"; var VoidDate: Date)
    begin
    end;
}

