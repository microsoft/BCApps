// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Globalization;
using System.Security.AccessControl;

#pragma warning disable AA0232
table 31274 "Posted Compensation Header CZC"
{
    Caption = 'Posted Compensation Header';
    DataCaptionFields = "No.", Description;
    LookupPageID = "Posted Compensation List CZC";

    fields
    {
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(13; "Company Type"; Enum "Compensation Company Type CZC")
        {
            Caption = 'Company Type';
            DataClassification = CustomerContent;
        }
        field(15; "Company No."; Code[20])
        {
            Caption = 'Company No.';
            TableRelation = if ("Company Type" = const(Customer)) Customer else
            if ("Company Type" = const(Vendor)) Vendor;
            DataClassification = CustomerContent;
        }
        field(20; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
            DataClassification = CustomerContent;
        }
        field(25; "Company Name 2"; Text[50])
        {
            Caption = 'Company Name 2';
            DataClassification = CustomerContent;
        }
        field(30; "Company Address"; Text[100])
        {
            Caption = 'Company Address';
            DataClassification = CustomerContent;
        }
        field(35; "Company Address 2"; Text[50])
        {
            Caption = 'Company Address 2';
            DataClassification = CustomerContent;
        }
        field(40; "Company City"; Text[30])
        {
            Caption = 'Company City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
            DataClassification = CustomerContent;
        }
        field(45; "Company Contact"; Text[100])
        {
            Caption = 'Company Contact';
            DataClassification = CustomerContent;
        }
        field(46; "Company County"; Text[30])
        {
            Caption = 'Company County';
            CaptionClass = '5,12,' + "Company Country/Region Code";
            DataClassification = CustomerContent;
        }
        field(47; "Company Country/Region Code"; Code[10])
        {
            Caption = 'Company Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = CustomerContent;
        }
        field(50; "Company Post Code"; Code[20])
        {
            Caption = 'Company Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
            DataClassification = CustomerContent;
        }
        field(55; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(65; "Salesperson/Purchaser Code"; Code[20])
        {
            Caption = 'Salesperson/Purchaser Code';
            TableRelation = "Salesperson/Purchaser";
            DataClassification = CustomerContent;
        }
        field(70; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;
        }
        field(75; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(80; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(85; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
            DataClassification = CustomerContent;
        }
        field(86; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
            DataClassification = CustomerContent;
        }
        field(90; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            CalcFormula = sum("Posted Compensation Line CZC"."Ledg. Entry Rem. Amt. (LCY)" where("Compensation No." = field("No.")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(95; "Compensation Balance (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            CalcFormula = sum("Posted Compensation Line CZC"."Amount (LCY)" where("Compensation No." = field("No.")));
            Caption = 'Compensation Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; "Compensation Value (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            CalcFormula = sum("Posted Compensation Line CZC"."Amount (LCY)" where("Compensation No." = field("No."), "Amount (LCY)" = filter(> 0)));
            Caption = 'Compensation Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        PostedCompensationLineCZC: Record "Posted Compensation Line CZC";
    begin
        PostedCompensationLineCZC.SetRange("Compensation No.", "No.");
        PostedCompensationLineCZC.DeleteAll(true);
    end;

    var
        ContactNotSupportedErr: Label 'Sending to contact is not supported for compensation document. Please select a customer or vendor company type.';
        ContactRelatedCustVendNotFoundErr: Label 'Cannot send email for contact %1 because no related customer or vendor was found.', Comment = '%1 = Contact No.';

    procedure Navigation()
    var
        Navigate: Page Navigate;
    begin
        Navigate.SetDoc("Posting Date", "No.");
        Navigate.Run();
    end;

    /// <summary>
    /// Sends the compensation records by email.
    /// </summary>
    /// <param name="ShowDialog">Whether to show the email dialog.</param>
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
    begin
        case "Company Type" of
            "Company Type"::Customer:
                DocumentSendingProfile.TrySendToEMail(
                    Enum::"Report Selection Usage"::"Posted Compensation CZC".AsInteger(), Rec, FieldNo("No."), GetDocumentTypeText(), FieldNo("Company No."), ShowDialog);
            "Company Type"::Vendor:
                ReportSelections.SendEmailToVendor(
                    Enum::"Report Selection Usage"::"Posted Compensation CZC".AsInteger(), Rec, Rec."No.", GetDocumentTypeText(), ShowDialog, Rec."Company No.");
            "Company Type"::Contact:
                SendEmailToContact(ShowDialog);
        end;
    end;

    local procedure SendEmailToContact(ShowDialog: Boolean)
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Vendor: Record Vendor;
        ReportSelections: Record "Report Selections";
    begin
        Contact.Get("Company No.");

        if Contact.FindCustomer(Customer) then begin
            ReportSelections.SendEmailToCust(
                Enum::"Report Selection Usage"::"Posted Compensation CZC".AsInteger(), Rec, Rec."No.", GetDocumentTypeText(), ShowDialog, Customer."No.");
            exit;
        end;
        if Contact.FindVendor(Vendor) then begin
            ReportSelections.SendEmailToVendor(
                Enum::"Report Selection Usage"::"Posted Compensation CZC".AsInteger(), Rec, Rec."No.", GetDocumentTypeText(), ShowDialog, Vendor."No.");
            exit;
        end;

        Error(ContactRelatedCustVendNotFoundErr, "Company No.");
    end;

    /// <summary>
    /// Sends selected compensation reports to the companies. Before this procedure is called,
    /// compensation documents are selected on the page and then selection filter is used to filter the selected documents.
    /// </summary>
    /// <remarks>
    /// Shows profile selection window and then send the selected reports to the companies.
    /// </remarks>
    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
    begin
        case "Company Type" of
            "Company Type"::Customer:
                DocumentSendingProfile.SendCustomerRecords(
                    ReportSelections.Usage::"Posted Compensation CZC".AsInteger(), Rec, GetDocumentTypeText(), "Company No.", "No.",
                    FieldNo("Company No."), FieldNo("No."));
            "Company Type"::Vendor:
                DocumentSendingProfile.SendVendorRecords(
                    ReportSelections.Usage::"Posted Compensation CZC".AsInteger(), Rec, GetDocumentTypeText(), "Company No.", "No.",
                    FieldNo("Company No."), FieldNo("No."));
            "Company Type"::Contact:
                Error(ContactNotSupportedErr);
        end;
    end;

    /// <summary>
    /// Prints selected compensation reports. Before this procedure is called,
    /// compensation documents are selected on the page and then selection filter is used to filter the selected documents.
    /// </summary>
    /// <param name="ShowDialog">
    /// Request window for the report will be displayed if true, otherwise the default settings are used.
    /// </param>
    procedure PrintRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        case "Company Type" of
            "Company Type"::Customer:
                DocumentSendingProfile.TrySendToPrinter(
                    Enum::"Report Selection Usage"::"Posted Compensation CZC".AsInteger(), Rec, FieldNo("Company No."), ShowDialog);
            "Company Type"::Vendor:
                DocumentSendingProfile.TrySendToPrinterVendor(
                    Enum::"Report Selection Usage"::"Posted Compensation CZC".AsInteger(), Rec, FieldNo("Company No."), ShowDialog);
            "Company Type"::Contact:
                DocumentSendingProfile.TrySendToPrinter(
                    Enum::"Report Selection Usage"::"Posted Compensation CZC".AsInteger(), Rec, 0, ShowDialog);
        end;
    end;

    /// <summary>
    /// Prints the compensation documents and saves them as document attachments.
    /// </summary>
    procedure PrintToDocumentAttachment()
    var
        PostedCompensationHeaderCZC: Record "Posted Compensation Header CZC";
    begin
        PostedCompensationHeaderCZC.Copy(Rec);
        PostedCompensationHeaderCZC.SetRecFilter();
        PrintToDocumentAttachment(PostedCompensationHeaderCZC);
    end;

    /// <summary>
    /// Prints the compensation documents and saves them as document attachments.
    /// </summary>
    /// <param name="PostedCompensationHeaderCZC">The compensation records to print and attach.</param>
    procedure PrintToDocumentAttachment(var PostedCompensationHeaderCZC: Record "Posted Compensation Header CZC")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := PostedCompensationHeaderCZC.Count() = 1;
        if PostedCompensationHeaderCZC.FindSet() then
            repeat
                DoPrintToDocumentAttachment(PostedCompensationHeaderCZC, ShowNotificationAction);
            until PostedCompensationHeaderCZC.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(PostedCompensationHeaderCZC: Record "Posted Compensation Header CZC"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
        RepSelManualHandlerCZC: Codeunit "Rep. Sel. Manual Handler CZC";
    begin
        PostedCompensationHeaderCZC.SetRecFilter();
        RepSelManualHandlerCZC.SetPostedCompensationHeader(PostedCompensationHeaderCZC);
        BindSubscription(RepSelManualHandlerCZC);
        ReportSelections.SaveAsDocumentAttachment(
            ReportSelections.Usage::"Posted Compensation CZC".AsInteger(), PostedCompensationHeaderCZC, PostedCompensationHeaderCZC."No.", PostedCompensationHeaderCZC."Company No.", ShowNotificationAction);
        UnbindSubscription(RepSelManualHandlerCZC);
    end;

    local procedure GetDocumentTypeText(): Text[150]
    var
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        exit(ReportDistributionMgt.GetFullDocumentTypeText(Rec));
    end;
}
