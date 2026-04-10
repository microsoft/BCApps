// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

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
using System.Globalization;
using System.Security.AccessControl;
using System.Text;

/// <summary>
/// Stores header information for posted finance charge memos including customer details, amounts, and cancellation status.
/// </summary>
table 304 "Issued Fin. Charge Memo Header"
{
    Caption = 'Issued Fin. Charge Memo Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Issued Fin. Charge Memo List";
    LookupPageID = "Issued Fin. Charge Memo List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique document number of the issued finance charge memo.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the customer who received this finance charge memo.
        /// </summary>
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the customer number the finance charge memo is for.';
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the name of the customer at the time the memo was issued.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the customer the finance charge memo is for.';
        }
        /// <summary>
        /// Specifies additional name information for the customer.
        /// </summary>
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        /// <summary>
        /// Specifies the street address of the customer at the time the memo was issued.
        /// </summary>
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the address of the customer the finance charge memo is for.';
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
            ToolTip = 'Specifies the city name of the customer the finance charge memo is for.';
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
        /// Specifies the language code used for the finance charge memo document.
        /// </summary>
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Specifies the currency code for amounts on the issued finance charge memo.
        /// </summary>
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the code of the currency that the issued finance charge memo is in.';
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the contact person at the customer.
        /// </summary>
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
            ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the finance charge memo is for.';
        }
        /// <summary>
        /// Contains the customer's reference information for this finance charge memo.
        /// </summary>
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The content will be printed on the related document.';
        }
        /// <summary>
        /// Specifies the first global dimension code assigned to the memo.
        /// </summary>
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Specifies the second global dimension code assigned to the memo.
        /// </summary>
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Specifies the customer posting group used when the memo was posted.
        /// </summary>
        field(17; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            ToolTip = 'Specifies the customer''Âs market type to link business transactions to.';
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the general business posting group used when the memo was posted.
        /// </summary>
        field(18; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Specifies the customer's VAT registration number.
        /// </summary>
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        /// <summary>
        /// Specifies the reason code assigned to the finance charge memo.
        /// </summary>
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Specifies the date when the finance charge memo was posted to the general ledger.
        /// </summary>
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date that the finance charge memo was issued on.';
        }
        /// <summary>
        /// Specifies the date of the finance charge memo document.
        /// </summary>
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
        /// <summary>
        /// Specifies the date by which payment was expected from the customer.
        /// </summary>
        field(23; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the date when payment of the finance charge memo is due.';
        }
        /// <summary>
        /// Specifies the finance charge terms code that was used to create the memo.
        /// </summary>
        field(25; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
            TableRelation = "Finance Charge Terms";
        }
        /// <summary>
        /// Indicates whether interest amounts were posted to the general ledger.
        /// </summary>
        field(26; "Interest Posted"; Boolean)
        {
            Caption = 'Interest Posted';
        }
        /// <summary>
        /// Indicates whether the additional fee was posted to the general ledger.
        /// </summary>
        field(27; "Additional Fee Posted"; Boolean)
        {
            Caption = 'Additional Fee Posted';
        }
        /// <summary>
        /// Specifies the description that appeared in ledger entries when the memo was posted.
        /// </summary>
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        /// <summary>
        /// Indicates whether comments exist for this issued finance charge memo.
        /// </summary>
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Fin. Charge Comment Line" where(Type = const("Issued Finance Charge Memo"),
                                                                  "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total remaining amount from all customer ledger entries on the memo lines.
        /// </summary>
        field(31; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line"."Remaining Amount" where("Finance Charge Memo No." = field("No."),
                                                                                       "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total interest amount charged on all memo lines.
        /// </summary>
        field(32; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line".Amount where("Finance Charge Memo No." = field("No."),
                                                                           Type = const("Customer Ledger Entry"),
                                                                           "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Interest Amount';
            ToolTip = 'Specifies the total of the interest amounts on the finance charge memo lines.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total additional fee amount from all memo lines.
        /// </summary>
        field(33; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line".Amount where("Finance Charge Memo No." = field("No."),
                                                                           Type = const("G/L Account")));
            Caption = 'Additional Fee';
            ToolTip = 'Specifies the total of the additional fee amounts on the finance charge memo lines.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total VAT amount from all memo lines.
        /// </summary>
        field(34; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line"."VAT Amount" where("Finance Charge Memo No." = field("No."),
                                                                                 "Detailed Interest Rates Entry" = const(false)));
            Caption = 'VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the number of times the finance charge memo has been printed.
        /// </summary>
        field(35; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            ToolTip = 'Specifies how many times the document has been printed.';
        }
        /// <summary>
        /// Specifies the user who issued the finance charge memo.
        /// </summary>
        field(36; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Specifies the number series used for the issued finance charge memo number.
        /// </summary>
        field(37; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series that was assigned to the finance charge memo before it was issued.
        /// </summary>
        field(38; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the document number that was assigned before the memo was issued.
        /// </summary>
        field(39; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
            ToolTip = 'Specifies the number of the finance charge memo.';
        }
        /// <summary>
        /// Specifies the source code that identifies the origin of the posted entries.
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
        /// Specifies the VAT business posting group used for the memo.
        /// </summary>
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the date used for VAT reporting purposes.
        /// </summary>
        field(44; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the VAT date for the finance charge memo.';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this issued finance charge memo has been canceled.
        /// </summary>
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
            ToolTip = 'Specifies if the issued finance charge memo has been canceled.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the user who canceled this finance charge memo.
        /// </summary>
        field(51; "Canceled By"; Code[50])
        {
            Caption = 'Canceled By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the date when this finance charge memo was canceled.
        /// </summary>
        field(52; "Canceled Date"; Date)
        {
            Caption = 'Canceled Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the document number of the credit memo that canceled this finance charge.
        /// </summary>
        field(53; "Canceled By Document No."; Code[20])
        {
            Caption = 'Canceled By Document No.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the regional format settings used for printing dates and numbers.
        /// </summary>
        field(54; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        /// <summary>
        /// Specifies the company bank account printed on the memo for payment.
        /// </summary>
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        /// <summary>
        /// Specifies the unique identifier for the dimension values assigned to this memo.
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
        FinChrgMemoIssue.DeleteIssuedFinChrgLines(Rec);

        FinChrgCommentLine.SetRange(Type, FinChrgCommentLine.Type::"Issued Finance Charge Memo");
        FinChrgCommentLine.SetRange("No.", "No.");
        FinChrgCommentLine.DeleteAll();
    end;

    var
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
        DimMgt: Codeunit DimensionManagement;

    /// <summary>
    /// Prints or emails the issued finance charge memo using the configured report selections.
    /// </summary>
    /// <param name="ShowRequestForm">Specifies whether to show the report request page before printing.</param>
    /// <param name="SendAsEmail">Specifies whether to send the memo via email instead of printing.</param>
    /// <param name="HideDialog">Specifies whether to suppress the email dialog when sending.</param>
    procedure PrintRecords(ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean)
    var
        DummyReportSelections: Record "Report Selections";
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if SendAsEmail then
            DocumentSendingProfile.TrySendToEMail(
              DummyReportSelections.Usage::"Fin.Charge".AsInteger(), Rec, FieldNo("No."),
              ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Customer No."), not HideDialog)
        else
            DocumentSendingProfile.TrySendToPrinter(
              DummyReportSelections.Usage::"Fin.Charge".AsInteger(), Rec, FieldNo("Customer No."), ShowRequestForm)
    end;

    /// <summary>
    /// Opens the Navigate page to show all related ledger entries for this issued finance charge memo.
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
    /// Increments the print count for this issued finance charge memo.
    /// </summary>
    procedure IncrNoPrinted()
    begin
        FinChrgMemoIssue.IncrNoPrinted(Rec);
    end;

    /// <summary>
    /// Opens the dimension set entries page to view dimensions assigned to this memo.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    /// <summary>
    /// Retrieves the customer's VAT registration number for document printing.
    /// </summary>
    /// <returns>The VAT registration number text.</returns>
    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    /// <summary>
    /// Retrieves the caption for the VAT registration number field.
    /// </summary>
    /// <returns>The field caption text for VAT Registration No.</returns>
    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        exit(FieldCaption("VAT Registration No."));
    end;

    /// <summary>
    /// Runs the Cancel Issued Finance Charge Memos report for the selected records.
    /// </summary>
    /// <param name="IssuedFinChargeMemoHeader">Specifies the issued finance charge memo records to cancel.</param>
    procedure RunCancelIssuedFinChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(IssuedFinChargeMemoHeader);
        IssuedFinChargeMemoHeader.SetFilter(
          "No.",
          SelectionFilterManagement.GetSelectionFilter(RecRef, IssuedFinChargeMemoHeader.FieldNo("No.")));

        REPORT.RunModal(REPORT::"Cancel Issued Fin.Charge Memos", true, false, IssuedFinChargeMemoHeader);
    end;

    /// <summary>
    /// Raised before the issued finance charge memo is printed or emailed.
    /// </summary>
    /// <param name="IssuedFinChargeMemoHeader">Specifies the issued finance charge memo header record.</param>
    /// <param name="ShowRequestForm">Specifies whether to show the report request page.</param>
    /// <param name="SendAsEmail">Specifies whether to send via email.</param>
    /// <param name="HideDialog">Specifies whether to hide the email dialog.</param>
    /// <param name="IsHandled">Set to true to skip the default print or email process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;
}
