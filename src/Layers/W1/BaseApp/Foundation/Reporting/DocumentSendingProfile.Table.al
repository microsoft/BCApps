// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Email;
using System.IO;
using System.Reflection;
using System.Telemetry;
using System.Utilities;

table 60 "Document Sending Profile"
{
    Caption = 'Document Sending Profile';
    LookupPageID = "Document Sending Profiles";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; Printer; Option)
        {
            Caption = 'Printer';
            OptionCaption = 'No,Yes (Prompt for Settings),Yes (Use Default Settings)';
            OptionMembers = No,"Yes (Prompt for Settings)","Yes (Use Default Settings)";
        }
        field(11; "E-Mail"; Option)
        {
            Caption = 'Email';
            OptionCaption = 'No,Yes (Prompt for Settings),Yes (Use Default Settings)';
            OptionMembers = No,"Yes (Prompt for Settings)","Yes (Use Default Settings)";
        }
        field(12; "E-Mail Attachment"; Enum "Document Sending Profile Attachment Type")
        {
            Caption = 'Email Attachment';
        }
        field(13; "E-Mail Format"; Code[20])
        {
            Caption = 'Email Format';
            TableRelation = "Electronic Document Format".Code;
        }
        field(15; Disk; Enum "Doc. Sending Profile Disk")
        {
            Caption = 'Disk';
        }
        field(16; "Disk Format"; Code[20])
        {
            Caption = 'Disk Format';
            TableRelation = "Electronic Document Format".Code;
        }
        field(20; "Electronic Document"; Enum "Doc. Sending Profile Elec.Doc.")
        {
            Caption = 'Electronic Document';
        }
        field(21; "Electronic Format"; Code[20])
        {
            Caption = 'Electronic Format';
            TableRelation = "Electronic Document Format".Code;
        }
        field(30; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            var
                DocumentSendingProfile: Record "Document Sending Profile";
            begin
                if (xRec.Default = true) and (Default = false) then
                    Error(CannotRemoveDefaultRuleErr);

                DocumentSendingProfile.SetRange(Default, true);
                DocumentSendingProfile.ModifyAll(Default, false, false);
            end;
        }
        field(50; "Send To"; Enum "Doc. Sending Profile Send To")
        {
            Caption = 'Send To';
        }
        field(51; Usage; Enum "Document Sending Profile Usage")
        {
            Caption = 'Usage';
        }
        field(52; "One Related Party Selected"; Boolean)
        {
            Caption = 'One Related Party Selected';
            InitValue = true;

            trigger OnValidate()
            begin
                if not "One Related Party Selected" then begin
                    "Electronic Document" := "Electronic Document"::No;
                    "Electronic Format" := '';
                end;
            end;
        }
        field(60; "Combine Email Documents"; Boolean)
        {
            Caption = 'Combine Email Documents';
            InitValue = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        if Default then
            Error(CannotDeleteDefaultRuleErr);

        Customer.SetRange("Document Sending Profile", Code);
        if Customer.FindFirst() then
            if Confirm(UpdateAssCustomerQst, false, Code) then
                Customer.ModifyAll("Document Sending Profile", '')
            else
                Error(CannotDeleteErr);
    end;

    trigger OnInsert()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.SetRange(Default, true);
        if not DocumentSendingProfile.FindFirst() then
            Default := true;
    end;

    var
        DefaultCodeTxt: Label 'DEFAULT', Comment = 'Translate as we translate default term in local languages';
        DefaultDescriptionTxt: Label 'Default rule used if no other provided';
#pragma warning disable AA0470
        RecordAsTextFormatterTxt: Label '%1 ; %2';
#pragma warning restore AA0470
        FieldCaptionContentFormatterTxt: Label '%1 (%2)', Comment = '%1=Field Caption (e.g. Email), %2=Field Content (e.g. PDF) so for example ''Email (PDF)''';
        CannotDeleteDefaultRuleErr: Label 'You cannot delete the default rule. Assign other rule to be default first.';
        CannotRemoveDefaultRuleErr: Label 'There must be one default rule in the system. To remove the default property from this rule, assign default to another rule.';
#pragma warning disable AA0470
        UpdateAssCustomerQst: Label 'If you delete document sending profile %1, it will also be deleted on customer cards that use the profile.\\Do you want to continue?';
#pragma warning restore AA0470
        CannotDeleteErr: Label 'Cannot delete the document sending profile.';
        CannotSendMultipleSalesDocsErr: Label 'You can only send one electronic sales document at a time.';
        ProfileSelectionQst: Label 'Confirm the first profile and use it for all selected documents.,Confirm the profile for each document.,Use the default profile for all selected documents without confirmation.', Comment = 'Translation should contain comma separators between variants as ENU value does. No other commas should be there.';
        CustomerProfileSelectionInstrTxt: Label 'Customers on the selected documents might use different document sending profiles. Choose one of the following options: ';
        VendorProfileSelectionInstrTxt: Label 'Vendors on the selected documents might use different document sending profiles. Choose one of the following options: ';
        InvoicesTxt: Label 'Invoices';
        ShipmentsTxt: Label 'Shipments';
        CreditMemosTxt: Label 'Credit Memos';
        ReceiptsTxt: Label 'Receipts';
        JobQuotesTxt: Label 'Project Quotes';
        PurchaseOrdersTxt: Label 'Purchase Orders';

    procedure GetDefaultForCustomer(CustomerNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            if DocumentSendingProfile.Get(Customer."Document Sending Profile") then
                exit;

        GetDefault(DocumentSendingProfile);
    end;

    local procedure GetDefaultSendingProfileForCustomerFromLookup(CustomerNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultSendingProfileForCustomerFromLookup(CustomerNo, DocumentSendingProfile, IsHandled);
        if IsHandled then
            exit;

        GetDefaultForCustomer(CustomerNo, DocumentSendingProfile);
    end;

    local procedure GetDefaultSendingProfileForVendorFromLookup(VendorNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultSendingProfileForVendorFromLookup(VendorNo, DocumentSendingProfile, IsHandled);
        if IsHandled then
            exit;

        DocumentSendingProfile.GetDefaultForVendor(VendorNo, DocumentSendingProfile);
    end;

    procedure GetDefaultForVendor(VendorNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            if DocumentSendingProfile.Get(Vendor."Document Sending Profile") then
                exit;

        GetDefault(DocumentSendingProfile);
    end;

    procedure GetDefault(var DefaultDocumentSendingProfile: Record "Document Sending Profile")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.SetRange(Default, true);
        if not DocumentSendingProfile.FindFirst() then begin
            DocumentSendingProfile.Init();
            DocumentSendingProfile.Validate(Code, DefaultCodeTxt);
            DocumentSendingProfile.Validate(Description, DefaultDescriptionTxt);
            DocumentSendingProfile.Validate("E-Mail", "E-Mail"::"Yes (Prompt for Settings)");
            DocumentSendingProfile.Validate("E-Mail Attachment", "E-Mail Attachment"::PDF);
            DocumentSendingProfile.Validate(Default, true);
            OnGetDefaultOnBeforeDocumentSendingProfileInsert(DocumentSendingProfile);
            DocumentSendingProfile.Insert(true);
        end;

        DefaultDocumentSendingProfile := DocumentSendingProfile;
    end;

    procedure GetRecordAsText(): Text
    var
        RecordAsText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRecordAsText(Rec, RecordAsText, IsHandled);
        if IsHandled then
            exit(RecordAsText);

        RecordAsText := '';

        if ("Electronic Document" <> "Electronic Document"::No) and ("Electronic Format" <> '') then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt,
                StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption("Electronic Document"), "Electronic Document"), RecordAsText);

        if "E-Mail" <> "E-Mail"::No then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt,
                StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption("E-Mail"), "E-Mail Attachment"), RecordAsText);
        if Printer <> Printer::No then
            RecordAsText := StrSubstNo(RecordAsTextFormatterTxt, FieldCaption(Printer), RecordAsText);

        if Disk <> Disk::No then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt, StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption(Disk), Disk), RecordAsText);

        OnAfterGetRecordAsText(Rec, RecordAsText, RecordAsTextFormatterTxt, FieldCaptionContentFormatterTxt);

        exit(RecordAsText);
    end;

    procedure WillUserBePrompted(): Boolean
    begin
        exit(
          (Printer = Printer::"Yes (Prompt for Settings)") or
          ("E-Mail" = "E-Mail"::"Yes (Prompt for Settings)"));
    end;

    procedure SetDocumentUsage(DocumentVariant: Variant)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentUsage: Enum "Electronic Document Format Usage";
    begin
        ElectronicDocumentFormat.GetDocumentFormatUsage(DocumentUsage, DocumentVariant);
        Validate(Usage, DocumentUsage);
    end;

    procedure VerifySelectedOptionsValid()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifySelectedOptionsValid(Rec, IsHandled);
        if IsHandled then
            exit;

        if "One Related Party Selected" then
            exit;

        if "E-Mail Attachment" <> "E-Mail Attachment"::PDF then
            Error(CannotSendMultipleSalesDocsErr);

        if "Electronic Document".AsInteger() > "Electronic Document"::No.AsInteger() then
            Error(CannotSendMultipleSalesDocsErr);
    end;

    procedure LookupProfile(CustNo: Code[20]; Multiselection: Boolean; ShowDialog: Boolean): Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable() then begin
            GetOfficeAddinDefault(Rec, OfficeMgt.AttachAvailable());
            exit(true);
        end;

        GetDefaultSendingProfileForCustomerFromLookup(CustNo, DocumentSendingProfile);
        if ShowDialog then
            exit(RunSelectSendingOptionsPage(DocumentSendingProfile.Code, Multiselection));

        Rec := DocumentSendingProfile;
        exit(true);
    end;

    procedure LookUpProfileVendor(VendorNo: Code[20]; Multiselection: Boolean; ShowDialog: Boolean): Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable() then begin
            GetOfficeAddinDefault(Rec, OfficeMgt.AttachAvailable());
            exit(true);
        end;

        GetDefaultSendingProfileForVendorFromLookup(VendorNo, DocumentSendingProfile);
        if ShowDialog then
            exit(RunSelectSendingOptionsPage(DocumentSendingProfile.Code, Multiselection));

        Rec := DocumentSendingProfile;
        exit(true);
    end;

    local procedure RunSelectSendingOptionsPage(DocumentSendingProfileCode: Code[20]; OneRelatedPartySelected: Boolean): Boolean
    var
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
    begin
        TempDocumentSendingProfile.Init();
        TempDocumentSendingProfile.Code := DocumentSendingProfileCode;
        TempDocumentSendingProfile.Validate("One Related Party Selected", OneRelatedPartySelected);
        TempDocumentSendingProfile.Insert();

        Commit();
        if PAGE.RunModal(PAGE::"Select Sending Options", TempDocumentSendingProfile) = ACTION::LookupOK then begin
            Rec := TempDocumentSendingProfile;
            exit(true);
        end;

        exit(false);
    end;

    procedure SendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        RecRefSource: RecordRef;
        RecRefToSend: RecordRef;
        ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault;
        SingleCustomerSelected: Boolean;
        ShowDialog: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendCustomerRecords(ReportUsage, RecordVariant, DocName, CustomerNo, DocumentNo, CustomerFieldNo, DocumentFieldNo, IsHandled);
        if not IsHandled then begin
            SingleCustomerSelected := IsSingleRecordSelected(RecordVariant, CustomerNo, CustomerFieldNo);

            if not CheckShowProfileSelectionMethodDialog(SingleCustomerSelected, ProfileSelectionMethod, CustomerNo, true) then
                exit;

            if SingleCustomerSelected or (ProfileSelectionMethod = ProfileSelectionMethod::ConfirmDefault) then begin
                ShowDialog := true;
                OnSendCustomerRecordsOnBeforeLookupProfile(ReportUsage, RecordVariant, CustomerNo, RecRefToSend, SingleCustomerSelected, ShowDialog);
                if DocumentSendingProfile.LookupProfile(CustomerNo, true, ShowDialog) then
                    DocumentSendingProfile.Send(ReportUsage, RecordVariant, DocumentNo, CustomerNo, DocName, CustomerFieldNo, DocumentFieldNo);
            end else begin
                ShowDialog := ProfileSelectionMethod = ProfileSelectionMethod::ConfirmPerEach;
                RecRefSource.GetTable(RecordVariant);
                if RecRefSource.FindSet() then
                    repeat
                        RecRefToSend := RecRefSource.Duplicate();
                        RecRefToSend.CurrentKeyIndex(1);
                        RecRefToSend.SetRecFilter();
                        CustomerNo := RecRefToSend.Field(CustomerFieldNo).Value();
                        DocumentNo := RecRefToSend.Field(DocumentFieldNo).Value();
                        OnSendCustomerRecordsOnBeforeLookupProfile(ReportUsage, RecordVariant, CustomerNo, RecRefToSend, SingleCustomerSelected, ShowDialog);
                        if DocumentSendingProfile.LookupProfile(CustomerNo, true, ShowDialog) then
                            DocumentSendingProfile.Send(ReportUsage, RecRefToSend, DocumentNo, CustomerNo, DocName, CustomerFieldNo, DocumentFieldNo);
                    until RecRefSource.Next() = 0;
            end;
        end;

        OnAfterSendCustomerRecords(ReportUsage, RecordVariant, DocName, CustomerNo, DocumentNo, CustomerFieldNo, DocumentFieldNo);
    end;

    procedure SendVendorRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; VendorNo: Code[20]; DocumentNo: Code[20]; VendorFieldNo: Integer; DocumentFieldNo: Integer)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault;
        SingleVendorSelected: Boolean;
        ShowDialog: Boolean;
        Handled: Boolean;
    begin
        OnBeforeSendVendorRecords(ReportUsage, RecordVariant, DocName, VendorNo, DocumentNo, VendorFieldNo, DocumentFieldNo, Handled);
        if Handled then
            exit;

        SingleVendorSelected := IsSingleRecordSelected(RecordVariant, VendorNo, VendorFieldNo);

        if not CheckShowProfileSelectionMethodDialog(SingleVendorSelected, ProfileSelectionMethod, VendorNo, false) then
            exit;

        if SingleVendorSelected or (ProfileSelectionMethod = ProfileSelectionMethod::ConfirmDefault) then begin
            ShowDialog := true;
            OnSendVendorRecordsOnBeforeLookupProfile(ReportUsage, RecordVariant, VendorNo, RecRef2, SingleVendorSelected, ShowDialog);
            if DocumentSendingProfile.LookUpProfileVendor(VendorNo, true, ShowDialog) then
                DocumentSendingProfile.SendVendor(ReportUsage, RecordVariant, DocumentNo, VendorNo, DocName, VendorFieldNo, DocumentFieldNo);
        end else begin
            ShowDialog := ProfileSelectionMethod = ProfileSelectionMethod::ConfirmPerEach;
            RecRef.GetTable(RecordVariant);
            if RecRef.FindSet() then
                repeat
                    RecRef2 := RecRef.Duplicate();
                    RecRef2.CurrentKeyIndex(1);
                    RecRef2.SetRecFilter();
                    VendorNo := RecRef2.Field(VendorFieldNo).Value();
                    DocumentNo := RecRef2.Field(DocumentFieldNo).Value();
                    OnSendVendorRecordsOnBeforeLookupProfile(ReportUsage, RecordVariant, VendorNo, RecRef2, SingleVendorSelected, ShowDialog);
                    if DocumentSendingProfile.LookUpProfileVendor(VendorNo, true, ShowDialog) then
                        DocumentSendingProfile.SendVendor(ReportUsage, RecRef2, DocumentNo, VendorNo, DocName, VendorFieldNo, DocumentFieldNo);
                until RecRef.Next() = 0;
        end;
    end;

    local procedure CheckShowProfileSelectionMethodDialog(SingleRecordSelected: Boolean; var ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault; AccountNo: Code[20]; IsCustomer: Boolean) Result: Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShowProfileSelectionMethodDialog(ProfileSelectionMethod, AccountNo, IsCustomer, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not SingleRecordSelected then
            if not DocumentSendingProfile.ProfileSelectionMethodDialog(ProfileSelectionMethod, IsCustomer) then
                exit(false);
        exit(true);
    end;

    procedure Send(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSend(ReportUsage, RecordVariant, DocNo, ToCust, DocName, CustomerFieldNo, DocumentNoFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Rec."Combine Email Documents" then
            FeatureTelemetry.LogUsage('0000II3', 'Document Sending Profile - Combine PDF', 'Combine');

        UpdateDocumentProfileForRecord(Rec, RecordVariant);
        SendToVAN(RecordVariant);
        SendToPrinter("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, CustomerFieldNo);
        TrySendToEMailGroupedMultipleSelection(
            "Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo, true);
        SendToDisk("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocNo, DocName, ToCust);

        OnAfterSend(ReportUsage, RecordVariant, DocNo, ToCust, DocName, CustomerFieldNo, DocumentNoFieldNo, Rec);
        Commit();
    end;

    procedure SendVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendVendor(ReportUsage, RecordVariant, DocNo, ToVendor, DocName, VendorNoFieldNo, DocumentNoFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Rec."Combine Email Documents" then
            FeatureTelemetry.LogUsage('0000II4', 'Document Sending Profile - Combine PDF', 'Combine');

        SendToVAN(RecordVariant);
        SendToPrinterVendor("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, VendorNoFieldNo);
        TrySendToEMailGroupedMultipleSelection("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocumentNoFieldNo, DocName, VendorNoFieldNo, false);
        SendToDiskVendor("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocNo, DocName, ToVendor);

        OnAfterSendVendor(
            ReportUsage, RecordVariant, DocNo, ToVendor, DocName, VendorNoFieldNo, DocumentNoFieldNo, Rec);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure TrySendToVAN(RecordVariant: Variant)
    begin
        "Electronic Document" := "Electronic Document"::"Through Document Exchange Service";
        SendToVAN(RecordVariant);
    end;

    procedure TrySendToPrinter(ReportUsage: Integer; RecordVariant: Variant; CustomerFieldNo: Integer; ShowDialog: Boolean)
    var
        Handled: Boolean;
    begin
        OnBeforeTrySendToPrinter(ReportUsage, RecordVariant, CustomerFieldNo, ShowDialog, Handled);
        if Handled then
            exit;

        if ShowDialog then
            Printer := Printer::"Yes (Prompt for Settings)"
        else
            Printer := Printer::"Yes (Use Default Settings)";

        SendToPrinter("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, CustomerFieldNo);
    end;

    procedure TrySendToPrinterVendor(ReportUsage: Integer; RecordVariant: Variant; VendorNoFieldNo: Integer; ShowDialog: Boolean)
    begin
        if ShowDialog then
            Printer := Printer::"Yes (Prompt for Settings)"
        else
            Printer := Printer::"Yes (Use Default Settings)";

        SendToPrinterVendor("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, VendorNoFieldNo);
    end;

    procedure TrySendToEMail(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerFieldNo: Integer; ShowDialog: Boolean)
    var
        Handled: Boolean;
        IsCustomer: Boolean;
    begin
        IsCustomer := true;
        OnBeforeTrySendToEMail(ReportUsage, RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo, ShowDialog, Handled, IsCustomer);
        if Handled then
            exit;

        if ShowDialog then
            "E-Mail" := "E-Mail"::"Yes (Prompt for Settings)"
        else
            "E-Mail" := "E-Mail"::"Yes (Use Default Settings)";

        "E-Mail Attachment" := "E-Mail Attachment"::PDF;

        TrySendToEMailGroupedMultipleSelection(
            "Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo, IsCustomer);
    end;

    procedure TrySendToEMailGroupedMultipleSelection(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerVendorFieldNo: Integer; IsCustomer: Boolean)
    var
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        RecRef: RecordRef;
        RecToSend: RecordRef;
        CustomerNoFieldRef: FieldRef;
        RecToSendCombine: Variant;
        CustomerVendorNos: Dictionary of [Code[20], Code[20]];
        CustomerVendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        RecRef.GetTable(RecordVariant);

        if Rec."Combine Email Documents" then begin
            GetDistinctCustomerVendor(RecRef, CustomerVendorFieldNo, CustomerVendorNos);

            RecToSendCombine := RecordVariant;
            CustomerNoFieldRef := RecRef.Field(CustomerVendorFieldNo);
            foreach CustomerVendorNo in CustomerVendorNos.Keys() do begin
                CustomerNoFieldRef.SetRange(CustomerVendorNo);
                RecRef.FindFirst();
                RecRef.SetTable(RecToSendCombine);

                DocumentNo := GetMultipleDocumentsNo(RecRef, DocumentNoFieldNo);
                DocName := GetMultipleDocumentsName(DocName, ReportUsage, RecRef);
                if IsCustomer then
                    SendToEMail(ReportUsage, RecToSendCombine, DocumentNo, DocName, CustomerVendorNo, CustomerVendorFieldNo)
                else
                    SendToEMailVendor(ReportUsage, RecToSendCombine, DocumentNo, DocName, CustomerVendorNo, CustomerVendorFieldNo);
            end;
        end
        else
            if RecRef.FindSet() then
                repeat
                    RecToSend := RecRef.Duplicate();
                    RecToSend.CurrentKeyIndex(1);
                    RecToSend.SetRecFilter();
                    CustomerVendorNo := RecToSend.Field(CustomerVendorFieldNo).Value();
                    DocumentNo := RecToSend.Field(DocumentNoFieldNo).Value();
                    DocName := ReportDistributionMgt.GetFullDocumentTypeText(RecToSend);
                    if IsCustomer then
                        SendToEMail(ReportUsage, RecToSend, DocumentNo, DocName, CustomerVendorNo, CustomerVendorFieldNo)
                    else
                        SendToEMailVendor(ReportUsage, RecToSend, DocumentNo, DocName, CustomerVendorNo, CustomerVendorFieldNo);
                until RecRef.Next() = 0;
    end;

    local procedure GetMultipleDocumentsNo(RecRef: RecordRef; DocumentNoFieldNo: Integer): Code[20]
    var
        DocumentNoFieldRef: FieldRef;
    begin
        if RecRef.Count > 1 then
            exit('');

        DocumentNoFieldRef := RecRef.Field(DocumentNoFieldNo);
        exit(DocumentNoFieldRef.Value);
    end;

    local procedure GetMultipleDocumentsName(DocName: Text[150]; ReportUsage: Enum "Report Selection Usage"; RecRef: RecordRef): Text[150]
    var
        ReportSelections: Record "Report Selections";
    begin
        if RecRef.Count > 1 then
            case ReportUsage of
                ReportSelections.Usage::"S.Invoice":
                    exit(InvoicesTxt);
                ReportSelections.Usage::"S.Shipment":
                    exit(ShipmentsTxt);
                ReportSelections.Usage::"S.Cr.Memo":
                    exit(CreditMemosTxt);
                ReportSelections.Usage::"S.Ret.Rcpt.":
                    exit(ReceiptsTxt);
                ReportSelections.Usage::JQ:
                    exit(JobQuotesTxt);
                ReportSelections.Usage::"P.Order":
                    exit(PurchaseOrdersTxt);
                else begin
                    OnGetDocumentName(ReportUsage, DocName);
                    exit(DocName);
                end;
            end;

        exit(DocName);
    end;

    local procedure GetDistinctCustomerVendor(RecRef: RecordRef; CustomerVendorFieldNo: Integer; var CustomerVendorNos: Dictionary of [Code[20], Code[20]])
    var
        FieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        if RecRef.FindSet() then
            repeat
                FieldRef := RecRef.Field(CustomerVendorFieldNo);
                CustomerNo := FieldRef.Value();
                if CustomerVendorNos.Add(CustomerNo, CustomerNo) then;
            until RecRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure TrySendToDisk(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToCust: Code[20])
    begin
        Disk := Disk::PDF;
        SendToDisk("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocNo, DocName, ToCust);
    end;

    procedure SendToVAN(RecordVariant: Variant)
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        SendWithReportDistributionManagement: Boolean;
    begin
        SendWithReportDistributionManagement := true;
        OnSendWithReportDistributionManagement(Rec, SendWithReportDistributionManagement);
        
        if (not SendWithReportDistributionManagement) or ("Electronic Document" = "Electronic Document"::No) then
            exit;

        ReportDistributionManagement.VANDocumentReport(RecordVariant, Rec);
    end;

    procedure SendToPrinter(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustomerNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        ShowRequestForm: Boolean;
    begin
        OnBeforeSendToPrinter(Rec, ReportSelections, RecordVariant);

        if Printer = Printer::No then
            exit;

        ShowRequestForm := Printer = Printer::"Yes (Prompt for Settings)";
        ReportSelections.PrintWithDialogForCust(ReportUsage, RecordVariant, ShowRequestForm, CustomerNoFieldNo);
    end;

    local procedure SendToPrinterVendor(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; VendorNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        ShowRequestForm: Boolean;
    begin
        if Printer = Printer::No then
            exit;

        ShowRequestForm := Printer = Printer::"Yes (Prompt for Settings)";
        ReportSelections.PrintWithDialogForVend(ReportUsage, RecordVariant, ShowRequestForm, VendorNoFieldNo);
    end;

    local procedure SendToEMail(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToCust: Code[20]; DocNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Customer: Record Customer;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocumentMailing: Codeunit "Document-Mailing";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        EmailBodyTempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        SourceReference: RecordRef;
        ShowDialog: Boolean;
        ClientFilePath: Text[250];
        ClientZipFileName: Text[250];
        SendToEmailAddress: Text[250];
        AttachmentStream: Instream;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        if "E-Mail" = "E-Mail"::No then
            exit;

        ShowDialog := "E-Mail" = "E-Mail"::"Yes (Prompt for Settings)";

        case "E-Mail Attachment" of
            "E-Mail Attachment"::PDF:
                ReportSelections.SendEmailToCust(ReportUsage.AsInteger(), RecordVariant, DocNo, DocName, ShowDialog, ToCust);
            "E-Mail Attachment"::"Electronic Document":
                begin
                    ReportSelections.GetEmailBodyForCust(EmailBodyTempBlob, ReportUsage, RecordVariant, ToCust, SendToEmailAddress);
                    ReportDistributionManagement.SendXmlEmailAttachment(
                      RecordVariant, "E-Mail Format", EmailBodyTempBlob, SendToEmailAddress, ReportUsage);
                end;
            "E-Mail Attachment"::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFilePath, RecordVariant, "E-Mail Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, TempBlob, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZipForCust(ReportUsage, RecordVariant, DocNo, ToCust, DataCompression);

                    DataCompression.SaveZipArchive(TempBlob);
                    TempBlob.CreateInStream(AttachmentStream);

                    TypeHelper.CopyRecVariantToRecRef(RecordVariant, SourceReference);
                    SourceTableIDs.Add(SourceReference.Number());
                    SourceIDs.Add(SourceReference.Field(SourceReference.SystemIdNo).Value());
                    SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

                    if Customer.Get(ToCust) then begin
                        SourceTableIDs.Add(Database::Customer);
                        SourceIDs.Add(Customer.SystemId);
                        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
                    end;

                    ReportSelections.GetEmailBodyForCust(EmailBodyTempBlob, ReportUsage, RecordVariant, ToCust, SendToEmailAddress);

                    DocumentMailing.EmailFile(
                      AttachmentStream, ClientZipFileName, EmailBodyTempBlob, DocNo, SendToEmailAddress, DocName,
                      not ShowDialog, ReportUsage.AsInteger(), SourceTableIDs, SourceIDs, SourceRelationTypes);
                end;
        end;

        OnAfterSendToEMail(Rec, ReportUsage, RecordVariant, DocNo, DocName, ToCust, DocNoFieldNo, ShowDialog);
    end;

    local procedure SendToEmailVendor(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToVendor: Code[20]; VendorNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Vendor: Record Vendor;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocumentMailing: Codeunit "Document-Mailing";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        EmailBodyTempBlob: Codeunit "Temp Blob";
        SourceReference: RecordRef;
        ShowDialog: Boolean;
        ClientFilePath: Text[250];
        ClientZipFileName: Text[250];
        SendToEmailAddress: Text[250];
        AttachmentStream: Instream;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        if "E-Mail" = "E-Mail"::No then
            exit;

        ShowDialog := "E-Mail" = "E-Mail"::"Yes (Prompt for Settings)";

        case "E-Mail Attachment" of
            "E-Mail Attachment"::PDF:
                ReportSelections.SendEmailToVendor(ReportUsage.AsInteger(), RecordVariant, DocNo, DocName, ShowDialog, ToVendor);
            "E-Mail Attachment"::"Electronic Document":
                begin
                    ReportSelections.GetEmailBodyForVend(EmailBodyTempBlob, ReportUsage, RecordVariant, ToVendor, SendToEmailAddress);
                    ReportDistributionManagement.SendXmlEmailAttachmentVendor(
                      RecordVariant, "E-Mail Format", EmailBodyTempBlob, SendToEmailAddress);
                end;
            "E-Mail Attachment"::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFilePath, RecordVariant, "E-Mail Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, TempBlob, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZipForVend(ReportUsage, RecordVariant, DocNo, ToVendor, DataCompression);

                    DataCompression.SaveZipArchive(TempBlob);
                    TempBlob.CreateInStream(AttachmentStream);
                    SourceReference := RecordVariant;

                    SourceTableIDs.Add(SourceReference.Number());
                    SourceIDs.Add(SourceReference.Field(SourceReference.SystemIdNo).Value());
                    SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

                    if Vendor.Get(ToVendor) then begin
                        SourceTableIDs.Add(Database::Vendor);
                        SourceIDs.Add(Vendor.SystemId);
                        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
                    end;

                    ReportSelections.GetEmailBodyForVend(EmailBodyTempBlob, ReportUsage, RecordVariant, ToVendor, SendToEmailAddress);

                    DocumentMailing.EmailFile(
                      AttachmentStream, ClientZipFileName, EmailBodyTempBlob, DocNo, SendToEmailAddress, DocName,
                      not ShowDialog, ReportUsage.AsInteger(), SourceTableIDs, SourceIDs, SourceRelationTypes);
                end;
        end;

        OnAfterSendToEmailVendor(Rec, ReportUsage, RecordVariant, DocNo, DocName, ToVendor, VendorNoFieldNo, ShowDialog);
    end;

    procedure SendToDisk(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToCust: Code[20])
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ClientFilePath: Text[250];
        ClientZipFileName: Text[250];
        IsHandled: Boolean;
    begin
        if Disk = Disk::No then
            exit;

        OnBeforeSendToDisk(ReportUsage.AsInteger(), RecordVariant, DocNo, DocName, ToCust, IsHandled);
        if IsHandled then
            exit;

        case Disk of
            Disk::PDF:
                ReportSelections.SendToDiskForCust(ReportUsage, RecordVariant, DocNo, DocName, ToCust);
            Disk::"Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.SaveFileOnClient(TempBlob, ClientFilePath);
                end;
            Disk::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, TempBlob, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZipForCust(ReportUsage, RecordVariant, DocNo, ToCust, DataCompression);
                    SaveZipArchiveToBLOB(DataCompression, TempBlob);

                    ReportDistributionManagement.SaveFileOnClient(TempBlob, ClientZipFileName);
                end;
        end;
    end;

    local procedure SendToDiskVendor(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToVendor: Code[20])
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ClientFilePath: Text[250];
        ClientZipFileName: Text[250];
    begin
        if Disk = Disk::No then
            exit;

        case Disk of
            Disk::PDF:
                ReportSelections.SendToDiskForVend(ReportUsage, RecordVariant, DocNo, DocName, ToVendor);
            Disk::"Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.SaveFileOnClient(TempBlob, ClientFilePath);
                end;
            Disk::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, TempBlob, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZipForVend(ReportUsage, RecordVariant, DocNo, ToVendor, DataCompression);
                    SaveZipArchiveToBLOB(DataCompression, TempBlob);

                    ReportDistributionManagement.SaveFileOnClient(TempBlob, ClientZipFileName);
                end;
        end;
    end;

    procedure GetOfficeAddinDefault(var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; CanAttach: Boolean)
    begin
        TempDocumentSendingProfile.Init();
        TempDocumentSendingProfile.Code := DefaultCodeTxt;
        TempDocumentSendingProfile.Description := DefaultDescriptionTxt;
        if CanAttach then
            TempDocumentSendingProfile."E-Mail" := TempDocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)"
        else
            TempDocumentSendingProfile."E-Mail" := TempDocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)";
        TempDocumentSendingProfile."E-Mail Attachment" := TempDocumentSendingProfile."E-Mail Attachment"::PDF;
        TempDocumentSendingProfile.Default := false;
    end;

    procedure ProfileSelectionMethodDialog(var ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault; IsCustomer: Boolean): Boolean
    var
        ProfileSelectionInstruction: Text;
    begin
        if IsCustomer then
            ProfileSelectionInstruction := CustomerProfileSelectionInstrTxt
        else
            ProfileSelectionInstruction := VendorProfileSelectionInstrTxt;

        case StrMenu(ProfileSelectionQst, 3, ProfileSelectionInstruction) of
            0:
                exit(false);
            1:
                ProfileSelectionMethod := ProfileSelectionMethod::ConfirmDefault;
            2:
                ProfileSelectionMethod := ProfileSelectionMethod::ConfirmPerEach;
            3:
                ProfileSelectionMethod := ProfileSelectionMethod::UseDefault;
        end;
        exit(true);
    end;

    protected procedure IsSingleRecordSelected(RecordVariant: Variant; CVNo: Code[20]; CVFieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecordVariant);
        if not RecRef.FindSet() then
            exit(false);

        if RecRef.Next() = 0 then
            exit(true);

        FieldRef := RecRef.Field(CVFieldNo);
        FieldRef.SetFilter('<>%1', CVNo);
        exit(RecRef.IsEmpty);
    end;

    procedure CheckElectronicSendingEnabled()
    var
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        if "Electronic Document" <> "Electronic Document"::No then
            if not HasThirdPartyDocExchService() then
                DocExchServiceMgt.CheckServiceEnabled();
    end;

    local procedure HasThirdPartyDocExchService() ExchServiceEnabled: Boolean
    begin
        OnCheckElectronicSendingEnabled(ExchServiceEnabled);
    end;

    local procedure SaveZipArchiveToBLOB(var DataCompression: Codeunit "Data Compression"; var TempBlob: Codeunit "Temp Blob")
    var
        ZipFileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(ZipFileOutStream);
        DataCompression.SaveZipArchive(ZipFileOutStream);
        DataCompression.CloseZipArchive();
    end;

    local procedure UpdateDocumentProfileForRecord(var DocumentSendingProfile: Record "Document Sending Profile"; RecordVariant: Variant)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(RecordVariant);
        if RecordRef.Number in [Database::"Sales Shipment Header", Database::"Return Receipt Header"] then
            UpdateDocumentProfileForCustomer(DocumentSendingProfile);
    end;

    local procedure UpdateDocumentProfileForCustomer(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        if DocumentSendingProfile."E-Mail Attachment" <> DocumentSendingProfile."E-Mail Attachment"::PDF then begin
            DocumentSendingProfile."E-Mail Attachment" := DocumentSendingProfile."E-Mail Attachment"::PDF;
            DocumentSendingProfile."E-Mail Format" := '';
        end;

        if DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No then begin
            DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::PDF;
            DocumentSendingProfile."Disk Format" := '';
        end;

        if (DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No) then begin
            DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
            DocumentSendingProfile."Electronic Format" := '';
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSend(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer; DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSendVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer; DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendToEMail(var DocumentSendingProfile: Record "Document Sending Profile"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToCust: Code[20]; DocNoFieldNo: Integer; ShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendToEmailVendor(var DocumentSendingProfile: Record "Document Sending Profile"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToVendor: Code[20]; VendorNoFieldNo: Integer; ShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShowProfileSelectionMethodDialog(var ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault; AccountNo: Code[20]; IsCustomer: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultSendingProfileForCustomerFromLookup(CustomerNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultSendingProfileForVendorFromLookup(VendorNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRecordAsText(DocumentSendingProfile: Record "Document Sending Profile"; var RecordAsText: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSend(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSendVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendVendorRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; VendorNo: Code[20]; DocumentNo: Code[20]; VendorFieldNo: Integer; DocumentFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSendToDisk(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToCust: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrySendToPrinter(ReportUsage: Integer; RecordVariant: Variant; CustomerFieldNo: Integer; ShowDialog: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrySendToEMail(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerFieldNo: Integer; var ShowDialog: Boolean; var Handled: Boolean; var IsCustomer: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckElectronicSendingEnabled(var ExchServiceEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentName(ReportUsage: Enum "Report Selection Usage"; var DocumentName: Text[150])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultOnBeforeDocumentSendingProfileInsert(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendCustomerRecordsOnBeforeLookupProfile(ReportUsage: Integer; RecordVariant: Variant; CustomerNo: Code[20]; var RecRefToSend: RecordRef; SingleCustomerSelected: Boolean; var ShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendVendorRecordsOnBeforeLookupProfile(ReportUsage: Integer; RecordVariant: Variant; VendorNo: Code[20]; var RecRefToSend: RecordRef; SingleVendorSelected: Boolean; var ShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifySelectedOptionsValid(var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordAsText(DocumentSendingProfile: Record "Document Sending Profile"; var RecordAsText: Text; RecordAsTextFormatterTxt: Text; FieldCaptionContentFormatterTxt: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendToPrinter(var DocumentSendingProfile: Record "Document Sending Profile"; var ReportSelections: Record "Report Selections"; RecordVariant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendWithReportDistributionManagement(var DocumentSendingProfile: Record "Document Sending Profile"; var SendWithReportDistributionManagement: Boolean)
    begin
    end;
}

