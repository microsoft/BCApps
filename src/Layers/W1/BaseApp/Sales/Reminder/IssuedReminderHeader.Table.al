// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using System.Globalization;
using System.Security.AccessControl;
using System.Text;

/// <summary>
/// Stores the header information for a posted reminder document that has been issued to a customer.
/// </summary>
table 297 "Issued Reminder Header"
{
    Caption = 'Issued Reminder Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Issued Reminder List";
    LookupPageID = "Issued Reminder List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique identifier for the issued reminder document.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the customer to whom this reminder was issued.
        /// </summary>
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the customer number the reminder is for.';
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the name of the customer at the time the reminder was issued.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the customer the reminder is for.';
        }
        /// <summary>
        /// Specifies additional name information for the customer.
        /// </summary>
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        /// <summary>
        /// Specifies the street address of the customer at the time of issuing.
        /// </summary>
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the address of the customer the reminder is for.';
        }
        /// <summary>
        /// Specifies additional address information for the customer.
        /// </summary>
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the postal code of the customer's address.
        /// </summary>
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            ToolTip = 'Specifies the postal code.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the city of the customer's address.
        /// </summary>
        field(8; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the city name of the customer the reminder is for.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the customer's address.
        /// </summary>
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        /// <summary>
        /// Specifies the country or region code of the customer's address.
        /// </summary>
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the language code used for reminder text translations.
        /// </summary>
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Specifies the currency in which amounts on the reminder were calculated.
        /// </summary>
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the issued reminder.';
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the name of the contact person at the customer.
        /// </summary>
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
            ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the reminder is for.';
        }
        /// <summary>
        /// Specifies the customer's reference number or code for this document.
        /// </summary>
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The content will be printed on the related document.';
        }
        /// <summary>
        /// Specifies the first shortcut dimension code used when the reminder was posted.
        /// </summary>
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Specifies the second shortcut dimension code used when the reminder was posted.
        /// </summary>
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Specifies the customer posting group used when the reminder was posted.
        /// </summary>
        field(17; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the general business posting group used when the reminder was posted.
        /// </summary>
        field(18; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Specifies the customer's VAT registration number for tax reporting.
        /// </summary>
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        /// <summary>
        /// Specifies the reason code that explains the purpose of the reminder entry.
        /// </summary>
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Specifies the date when the reminder was posted to the general ledger.
        /// </summary>
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date that the reminder was issued on.';
        }
        /// <summary>
        /// Specifies the date of the reminder document.
        /// </summary>
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
        /// <summary>
        /// Specifies the date by which the customer was required to pay.
        /// </summary>
        field(23; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the date when payment of the amount on the reminder is due.';
        }
        /// <summary>
        /// Specifies the reminder terms code that was used for this reminder.
        /// </summary>
        field(24; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            ToolTip = 'Specifies the reminder terms code for the reminder.';
            TableRelation = "Reminder Terms";
        }
        /// <summary>
        /// Specifies the finance charge terms used for calculating interest.
        /// </summary>
        field(25; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
            TableRelation = "Finance Charge Terms";
        }
        /// <summary>
        /// Indicates whether interest charges were posted when the reminder was issued.
        /// </summary>
        field(26; "Interest Posted"; Boolean)
        {
            Caption = 'Interest Posted';
        }
        /// <summary>
        /// Indicates whether additional fees were posted when the reminder was issued.
        /// </summary>
        field(27; "Additional Fee Posted"; Boolean)
        {
            Caption = 'Additional Fee Posted';
        }
        /// <summary>
        /// Specifies the escalation level at which this reminder was issued.
        /// </summary>
        field(28; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            ToolTip = 'Specifies the reminder''s level.';
            TableRelation = "Reminder Level"."No." where("Reminder Terms Code" = field("Reminder Terms Code"));
        }
        /// <summary>
        /// Specifies the description that appeared on ledger entries when the reminder was posted.
        /// </summary>
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        /// <summary>
        /// Indicates whether comments are attached to this issued reminder.
        /// </summary>
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Reminder Comment Line" where(Type = const("Issued Reminder"),
                                                               "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total remaining amount that the customer owed on the entries included in this reminder.
        /// </summary>
        field(31; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line"."Remaining Amount" where("Reminder No." = field("No."),
                                                                               "Line Type" = const("Reminder Line"),
                                                                               "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the total of the remaining amounts on the reminder lines.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total interest amount that was charged on this reminder.
        /// </summary>
        field(32; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line".Amount where("Reminder No." = field("No."),
                                                                   Type = const("Customer Ledger Entry"),
                                                                   "Line Type" = const("Reminder Line"),
                                                                   "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Interest Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total additional fee amount that was charged on this reminder.
        /// </summary>
        field(33; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line".Amount where("Reminder No." = field("No."),
                                                                  Type = const("G/L Account"),
                                                                  "Line Type" = filter(<> "Not Due")));
            Caption = 'Additional Fee';
            ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total VAT amount that was calculated on this reminder.
        /// </summary>
        field(34; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line"."VAT Amount" where("Reminder No." = field("No."),
                                                                        "Detailed Interest Rates Entry" = const(false),
                                                                        "Line Type" = filter(<> "Not Due")));
            Caption = 'VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies how many times the reminder has been printed.
        /// </summary>
        field(35; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            ToolTip = 'Specifies how many times the document has been printed.';
        }
        /// <summary>
        /// Specifies the user who issued the reminder.
        /// </summary>
        field(36; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Specifies the number series used to assign the document number.
        /// </summary>
        field(37; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series of the original reminder before it was issued.
        /// </summary>
        field(38; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the document number of the original reminder before it was issued.
        /// </summary>
        field(39; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
            ToolTip = 'Specifies the number of the reminder from which the issued reminder was created.';
        }
        /// <summary>
        /// Specifies the source code for audit trail purposes.
        /// </summary>
        field(40; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Specifies the tax area code for sales tax calculation.
        /// </summary>
        field(41; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the customer is liable for sales tax.
        /// </summary>
        field(42; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Specifies the VAT business posting group used when the reminder was posted.
        /// </summary>
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Contains the total line fee amount charged on this reminder.
        /// </summary>
        field(44; "Add. Fee per Line"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Currency Code";
            CalcFormula = sum("Issued Reminder Line".Amount where("Reminder No." = field("No."),
                                                                   Type = const("Line Fee")));
            Caption = 'Add. Fee per Line';
            ToolTip = 'Specifies that the fee is distributed on individual reminder lines.';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the date used for VAT reporting purposes.
        /// </summary>
        field(47; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the VAT date for the reminder.';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this issued reminder has been canceled.
        /// </summary>
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
            ToolTip = 'Specifies if the issued reminder has been canceled.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the user who canceled the issued reminder.
        /// </summary>
        field(51; "Canceled By"; Code[50])
        {
            Caption = 'Canceled By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the date when the issued reminder was canceled.
        /// </summary>
        field(52; "Canceled Date"; Date)
        {
            Caption = 'Canceled Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the document number that canceled this issued reminder.
        /// </summary>
        field(53; "Canceled By Document No."; Code[20])
        {
            Caption = 'Canceled By Document No.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the regional format for dates, numbers, and currency display.
        /// </summary>
        field(54; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        /// <summary>
        /// Contains the email body text content that was used for reminder communications.
        /// </summary>
        field(55; "Email Text"; Blob)
        {
            Caption = 'Email Text';
        }
        /// <summary>
        /// Indicates whether an email has been sent for the current reminder level.
        /// </summary>
        field(56; "Sent For Current Level"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the date and time when the last email was sent for this reminder.
        /// </summary>
        field(57; "Last Email Sent Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the total number of times an email has been sent for this reminder.
        /// </summary>
        field(58; "Total Email Sent Count"; Integer)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the number of times an email has been sent for the current reminder level.
        /// </summary>
        field(59; "Last Level Email Sent Count"; Integer)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the reminder level at which the last email was sent.
        /// </summary>
        field(60; "Email Sent Level"; Integer)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the entry number of a failed email in the outbox for retry purposes.
        /// </summary>
        field(61; "Failed Email Outbox Entry No."; BigInteger)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the company bank account for receiving payments referenced on this reminder.
        /// </summary>
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        /// <summary>
        /// Specifies the combination of dimension values that were applied to this reminder.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        /// <summary>
        /// Specifies the reminder automation group code that was used to create this reminder.
        /// </summary>
        field(500; "Reminder Automation Code"; Code[50])
        {
            DataClassification = CustomerContent;
            TableRelation = "Reminder Action Group"."Code";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Posting Date")
        {
        }
        key(Key3; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Customer No.", Name, "Posting Date")
        {
        }
    }

    trigger OnDelete()
    begin
        TestField("No. Printed");
        LockTable();
        ReminderIssue.DeleteIssuedReminderLines(Rec);

        ReminderCommentLine.SetRange(Type, ReminderCommentLine.Type::"Issued Reminder");
        ReminderCommentLine.SetRange("No.", "No.");
        ReminderCommentLine.DeleteAll();
    end;

    var
        ReminderCommentLine: Record "Reminder Comment Line";
        ReminderIssue: Codeunit "Reminder-Issue";
        DimMgt: Codeunit DimensionManagement;
        SuppresSendDialogQst: Label 'Do you want to suppress send dialog?';

    /// <summary>
    /// Prints or sends issued reminders based on the specified options.
    /// </summary>
    /// <param name="ShowRequestForm">True to show the report request form before printing.</param>
    /// <param name="SendAsEmail">True to send reminders by email instead of printing.</param>
    /// <param name="HideDialog">True to suppress the email send dialog.</param>
    procedure PrintRecords(ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderHeaderToSend: Record "Issued Reminder Header";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if SendAsEmail then begin
            IssuedReminderHeader.Copy(Rec);
            if (not HideDialog) and (IssuedReminderHeader.Count > 1) then
                if Confirm(SuppresSendDialogQst) then
                    HideDialog := true;
            if IssuedReminderHeader.FindSet() then
                repeat
                    IssuedReminderHeaderToSend.Copy(IssuedReminderHeader);
                    IssuedReminderHeaderToSend.SetRecFilter();
                    DocumentSendingProfile.TrySendToEMail(
                      DummyReportSelections.Usage::Reminder.AsInteger(), IssuedReminderHeaderToSend, IssuedReminderHeaderToSend.FieldNo("No."),
                      ReportDistributionMgt.GetFullDocumentTypeText(Rec), IssuedReminderHeaderToSend.FieldNo("Customer No."), not HideDialog)
                until IssuedReminderHeader.Next() = 0;
        end else
            DocumentSendingProfile.TrySendToPrinter(
              DummyReportSelections.Usage::Reminder.AsInteger(), Rec,
              IssuedReminderHeaderToSend.FieldNo("Customer No."), ShowRequestForm);

        OnAfterPrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog);
    end;

    /// <summary>
    /// Clears the sent email tracking fields when the reminder level changes.
    /// </summary>
    /// <param name="IssuedReminderHeader">The issued reminder header to update.</param>
    procedure ClearSentEmailFieldsOnLevelUpdate(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader."Sent For Current Level" := false;
        IssuedReminderHeader."Last Level Email Sent Count" := 0;
    end;

    /// <summary>
    /// Opens the Navigate page to show all related ledger entries for this issued reminder.
    /// </summary>
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    /// <summary>
    /// Increments the print count for this issued reminder.
    /// </summary>
    procedure IncrNoPrinted()
    begin
        ReminderIssue.IncrNoPrinted(Rec);
    end;

    /// <summary>
    /// Opens the dimension set entries page to view dimensions assigned to this reminder.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    /// <summary>
    /// Retrieves the customer's VAT registration number for document printing.
    /// </summary>
    /// <returns>Returns the VAT registration number.</returns>
    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    /// <summary>
    /// Retrieves the caption for the VAT registration number field.
    /// </summary>
    /// <returns>Returns the field caption text.</returns>
    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        exit(FieldCaption("VAT Registration No."));
    end;

    /// <summary>
    /// Calculates the total VAT amount for line fees on this reminder.
    /// </summary>
    /// <returns>Returns the sum of VAT amounts for line fee entries.</returns>
    procedure CalculateLineFeeVATAmount(): Decimal
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetCurrentKey("Reminder No.", Type, "Line Type");
        IssuedReminderLine.SetRange("Reminder No.", "No.");
        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"Line Fee");
        IssuedReminderLine.CalcSums("VAT Amount");
        exit(IssuedReminderLine."VAT Amount");
    end;

    /// <summary>
    /// Calculates the total amount including VAT for all lines on this reminder.
    /// </summary>
    /// <returns>Returns the sum of amounts and VAT amounts for all reminder lines.</returns>
    procedure CalculateTotalIncludingVAT(): Decimal
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        ReminderInterestAmount: Decimal;
        InterestAmountTotal: Decimal;
        VATAmountTotal: Decimal;
        RemainingAmountTotal: Decimal;
    begin
        IssuedReminderLine.SetRange("Reminder No.", Rec."No.");

        IssuedReminderLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if IssuedReminderLine.IsEmpty() then
            exit(0);

        IssuedReminderLine.FindSet();
        repeat
            ReminderInterestAmount := 0;
            case IssuedReminderLine.Type of
                IssuedReminderLine.Type::"G/L Account":
                    "Remaining Amount" := IssuedReminderLine.Amount;
                IssuedReminderLine.Type::"Line Fee":
                    "Remaining Amount" := IssuedReminderLine.Amount;
                IssuedReminderLine.Type::"Customer Ledger Entry":
                    ReminderInterestAmount := IssuedReminderLine.Amount;
            end;

            InterestAmountTotal += ReminderInterestAmount;
            RemainingAmountTotal += IssuedReminderLine."Remaining Amount";
            VATAmountTotal += IssuedReminderLine."VAT Amount";
        until IssuedReminderLine.Next() = 0;
        exit(RemainingAmountTotal + InterestAmountTotal + VATAmountTotal);
    end;

    /// <summary>
    /// Raised after printing the issued reminder records.
    /// </summary>
    /// <param name="IssuedReminderHeader">The issued reminder header record.</param>
    /// <param name="ShowRequestForm">Indicates whether to show the request form.</param>
    /// <param name="SendAsEmail">Indicates whether to send as email.</param>
    /// <param name="HideDialog">Indicates whether to hide dialogs.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintRecords(var IssuedReminderHeader: Record "Issued Reminder Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing the issued reminder records.
    /// </summary>
    /// <param name="IssuedReminderHeader">The issued reminder header record.</param>
    /// <param name="ShowRequestForm">Indicates whether to show the request form.</param>
    /// <param name="SendAsEmail">Indicates whether to send as email.</param>
    /// <param name="HideDialog">Indicates whether to hide dialogs.</param>
    /// <param name="IsHandled">Set to true to skip default printing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var IssuedReminderHeader: Record "Issued Reminder Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the Cancel Issued Reminders report for the selected issued reminder records.
    /// </summary>
    /// <param name="IssuedReminderHeader">The issued reminder header records to cancel.</param>
    procedure RunCancelIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(IssuedReminderHeader);
        IssuedReminderHeader.SetFilter(
          "No.",
          SelectionFilterManagement.GetSelectionFilter(RecRef, IssuedReminderHeader.FieldNo("No.")));

        REPORT.RunModal(REPORT::"Cancel Issued Reminders", true, false, IssuedReminderHeader);
    end;

    /// <summary>
    /// Raised to get report parameters for the issued reminder report.
    /// </summary>
    /// <param name="LogInteraction">Returns whether to log interaction.</param>
    /// <param name="ShowNotDueAmounts">Returns whether to show not due amounts.</param>
    /// <param name="ShowMIRLines">Returns whether to show MIR lines.</param>
    /// <param name="ReportID">The report ID being run.</param>
    /// <param name="Handled">Set to true to indicate parameters are provided.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnGetReportParameters(var LogInteraction: Boolean; var ShowNotDueAmounts: Boolean; var ShowMIRLines: Boolean; ReportID: Integer; var Handled: Boolean)
    begin
    end;
}
