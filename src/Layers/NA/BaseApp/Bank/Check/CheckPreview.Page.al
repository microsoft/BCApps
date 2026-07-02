// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Provides formatted preview of check layout and content before final printing.
/// Displays payer information, payee details, and check amounts in standard check format.
/// </summary>
/// <remarks>
/// Source Table: Gen. Journal Line. Integrates with company information and address formatting.
/// Shows complete check preview including routing numbers, amounts, and remittance details.
/// </remarks>
page 404 "Check Preview"
{
    Caption = 'Check Preview';
    DataCaptionExpression = Rec."Document No." + ' ' + CheckToAddr[1];
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(Payer)
            {
                Caption = 'Payer';
                field("CompanyAddr[1]"; CompanyAddr[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the company name that will appear on the check.';
                }
                field("CompanyAddr[2]"; CompanyAddr[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Address';
                    ToolTip = 'Specifies the company address that will appear on the check.';
                }
                field("CompanyAddr[3]"; CompanyAddr[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Address 2';
                    ToolTip = 'Specifies the extended company address that will appear on the check.';
                }
                field("CompanyAddr[4]"; CompanyAddr[4])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Post Code/City';
                    ToolTip = 'Specifies the company post code and city that will appear on the check.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field(CheckStatusText; CheckStatusText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies if the check is printed.';
                }
            }
            group(Amount)
            {
                Caption = 'Amount';
                group(Control30)
                {
                    ShowCaption = false;
                    label(AmountText)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(NumberText[1]);
                        Caption = 'Amount Text';
                        ToolTip = 'Specifies the amount in letters that will appear on the check.';
                    }
                    label("Amount Text 2")
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(NumberText[2]);
                        Caption = 'Amount Text 2';
                        ToolTip = 'Specifies an additional part of the amount in letters that will appear on the check.';
                    }
                }
            }
            group(Payee)
            {
                Caption = 'Payee';
                fixed(Control1902115401)
                {
                    ShowCaption = false;
                    group("Pay to the order of")
                    {
                        Caption = 'Pay to the order of';
                        field("CheckToAddr[1]"; CheckToAddr[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Pay-to Name';
                            ToolTip = 'Specifies the name of the payee that will appear on the check.';
                        }
                        field(Address; ConcAddr(CheckToAddr))
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Address';
                            ToolTip = 'Specifies the issuers address.';
                        }
                    }
                    group(Date)
                    {
                        Caption = 'Date';
                        field(CheckDateText; CheckDateText)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the posting date for the entry.';
                        }
                        field(Text002; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder2; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder3; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                    }
                    group(Control1900724401)
                    {
                        Caption = 'Amount';
                        field(CheckAmount; CheckAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            ShowCaption = false;
                            ToolTip = 'Specifies the amount that will appear on the check.';
                        }
                        field(Placeholder4; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder5; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder6; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcCheck();
    end;

    trigger OnOpenPage()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        BankAcc2: Record "Bank Account";
        Employee: Record Employee;
        FormatAddr: Codeunit "Format Address";
        ChkTransMgt: Report "Check Translation Management";
        CheckToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        NumberText: array[2] of Text[80];
        CheckStatusText: Text[30];
        CheckAmount: Decimal;

        PrintedCheckLbl: Label 'Printed Check';
        NotPrintedCheckLbl: Label 'Not Printed Check';
        PlaceholderLbl: Label 'Placeholder';
        CheckDateFormat: Option " ","MM DD YYYY","DD MM YYYY","YYYY MM DD";
        CheckLanguage: Integer;
        DateSeparator: Option " ","-",".","/";
        CheckStyle: Option ,US,CA;
        DateIndicator: Text[10];
        CheckDateText: Text[30];

    local procedure CalcCheck()
    begin
        if (Rec."Bal. Account Type" <> Rec."Bal. Account Type"::"Bank Account") or
           not BankAcc2.Get(Rec."Bal. Account No.")
        then
            Clear(BankAcc2);
        if Rec."Check Printed" then begin
            GenJnlLine.Reset();
            GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            GenJnlLine.SetRange("Posting Date", Rec."Posting Date");
            GenJnlLine.SetRange("Document No.", Rec."Document No.");
            if Rec."Bal. Account No." = '' then
                GenJnlLine.SetRange("Bank Payment Type", GenJnlLine."Bank Payment Type"::" ")
            else
                GenJnlLine.SetRange("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Computer Check");
            GenJnlLine.SetRange("Check Printed", true);
            CheckStatusText := PrintedCheckLbl;
        end else begin
            GenJnlLine.Reset();
            GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            GenJnlLine.SetRange("Posting Date", Rec."Posting Date");
            GenJnlLine.SetRange("Document No.", Rec."Document No.");
            GenJnlLine.SetRange("Account Type", Rec."Account Type");
            GenJnlLine.SetRange("Account No.", Rec."Account No.");
            GenJnlLine.SetRange("Bal. Account Type", Rec."Bal. Account Type");
            GenJnlLine.SetRange("Bal. Account No.", Rec."Bal. Account No.");
            GenJnlLine.SetRange("Bank Payment Type", Rec."Bank Payment Type");
            CheckStatusText := NotPrintedCheckLbl;
        end;

        CheckAmount := 0;
        if GenJnlLine.Find('-') then
            repeat
                CheckAmount := CheckAmount + GenJnlLine.Amount;
            until GenJnlLine.Next() = 0;

        if CheckAmount < 0 then
            CheckAmount := 0;

        FormatTextFieldsForCheck();
    end;

    local procedure FormatTextFieldsForCheck()
    var
        RemitAddress: Record "Remit Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatTextFieldsForCheck(CheckToAddr, CheckAmount, GenJnlLine, Cust, BankAcc, Employee, Vend, Rec, IsHandled, BankAcc2, CheckDateFormat, DateSeparator, CheckLanguage, CheckStyle, CheckDateText);
        if IsHandled then
            exit;

        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                begin
                    Clear(CheckToAddr);
                    CheckToAddr[1] := GenJnlLine.Description;
                    ChkTransMgt.SetCheckPrintParams(
                      BankAcc2."Check Date Format",
                      BankAcc2."Check Date Separator",
                      BankAcc2."Country/Region Code",
                      BankAcc2."Bank Communication",
                      CheckToAddr[1],
                      CheckDateFormat,
                      DateSeparator,
                      CheckLanguage,
                      CheckStyle);
                end;
            GenJnlLine."Account Type"::Customer:
                begin
                    Cust.Get(GenJnlLine."Account No.");
                    Cust.Contact := '';
                    FormatAddr.Customer(CheckToAddr, Cust);
                    ChkTransMgt.SetCheckPrintParams(
                      Cust."Check Date Format",
                      Cust."Check Date Separator",
                      BankAcc2."Country/Region Code",
                      Cust."Bank Communication",
                      CheckToAddr[1],
                      CheckDateFormat,
                      DateSeparator,
                      CheckLanguage,
                      CheckStyle);
                end;
#pragma warning disable AA0005
            GenJnlLine."Account Type"::Vendor:
                begin
                    if GenJnlLine."Remit-to Code" = '' then begin
                        Vend.Get(GenJnlLine."Account No.");
                        Vend.Contact := '';
                        FormatAddr.Vendor(CheckToAddr, Vend);
                    end
                    else begin
                        Vend.Get(GenJnlLine."Account No.");
                        RemitAddress.Get(GenJnlLine."Remit-to Code", GenJnlLine."Account No.");
                        FormatAddr.VendorRemitToAddress(RemitAddress, CheckToAddr);
                    end;
                    ChkTransMgt.SetCheckPrintParams(
                      Vend."Check Date Format",
                      Vend."Check Date Separator",
                      BankAcc2."Country/Region Code",
                      Vend."Bank Communication",
                      CheckToAddr[1],
                      CheckDateFormat,
                      DateSeparator,
                      CheckLanguage,
                      CheckStyle);
                end;
#pragma warning restore AA0005
            GenJnlLine."Account Type"::"Bank Account":
                begin
                    BankAcc.Get(GenJnlLine."Account No.");
                    BankAcc.Contact := '';
                    FormatAddr.BankAcc(CheckToAddr, BankAcc);
                    ChkTransMgt.SetCheckPrintParams(
                      BankAcc."Check Date Format",
                      BankAcc."Check Date Separator",
                      BankAcc2."Country/Region Code",
                      BankAcc."Bank Communication",
                      CheckToAddr[1],
                      CheckDateFormat,
                      DateSeparator,
                      CheckLanguage,
                      CheckStyle);
                end;
            GenJnlLine."Account Type"::"Fixed Asset":
                GenJnlLine.FieldError("Account Type");
            GenJnlLine."Account Type"::Employee:
                begin
                    Employee.Get(GenJnlLine."Account No.");
                    FormatAddr.Employee(CheckToAddr, Employee);
                    ChkTransMgt.SetCheckPrintParams(
                      BankAcc2."Check Date Format",
                      BankAcc2."Check Date Separator",
                      BankAcc2."Country/Region Code",
                      BankAcc2."Bank Communication",
                      CheckToAddr[1],
                      CheckDateFormat,
                      DateSeparator,
                      CheckLanguage,
                      CheckStyle);
                end;
        end;

        if not ChkTransMgt.FormatNoText(NumberText, CheckAmount, CheckLanguage, GenJnlLine."Currency Code") then
            Error(NumberText[1]);
        CheckDateText := ChkTransMgt.FormatDate(Rec."Document Date", CheckDateFormat, DateSeparator, CheckLanguage, DateIndicator);

        OnAfterFormatTextFieldsForCheck(CheckToAddr);
    end;

    local procedure ConcAddr(Addr: array[8] of Text[100]) Str: Text
    var
        i: Integer;
    begin
        for i := 2 to ArrayLen(Addr) do
            if Addr[i] <> '' then
                Str := Str + Addr[i] + ', ';
        Str := DelChr(Str, '<>', ', ');
    end;

    /// <summary>
    /// Integration event raised before formatting text fields for check display.
    /// Enables custom formatting logic or field population before standard check formatting.
    /// </summary>
    /// <param name="CheckToAddr">Array of address text fields for the check</param>
    /// <param name="CheckAmount">Amount value for the check</param>
    /// <param name="GenJournalLine">General journal line associated with the check</param>
    /// <param name="Customer">Customer record when balance account type is Customer</param>
    /// <param name="BankAccount">Bank account record for the check</param>
    /// <param name="Employee">Employee record when balance account type is Employee</param>
    /// <param name="Vendor">Vendor record when balance account type is Vendor</param>
    /// <param name="Rec">Current record context for the check preview</param>
    /// <param name="IsHandled">Set to true to skip standard text field formatting</param>
    /// <remarks>
    /// Raised from FormatTextFieldsForCheck procedure before standard check text formatting.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatTextFieldsForCheck(var CheckToAddr: array[8] of Text[100]; CheckAmount: Decimal; var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; var BankAccount: Record "Bank Account"; Employee: Record Employee; var Vendor: Record Vendor; Rec: Record "Gen. Journal Line"; var IsHandled: Boolean; var BankAccount2: Record "Bank Account"; CheckDateFormat: Option; DateSeparator: Option; CheckLanguage: Integer; CheckStyle: Option; CheckDateText: Text[30])
    begin
    end;

    /// <summary>
    /// Integration event raised after formatting text fields for check display.
    /// Enables custom modifications to formatted check text fields.
    /// </summary>
    /// <param name="CheckToAddr">Array of formatted address text fields for the check</param>
    /// <remarks>
    /// Raised from FormatTextFieldsForCheck procedure after standard check text formatting.
    /// </remarks>
    [IntegrationEvent(true, false)]
    local procedure OnAfterFormatTextFieldsForCheck(var CheckToAddr: array[8] of Text[100])
    begin
    end;
}

