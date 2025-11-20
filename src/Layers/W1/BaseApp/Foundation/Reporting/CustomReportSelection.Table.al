// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Email;
using System.Reflection;
using System.Text;
using System.Utilities;

table 9657 "Custom Report Selection"
{
    Caption = 'Custom Report Selection';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(2; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(18)) Customer."No."
            else
            if ("Source Type" = const(23)) Vendor."No.";
        }
        field(3; Usage; Enum "Report Selection Usage")
        {
            Caption = 'Usage';
        }
        field(4; Sequence; Integer)
        {
            AutoIncrement = true;
            Caption = 'Sequence';
        }
        field(5; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = "Report Metadata"."ID";
            ToolTip = 'Specifies the ID of the report.';

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
                if (("Report ID" = 0) or ("Report ID" <> xRec."Report ID")) then begin
                    Validate("Custom Report Layout Code", '');
                    Validate("Email Body Layout Code", '');
                    Validate("Email Body Layout Name", '');
                    Validate("Email Attachment Layout Name", '');
                end;
            end;
        }
        field(6; "Report Caption"; Text[250])
        {
            CalcFormula = lookup("Report Metadata".Caption where("ID" = field("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the name of the report.';
        }
        field(7; "Custom Report Layout Code"; Code[20])
        {
            Caption = 'Custom Report Layout Code';
            TableRelation = "Custom Report Layout" where(Code = field("Custom Report Layout Code"));

            trigger OnValidate()
            begin
                CalcFields("Custom Report Description");
            end;
        }
        field(8; "Custom Report Description"; Text[250])
        {
            CalcFormula = lookup("Custom Report Layout".Description where(Code = field("Custom Report Layout Code")));
            Caption = 'Custom Report Description';
            FieldClass = FlowField;
            ToolTip = 'Specifies a description of the custom report layout.';
        }
        field(9; "Send To Email"; Text[200])
        {
            Caption = 'Send To Email';
            ToolTip = 'Specifies that the report is used when sending emails.';

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "Send To Email" <> '' then begin
                    if "Use Email from Contact" then
                        Error(UseEmailFromContactErr);
                    MailManagement.CheckValidEmailAddresses("Send To Email");
                end else
                    ClearSeletedContactsFilter();
            end;
        }
        field(19; "Use for Email Attachment"; Boolean)
        {
            Caption = 'Use for Email Attachment';
            InitValue = true;
            ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';

            trigger OnValidate()
            begin
                if not "Use for Email Body" then begin
                    Validate("Email Body Layout Code", '');
                    Validate("Email Body Layout AppID", EmptyGuid);
                    Validate("Email Body Layout Name", '');
                end;
            end;
        }
        field(20; "Use for Email Body"; Boolean)
        {
            Caption = 'Use for Email Body';
            ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';

            trigger OnValidate()
            begin
                if not "Use for Email Body" then begin
                    Validate("Email Body Layout Code", '');
                    Validate("Email Body Layout AppID", EmptyGuid);
                    Validate("Email Body Layout Name", '');
                end;
            end;
        }
        field(21; "Email Body Layout Code"; Code[20])
        {
            Caption = 'Email Body Layout Code';
            TableRelation = "Custom Report Layout" where(Code = field("Email Body Layout Code"),
                                                          "Report ID" = field("Report ID"));
            ToolTip = 'Specifies the ID of the email body layout that is used.';

            trigger OnValidate()
            begin
                if "Email Body Layout Code" <> '' then
                    TestField("Use for Email Body", true);
                CalcFields("Email Body Layout Description");
            end;
        }
        field(22; "Email Body Layout Description"; Text[250])
        {
            CalcFormula = lookup("Custom Report Layout".Description where(Code = field("Email Body Layout Code")));
            Caption = 'Email Body Layout Description';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies a description of the custom email body layout that is used.';
        }
        field(23; "Use Email from Contact"; Boolean)
        {
            Caption = 'Use Email from Contacts';
        }
        field(24; "Selected Contacts Filter"; Blob)
        {
            Caption = 'Selected Contacts Filter';
        }
        field(25; "Email Attachment Layout Name"; Text[250])
        {
            Caption = 'Email attachment layout name';
            Editable = false;
        }
        field(26; "Email Attachment Layout AppID"; Guid)
        {
            Caption = 'Email attachment layout App ID';
            Editable = false;
        }
        field(27; "Email Body Layout Name"; Text[250])
        {
            Caption = 'Email body layout name';
            Editable = false;
        }
        field(28; "Email Body Layout AppID"; Guid)
        {
            Caption = 'Email body layout App ID';
            Editable = false;
        }
        field(29; "Email Body Layout Caption"; Text[250])
        {
            Caption = 'Email Body Layout';
            ToolTip = 'Specifies the description of the report layout that is used for email body.';
            FieldClass = FlowField;
            CalcFormula = lookup("Report Layout List".Caption where("Report ID" = field("Report ID"), Name = field("Email Attachment Layout Name")));
            Editable = false;

            trigger OnLookup()
            var
                ReportLayoutList: Record "Report Layout List";
                ReportManagement: Codeunit ReportManagement;
                Handled: Boolean;
            begin
                ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                ReportManagement.OnSelectReportLayout(ReportLayoutList, Handled);
                if not Handled then
                    exit;
                "Email Body Layout Name" := ReportLayoutList.Name;
                "Email Body Layout AppID" := ReportLayoutList."Application ID";
            end;
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source No.", Usage, Sequence)
        {
            Clustered = true;
        }
        key(Key2; "Report ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Report ID");
    end;

    trigger OnModify()
    begin
        TestField("Report ID");
    end;

    var
        TargetEmailAddressErr: Label 'The target email address has not been specified on the document layout for %1, %2. //Choose the Document Layouts action on the customer or vendor card to specify the email address.', Comment = '%1 - Source Data RecordID, %2 - Usage';
        ExceededContactsNotificationTxt: Label 'Too many contacts were selected. Only %1 of %2 contact emails were processed. You can revise contact selection.', Comment = '%1 = number of contacts, %2 = number of contacts';
        UseEmailFromContactErr: Label 'You already use emails from contacts and cannot enter email addresses manually. Delete the value in the Send to Email field, and then enter another email address.';
        StartUseEmailFromContactTxt: Label 'Choose the Select Email from Contacts action if you want to view the list of contacts that will be used to send emails.';
        EmptyGuid: Guid;

    procedure InitUsage()
    begin
        Usage := xRec.Usage;
    end;

    procedure FilterReportUsage(NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
        Reset();
        SetRange("Source Type", NewSourceType);
        SetRange("Source No.", NewSourceNo);
        SetRange(Usage, NewUsage);
    end;

    procedure FilterEmailBodyUsage(NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
        FilterReportUsage(NewSourceType, NewSourceNo, NewUsage);
        SetRange("Use for Email Body", true);

        OnAfterFilterEmailBodyUsage(Rec, NewSourceType, NewSourceNo, NewUsage);
    end;

    local procedure LookupCustomReportLayout(CurrentLayoutCode: Code[20]): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        if CustomReportLayout.LookupLayoutOK("Report ID") then
            exit(CustomReportLayout.Code);

        exit(CurrentLayoutCode);
    end;

    procedure LookupCustomReportDescription()
    begin
        Validate("Custom Report Layout Code", LookupCustomReportLayout("Custom Report Layout Code"));
    end;

    procedure LookupEmailBodyDescription()
    begin
        Validate("Email Body Layout Code", LookupCustomReportLayout("Custom Report Layout Code"));
    end;

    [Scope('OnPrem')]
    procedure CheckEmailSendTo(DataRecRef: RecordRef)
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessage: Text;
    begin
        if GetSendToEmail(true) = '' then begin
            ErrorMessage := StrSubstNo(TargetEmailAddressErr, DataRecRef.RecordId, Usage);
            ErrorMessageManagement.LogError(Rec, ErrorMessage, '');
        end;
    end;

    procedure CopyFromReportSelections(var ReportSelections: Record "Report Selections"; SourceType: Integer; SourceNo: Code[20])
    var
        CustomReportSelection: Record "Custom Report Selection";
        SequenceNo: Integer;
    begin
        if ReportSelections.FindSet() then begin
            SequenceNo := GetSequenceNo();
            CustomReportSelection.SetRange("Source Type", SourceType);
            CustomReportSelection.SetRange("Source No.", SourceNo);
            repeat
                CustomReportSelection.SetRange(Usage, ReportSelections.Usage);
                CustomReportSelection.SetRange("Report ID", ReportSelections."Report ID");
                if CustomReportSelection.IsEmpty() then begin
                    Init();
                    Validate("Source Type", SourceType);
                    Validate("Source No.", SourceNo);
                    Validate(Usage, ReportSelections.Usage);
                    Validate(Sequence, SequenceNo);
                    Validate("Report ID", ReportSelections."Report ID");
                    Validate("Use for Email Body", ReportSelections."Use for Email Body");
                    Validate("Use for Email Attachment", ReportSelections."Use for Email Attachment");
                    Validate("Custom Report Layout Code", ReportSelections."Custom Report Layout Code");
                    if ReportSelections."Email Body Layout Type" = ReportSelections."Email Body Layout Type"::"Custom Report Layout" then
                        Validate("Email Body Layout Code", ReportSelections."Email Body Layout Code");
                    Validate("Email Body Layout Name", ReportSelections."Email Body Layout Name");
                    Validate("Email Body Layout AppID", ReportSelections."Email Body Layout AppID");
                    Validate("Email Attachment Layout Name", ReportSelections."Report Layout Name");
                    Validate("Email Attachment Layout AppID", ReportSelections."Report Layout AppID");
                    OnCopyFromReportSelectionsOnBeforeInsert(Rec, ReportSelections);
                    Insert();
                    SequenceNo += 1;
                end;
            until ReportSelections.Next() = 0;
        end;

        OnCopyFromReportSelections(Rec, ReportSelections);
    end;

    procedure GetSendToEmailFromContactsSelection(LinkType: Option; LinkNo: Code[20])
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.FindContactsByRelation(Contact, "Contact Business Relation Link to Table".FromInteger(LinkType), LinkNo);
        if IsCustomerVendorLinkType("Contact Business Relation Link to Table".FromInteger(LinkType)) then
            GetCustomerVendorAdditionalContacts(Contact, "Contact Business Relation Link to Table".FromInteger(LinkType), LinkNo);
        if Contact.FindSet() then
            if Contact.GetContactsSelectionFromContactList(true) then
                GetSendToEmailFromContacts(Contact);
    end;

    procedure GetSendToEmailFromContacts(var Contact: Record Contact)
    var
        ExceededContactsNotification: Notification;
        EmailList: Text;
        FieldLenghtExceeded: Boolean;
        MaxFieldLength: Integer;
        ProcessedContactsCount: Integer;
        ShowExceededContactsNotification: Boolean;
    begin
        "Send To Email" := '';
        if Contact.FindSet() then begin
            MaxFieldLength := MaxStrLen("Send To Email");
            repeat
                if Contact."E-Mail" <> '' then
                    if StrLen(EmailList + Contact."E-Mail") <= MaxFieldLength then begin
                        ProcessedContactsCount += 1;
                        EmailList += Contact."E-Mail";
                        if StrLen(EmailList) < MaxFieldLength then
                            EmailList += ';';
                    end else begin
                        FieldLenghtExceeded := true;
                        ShowExceededContactsNotification := FieldLenghtExceeded;
                    end;
            until (Contact.Next() = 0) or FieldLenghtExceeded;
        end;
        EmailList := DelChr(EmailList, '>', ';');
        "Send To Email" := CopyStr(EmailList, 1, MaxStrLen("Send To Email"));
        if "Send To Email" <> '' then
            FillSelectedContactsFilter(Contact.GetFilter("No."));
        OnGetSendToEmailFromContacts(Rec, Contact, ShowExceededContactsNotification);

        if ShowExceededContactsNotification then begin
            ExceededContactsNotification.Scope(NotificationScope::LocalScope);
            ExceededContactsNotification.Message(StrSubstNo(ExceededContactsNotificationTxt, ProcessedContactsCount, Contact.Count));
            ExceededContactsNotification.Send();
        end;
    end;

    procedure ShowSelectedContacts()
    var
        Contact: Record Contact;
    begin
        if "Use Email from Contact" then begin
            Contact.SetFilter("No.", GetSelectedContactsFilter());
            Contact.GetContactsSelectionFromContactList(false);
        end else
            Message(StartUseEmailFromContactTxt);
    end;

    local procedure ClearSeletedContactsFilter()
    begin
        CalcFields("Selected Contacts Filter");
        Clear("Selected Contacts Filter");
        "Use Email from Contact" := false;
    end;

    local procedure FillSelectedContactsFilter(SelectedContactsFilter: Text)
    var
        OStream: OutStream;
    begin
        if SelectedContactsFilter = '' then
            exit;
        if "Selected Contacts Filter".HasValue() then begin
            CalcFields("Selected Contacts Filter");
            Clear("Selected Contacts Filter");
        end;
        "Selected Contacts Filter".CreateOutStream(OStream);
        OStream.WriteText(SelectedContactsFilter);
        "Use Email from Contact" := true;
    end;

    local procedure GetSelectedContactsFilter() SelectedContactsFilter: Text
    var
        IStream: InStream;
    begin
        if not "Selected Contacts Filter".HasValue() then
            exit('');

        CalcFields("Selected Contacts Filter");
        "Selected Contacts Filter".CreateInStream(IStream);
        IStream.ReadText(SelectedContactsFilter);
        OnGetSelectedContactsFilter(SelectedContactsFilter);
    end;

    procedure GetSendToEmail(Update: Boolean) Result: Text[250]
    var
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSendToEmail(Update, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Use Email from Contact" then begin
            Contact.SetFilter("No.", GetSelectedContactsFilter());
            FillSendToEmail(Contact);
            if Update then
                Modify();
        end;
        exit("Send To Email");
    end;

    local procedure FillSendToEmail(var Contact: Record Contact)
    var
        EmailList: Text;
        MaxFieldLength: Integer;
        FieldLenghtExceeded: Boolean;
    begin
        "Send To Email" := '';
        MaxFieldLength := MaxStrLen("Send To Email");
        if Contact.FindSet() then
            repeat
                if Contact."E-Mail" <> '' then
                    if StrLen(EmailList + Contact."E-Mail") <= MaxFieldLength then begin
                        EmailList += Contact."E-Mail";
                        if StrLen(EmailList) < MaxFieldLength then
                            EmailList += ';';
                    end else
                        FieldLenghtExceeded := true;
            until (Contact.Next() = 0) or FieldLenghtExceeded;
        EmailList := DelChr(EmailList, '>', ';');
        "Send To Email" := CopyStr(EmailList, 1, MaxStrLen("Send To Email"));
    end;

    procedure UpdateSendtoEmail(Update: Boolean)
    begin
        if FindSet() then
            repeat
                GetSendToEmail(Update);
            until Next() = 0;
    end;

    local procedure GetSequenceNo(): Integer
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        CustomReportSelection.SetCurrentKey(Sequence);
        if CustomReportSelection.FindLast() then
            exit(CustomReportSelection.Sequence + 1);
        exit(1);
    end;

    local procedure IsCustomerVendorLinkType(LinkType: Enum "Contact Business Relation Link To Table"): Boolean
    begin
        exit((LinkType = LinkType::Customer) or (LinkType = LinkType::Vendor));
    end;

    local procedure GetCustomerVendorAdditionalContacts(var Contact: Record Contact; LinkType: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BillToPayToContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        CVNo: Code[20];
    begin
        case LinkType of
            "Contact Business Relation Link To Table"::Customer:
                begin
                    Customer.Get(LinkNo);
                    if Customer.Get(Customer."Bill-to Customer No.") then
                        CVNo := Customer."No.";
                end;
            "Contact Business Relation Link To Table"::Vendor:
                begin
                    Vendor.Get(LinkNo);
                    if Vendor.Get(Vendor."Pay-to Vendor No.") then
                        CVNo := Vendor."No.";
                end;
        end;

        if ContactBusinessRelation.FindContactsByRelation(BillToPayToContact, LinkType, CVNo) then
            CombineContacts(Contact, BillToPayToContact);
    end;

    local procedure CombineContacts(var Contact: Record Contact; var BillToPayToContact: Record Contact)
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        ContactNoFilter: Text;
    begin
        ContactNoFilter := SelectionFilterManagement.GetSelectionFilterForContact(Contact);
        if ContactNoFilter <> '' then
            ContactNoFilter += '|' + SelectionFilterManagement.GetSelectionFilterForContact(BillToPayToContact)
        else
            ContactNoFilter := SelectionFilterManagement.GetSelectionFilterForContact(BillToPayToContact);

        Contact.Reset();
        Contact.SetFilter("No.", ContactNoFilter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterEmailBodyUsage(var CustomReportSelection: Record "Custom Report Selection"; NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
    end;


    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetSendToEmail(Update: Boolean; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnCopyFromReportSelections(var CustomReportSelection: Record "Custom Report Selection"; var ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromReportSelectionsOnBeforeInsert(var CustomReportSelection: Record "Custom Report Selection"; ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSendToEmailFromContacts(var CustomReportSelection: Record "Custom Report Selection"; var Contact: Record Contact; var ShowExceededContactsNotification: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSelectedContactsFilter(var SelectedContactsFilter: Text)
    begin
    end;
}