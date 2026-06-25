// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Reporting;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Security.AccessControl;

#pragma warning disable AA0232
table 11737 "Posted Cash Document Hdr. CZP"
{
    Caption = 'Posted Cash Document Header';
    DataCaptionFields = "Cash Desk No.", "Document Type", "No.", "Pay-to/Receive-from Name";
    DrillDownPageID = "Posted Cash Document List CZP";
    LookupPageID = "Posted Cash Document List CZP";
    Permissions = tabledata "Posted Cash Document Line CZP" = rd;

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
            TableRelation = "Cash Desk CZP";
            DataClassification = CustomerContent;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(3; "Pay-to/Receive-from Name"; Text[100])
        {
            Caption = 'Pay-to/Receive-from Name';
            DataClassification = CustomerContent;
        }
        field(4; "Pay-to/Receive-from Name 2"; Text[50])
        {
            Caption = 'Pay-to/Receive-from Name 2';
            DataClassification = CustomerContent;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(7; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            CalcFormula = Sum("Posted Cash Document Line CZP".Amount where("Cash Desk No." = field("Cash Desk No."), "Cash Document No." = field("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = Sum("Posted Cash Document Line CZP"."Amount (LCY)" where("Cash Desk No." = field("Cash Desk No."), "Cash Document No." = field("No.")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            DataClassification = CustomerContent;
        }
        field(17; "Created ID"; Code[50])
        {
            Caption = 'Created ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(18; "Released ID"; Code[50])
        {
            Caption = 'Released ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(19; "Posted ID"; Code[50])
        {
            Caption = 'Posted ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(20; "Document Type"; Enum "Cash Document Type CZP")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
            DataClassification = CustomerContent;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
            DataClassification = CustomerContent;
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
            DataClassification = CustomerContent;
        }
        field(25; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DataClassification = CustomerContent;
        }
        field(30; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;
        }
        field(35; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
            DataClassification = CustomerContent;
        }
        field(38; "Created Date"; Date)
        {
            Caption = 'Created Date';
            DataClassification = CustomerContent;
        }
        field(40; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(42; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
            DataClassification = CustomerContent;
        }
        field(45; "Amounts Including VAT"; Boolean)
        {
            Caption = 'Amounts Including VAT';
            DataClassification = CustomerContent;
        }
        field(51; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Posted Cash Document Line CZP"."VAT Base Amount" where("Cash Desk No." = field("Cash Desk No."), "Cash Document No." = field("No.")));
            Caption = 'VAT Base Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Posted Cash Document Line CZP"."Amount Including VAT" where("Cash Desk No." = field("Cash Desk No."), "Cash Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = Sum("Posted Cash Document Line CZP"."VAT Base Amount (LCY)" where("Cash Desk No." = field("Cash Desk No."), "Cash Document No." = field("No.")));
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Amount Including VAT (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = Sum("Posted Cash Document Line CZP"."Amount Including VAT (LCY)" where("Cash Desk No." = field("Cash Desk No."), "Cash Document No." = field("No.")));
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            DataClassification = CustomerContent;
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(62; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
            DataClassification = CustomerContent;
        }
        field(65; "Payment Purpose"; Text[100])
        {
            Caption = 'Payment Purpose';
            DataClassification = CustomerContent;
        }
        field(70; "Received By"; Text[100])
        {
            Caption = 'Received By';
            DataClassification = CustomerContent;
        }
        field(71; "Identification Card No."; Code[10])
        {
            Caption = 'Identification Card No.';
            DataClassification = CustomerContent;
        }
        field(72; "Paid By"; Text[100])
        {
            Caption = 'Paid By';
            DataClassification = CustomerContent;
        }
        field(73; "Received From"; Text[100])
        {
            Caption = 'Received From';
            DataClassification = CustomerContent;
        }
        field(74; "Paid To"; Text[100])
        {
            Caption = 'Paid To';
            DataClassification = CustomerContent;
        }
        field(80; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
        }
        field(81; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            DataClassification = CustomerContent;
        }
        field(90; "Partner Type"; Enum "Cash Document Partner Type CZP")
        {
            Caption = 'Partner Type';
            DataClassification = CustomerContent;
        }
        field(91; "Partner No."; Code[20])
        {
            Caption = 'Partner No.';
            TableRelation = if ("Partner Type" = const(Customer)) Customer else
            if ("Partner Type" = const(Vendor)) Vendor else
            if ("Partner Type" = const(Contact)) Contact else
            if ("Partner Type" = const("Salesperson/Purchaser")) "Salesperson/Purchaser" else
            if ("Partner Type" = const(Employee)) Employee;
            DataClassification = CustomerContent;
        }
        field(98; "Canceled Document"; Boolean)
        {
            Caption = 'Canceled Document';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(102; "EET Entry No."; Integer)
        {
            Caption = 'EET Entry No.';
            TableRelation = "EET Entry CZL";
            DataClassification = CustomerContent;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "Cash Desk No.", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Cash Desk No.", "Document Type", "No.")
        {
        }
        key(Key3; "Cash Desk No.", "Posting Date")
        {
        }
        key(Key4; "External Document No.")
        {
        }
        key(Key5; "No.", "Posting Date")
        {
        }
    }

    trigger OnDelete()
    var
        PostedCashDocumentLineCZP: Record "Posted Cash Document Line CZP";
    begin
        PostedCashDocumentLineCZP.SetRange("Cash Desk No.", "Cash Desk No.");
        PostedCashDocumentLineCZP.SetRange("Cash Document No.", "No.");
        PostedCashDocumentLineCZP.DeleteAll();
    end;

    var
        DimensionManagement: Codeunit DimensionManagement;

    /// <summary>
    /// Sends the cash document records by email.
    /// </summary>
    /// <param name="ShowDialog">Whether to show the email dialog.</param>
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        TestField("Document Type", "Document Type"::Receipt);
        TestField("Partner Type", "Partner Type"::Customer);
        TestField("Partner No.");

        DocumentSendingProfile.TrySendToEMail(
            Enum::"Report Selection Usage"::"Posted Cash Receipt CZP".AsInteger(), Rec, FieldNo("No."), GetDocumentTypeText(), FieldNo("Partner No."), ShowDialog);
    end;

    /// <summary>
    /// Sends selected cash document reports to the companies. Before this procedure is called,
    /// cash documents are selected on the page and then selection filter is used to filter the selected documents.
    /// </summary>
    /// <remarks>
    /// Shows profile selection window and then send the selected reports to the companies.
    /// </remarks>
    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        TestField("Document Type", "Document Type"::Receipt);
        TestField("Partner Type", "Partner Type"::Customer);
        TestField("Partner No.");

        DocumentSendingProfile.SendCustomerRecords(
            Enum::"Report Selection Usage"::"Posted Cash Receipt CZP".AsInteger(), Rec, GetDocumentTypeText(), "Partner No.", "No.",
            FieldNo("Partner No."), FieldNo("No."));
    end;

    /// <summary>
    /// Prints selected cash document reports. Before this procedure is called,
    /// cash documents are selected on the page and then selection filter is used to filter the selected documents.
    /// </summary>
    /// <param name="ShowDialog">
    /// Request window for the report will be displayed if true, otherwise the default settings are used.
    /// </param>
    procedure PrintRecords(ShowDialog: Boolean)
    begin
        TestField("Document Type");

        case "Document Type" of
            "Document Type"::Receipt:
                PrintCashReceipt(ShowDialog);
            "Document Type"::Withdrawal:
                PrintCashWithdrawal(ShowDialog);
        end;
    end;

    local procedure PrintCashReceipt(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        case "Partner Type" of
            "Partner Type"::Customer:
                DocumentSendingProfile.TrySendToPrinter(
                    Enum::"Report Selection Usage"::"Posted Cash Receipt CZP".AsInteger(), Rec, FieldNo("Partner No."), ShowDialog);
            "Partner Type"::Vendor:
                DocumentSendingProfile.TrySendToPrinterVendor(
                    Enum::"Report Selection Usage"::"Posted Cash Receipt CZP".AsInteger(), Rec, FieldNo("Partner No."), ShowDialog);
            else
                DocumentSendingProfile.TrySendToPrinter(
                    Enum::"Report Selection Usage"::"Posted Cash Receipt CZP".AsInteger(), Rec, 0, ShowDialog);
        end;
    end;

    local procedure PrintCashWithdrawal(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        case "Partner Type" of
            "Partner Type"::Customer:
                DocumentSendingProfile.TrySendToPrinter(
                    Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP".AsInteger(), Rec, FieldNo("Partner No."), ShowDialog);
            "Partner Type"::Vendor:
                DocumentSendingProfile.TrySendToPrinterVendor(
                    Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP".AsInteger(), Rec, FieldNo("Partner No."), ShowDialog);
            else
                DocumentSendingProfile.TrySendToPrinter(
                    Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP".AsInteger(), Rec, 0, ShowDialog);
        end;
    end;

    /// <summary>
    /// Prints the cash documents and saves them as document attachments.
    /// </summary>
    procedure PrintToDocumentAttachment()
    var
        PostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP";
    begin
        PostedCashDocumentHdrCZP.Copy(Rec);
        PostedCashDocumentHdrCZP.SetRecFilter();
        PrintToDocumentAttachment(PostedCashDocumentHdrCZP);
    end;

    /// <summary>
    /// Prints the cash documents and saves them as document attachments.
    /// </summary>
    /// <param name="PostedCashDocumentHdrCZP">The cash document records to print and attach.</param>
    procedure PrintToDocumentAttachment(var PostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := PostedCashDocumentHdrCZP.Count() = 1;
        if PostedCashDocumentHdrCZP.FindSet() then
            repeat
                DoPrintToDocumentAttachment(PostedCashDocumentHdrCZP, ShowNotificationAction);
            until PostedCashDocumentHdrCZP.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(PostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
        RepSelManualHandlerCZP: Codeunit "Rep. Sel. Manual Handler CZP";
    begin
        PostedCashDocumentHdrCZP.SetRecFilter();
        RepSelManualHandlerCZP.SetPostedCashDocumentHeader(PostedCashDocumentHdrCZP);
        BindSubscription(RepSelManualHandlerCZP);
        case PostedCashDocumentHdrCZP."Document Type" of
            PostedCashDocumentHdrCZP."Document Type"::Receipt:
                ReportSelections.SaveAsDocumentAttachment(
                    ReportSelections.Usage::"Posted Cash Receipt CZP".AsInteger(), PostedCashDocumentHdrCZP, PostedCashDocumentHdrCZP."No.", PostedCashDocumentHdrCZP."Partner No.", ShowNotificationAction);
            PostedCashDocumentHdrCZP."Document Type"::Withdrawal:
                ReportSelections.SaveAsDocumentAttachment(
                    ReportSelections.Usage::"Posted Cash Withdrawal CZP".AsInteger(), PostedCashDocumentHdrCZP, PostedCashDocumentHdrCZP."No.", PostedCashDocumentHdrCZP."Partner No.", ShowNotificationAction);
        end;
        UnbindSubscription(RepSelManualHandlerCZP);
    end;

    procedure Navigate()
    var
        PageNavigate: Page Navigate;
    begin
        PageNavigate.SetDoc("Posting Date", "No.");
        PageNavigate.SetRec(Rec);
        PageNavigate.Run();
    end;

    procedure ShowDimensions()
    var
        TwoPlaceholdersTok: Label '%1 %2', Locked = true;
    begin
        DimensionManagement.ShowDimensionSet("Dimension Set ID", StrSubstNo(TwoPlaceholdersTok, TableCaption, "No."));
    end;

    procedure HasPostedDocumentAttachment(): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", Database::"Posted Cash Document Hdr. CZP");
        DocumentAttachment.SetRange("No.", Rec."No.");
        exit(not DocumentAttachment.IsEmpty());
    end;

    local procedure GetDocumentTypeText(): Text[150]
    var
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        exit(ReportDistributionMgt.GetFullDocumentTypeText(Rec));
    end;
#if not CLEAN29
#pragma warning disable AL0432

    [Obsolete('The table "Cash Desk Rep. Selections CZP" has been replaced by the standard "Report Selections" table and is no longer supported. This event will be removed in future versions.', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrintRecordsOnBeforeFilterAndPrintReports(var CashDeskRepSelectionsCZP: Record "Cash Desk Rep. Selections CZP"; PostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP"; ShowRequestForm: Boolean; var IsHandled: Boolean);
    begin
    end;
#pragma warning restore AL0432
#endif
}
