// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Campaign;
using Microsoft.Utilities;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.Globalization;
using System.Integration;
using System.Security.AccessControl;

table 5065 "Interaction Log Entry"
{
    Caption = 'Interaction Log Entry';
    DataClassification = CustomerContent;
    DrillDownPageID = "Interaction Log Entries";
    LookupPageID = "Interaction Log Entries";
    ReplicateData = true;
    Permissions = tabledata "Interaction Log Entry" = rimd,
                  tabledata "Inter. Log Entry Comment Line" = rd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(3; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            TableRelation = Contact where(Type = const(Company));
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Information Flow"; Option)
        {
            Caption = 'Information Flow';
            OptionCaption = ' ,Outbound,Inbound';
            OptionMembers = " ",Outbound,Inbound;
        }
        field(7; "Initiated By"; Option)
        {
            Caption = 'Initiated By';
            OptionCaption = ' ,Us,Them';
            OptionMembers = " ",Us,Them;
        }
        field(8; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
            TableRelation = Attachment;
        }
        field(9; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Cost (LCY)';
            Editable = false;
        }
        field(10; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(12; "Interaction Group Code"; Code[10])
        {
            Caption = 'Interaction Group Code';
            TableRelation = "Interaction Group";
        }
        field(13; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            TableRelation = "Interaction Template";
        }
        field(14; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(15; "Campaign Entry No."; Integer)
        {
            Caption = 'Campaign Entry No.';
            TableRelation = "Campaign Entry" where("Campaign No." = field("Campaign No."));
        }
        field(16; "Campaign Response"; Boolean)
        {
            Caption = 'Campaign Response';
        }
        field(17; "Campaign Target"; Boolean)
        {
            Caption = 'Campaign Target';
        }
        field(18; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
        }
        field(19; Evaluation; Enum "Interaction Evaluation")
        {
            Caption = 'Evaluation';
            Editable = false;
        }
        field(20; "Time of Interaction"; Time)
        {
            Caption = 'Time of Interaction';
        }
        field(21; "Attempt Failed"; Boolean)
        {
            Caption = 'Attempt Failed';
        }
        field(23; "To-do No."; Code[20])
        {
            Caption = 'Task No.';
            TableRelation = "To-do";
        }
        field(24; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(25; "Delivery Status"; Enum "Interaction Delivery Status")
        {
            Caption = 'Delivery Status';
        }
        field(26; Canceled; Boolean)
        {
            Caption = 'Canceled';
        }
        field(27; "Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type';
        }
        field(28; "Contact Alt. Address Code"; Code[10])
        {
            Caption = 'Contact Alt. Address Code';
            TableRelation = "Contact Alt. Address".Code where("Contact No." = field("Contact No."));
        }
        field(29; "Logged Segment Entry No."; Integer)
        {
            Caption = 'Logged Segment Entry No.';
            TableRelation = "Logged Segment";
        }
        field(30; "Document Type"; Enum "Interaction Log Entry Document Type")
        {
            Caption = 'Document Type';
        }
        field(31; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(32; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(33; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(34; "Contact Via"; Text[80])
        {
            Caption = 'Contact Via';
        }
        field(35; "Send Word Docs. as Attmt."; Boolean)
        {
            Caption = 'Send Word Docs. as Attmt.';
        }
        field(36; "Interaction Language Code"; Code[10])
        {
            Caption = 'Interaction Language Code';
            TableRelation = Language;
        }
        field(37; "E-Mail Logged"; Boolean)
        {
            Caption = 'Email Logged';
        }
        field(38; Subject; Text[100])
        {
            Caption = 'Subject';
        }
        field(39; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact Company No."), Type = const(Company)));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; Comment; Boolean)
        {
            CalcFormula = exist("Inter. Log Entry Comment Line" where("Entry No." = field("Entry No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        field(45; Postponed; Boolean)
        {
            Caption = 'Postponed';
        }
        field(46; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
        }
        field(47; Merged; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(48; "Modified Word Template"; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contact Company No.", "Contact No.", Date, Postponed)
        {
        }
        key(Key3; "Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed", Postponed)
        {
        }
        key(Key4; "Interaction Group Code", Date)
        {
        }
        key(Key5; "Interaction Group Code", Canceled, Date, Postponed)
        {
        }
        key(Key6; "Interaction Template Code", Date)
        {
        }
        key(Key7; "Interaction Template Code", Canceled, Date, Postponed)
        {
            IncludedFields = "Cost (LCY)", "Duration (Min.)";
        }
        key(Key8; Canceled, "Campaign No.", "Campaign Entry No.", Date, Postponed)
        {
        }
        key(Key9; "Campaign No.", "Campaign Entry No.", Date, Postponed)
        {
        }
        key(Key10; "Salesperson Code", Date, Postponed)
        {
        }
        key(Key11; Canceled, "Salesperson Code", Date, Postponed)
        {
            IncludedFields = "Cost (LCY)", "Duration (Min.)";
        }
        key(Key12; "Logged Segment Entry No.", Postponed)
        {
        }
        key(Key13; "Attachment No.")
        {
        }
        key(Key14; "To-do No.", Date)
        {
        }
        key(Key15; "Contact No.", "Correspondence Type", "E-Mail Logged", Subject, Postponed)
        {
        }
        key(Key16; "Campaign No.", "Campaign Target")
        {
        }
        key(Key17; "Campaign No.", "Contact Company No.", "Campaign Target", Postponed)
        {
        }
        key(Key18; "Opportunity No.", Date)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Contact No.", Date)
        {
        }
        fieldgroup(Brick; "Salesperson Code", Description, Date, "Contact Name", "Contact Company Name")
        {
        }
    }

    trigger OnDelete()
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        Attachment: Record Attachment;
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
    begin
        InterLogEntryCommentLine.SetRange("Entry No.", "Entry No.");
        if not InterLogEntryCommentLine.IsEmpty() then
            InterLogEntryCommentLine.DeleteAll();

        CampaignTargetGroupMgt.DeleteContfromTargetGr(Rec);
        if UniqueAttachment() then
            if Attachment.Get("Attachment No.") then
                Attachment.RemoveAttachment(false);
    end;

    var
#pragma warning disable AA0470
        MarkedAsFormatTxt: Label '%1 %2 is marked %3.\';
#pragma warning restore AA0470
        RemoveCheckmarkQst: Label 'Do you wish to remove the checkmark?';
#pragma warning disable AA0470
        MarkAsQst: Label 'Do you wish to mark %1 %2 as %3?';
#pragma warning restore AA0470
        CantViewStatementsErr: Label 'It is not possible to view sales statements after they have been printed.';
        CantShowCoverSheetsErr: Label 'It is not possible to show cover sheets after they have been printed.';
#pragma warning disable AA0470
        RemoveCheckmarkLinesQst: Label 'Do you wish to remove the checkmark from the selected %1 lines?';
        MarkLinesAsQst: Label 'Do you wish to mark the selected %1 lines as %2?';
#pragma warning restore AA0470
        RemoveAttachmentQst: Label 'Do you want to remove Attachment?';
        RemoveUniqueAttachmentsQst: Label 'Do you want to remove unique Attachments for the selected lines?';
        EvaluationOptionsTxt: Label 'Very Positive,Positive,Neutral,Negative,Very Negative';
        TitleFromLbl: Label '%1 - from %2', Comment = '%1 - document description, %2 - name';
        TitleByLbl: Label '%1 - by %2', Comment = '%1 - document description, %2 - name';
        OpenMessageQst: Label 'You are about to open an email message in Outlook Online. Email messages might contain harmful content. Use caution when interacting with the message. Do you want to continue?';

    [InherentPermissions(PermissionObjectType::TableData, Database::"Interaction Log Entry", 'r')]
    procedure InsertRecord()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if not Insert() then begin
            SequenceNoMgt.RebaseSeqNo(Database::"Interaction Log Entry");
            "Entry No." := SequenceNoMgt.GetNextSeqNo(Database::"Interaction Log Entry");
            Insert();
        end;
    end;

    procedure AssignNewOpportunity()
    var
        Opportunity: Record Opportunity;
        Contact: Record Contact;
    begin
        TestField(Canceled, false);
        TestField("Opportunity No.", '');
        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        if "Contact Company No." <> '' then
            if Contact.Get("Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        Opportunity.CreateFromInteractionLogEntry(Rec);
        "Opportunity No." := Opportunity."No.";
        Modify();
    end;

    procedure CanCreateOpportunity(): Boolean
    begin
        exit(not Canceled and ("Opportunity No." = ''));
    end;

    procedure CopyFromSegment(SegLine: Record "Segment Line")
    begin
        "Contact No." := SegLine."Contact No.";
        "Contact Company No." := SegLine."Contact Company No.";
        Date := SegLine.Date;
        Description := SegLine.Description;
        "Information Flow" := SegLine."Information Flow";
        "Initiated By" := SegLine."Initiated By";
        "Attachment No." := SegLine."Attachment No.";
        "Cost (LCY)" := SegLine."Cost (LCY)";
        "Duration (Min.)" := SegLine."Duration (Min.)";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Interaction Group Code" := SegLine."Interaction Group Code";
        "Interaction Template Code" := SegLine."Interaction Template Code";
        "Interaction Language Code" := SegLine."Language Code";
        Subject := SegLine.Subject;
        "Campaign No." := SegLine."Campaign No.";
        "Campaign Entry No." := SegLine."Campaign Entry No.";
        "Campaign Response" := SegLine."Campaign Response";
        "Campaign Target" := SegLine."Campaign Target";
        "Segment No." := SegLine."Segment No.";
        Evaluation := SegLine.Evaluation;
        "Time of Interaction" := SegLine."Time of Interaction";
        "Attempt Failed" := SegLine."Attempt Failed";
        "To-do No." := SegLine."To-do No.";
        "Salesperson Code" := SegLine."Salesperson Code";
        "Correspondence Type" := SegLine."Correspondence Type";
        "Contact Alt. Address Code" := SegLine."Contact Alt. Address Code";
        "Document Type" := SegLine."Document Type";
        "Document No." := SegLine."Document No.";
        "Doc. No. Occurrence" := SegLine."Doc. No. Occurrence";
        "Version No." := SegLine."Version No.";
        "Send Word Docs. as Attmt." := SegLine."Send Word Doc. As Attmt.";
        "Contact Via" := SegLine."Contact Via";
        "Opportunity No." := SegLine."Opportunity No.";
        "Word Template Code" := SegLine."Word Template Code";
        Merged := SegLine.Merged;

        OnAfterCopyFromSegment(Rec, SegLine);
    end;

    procedure CreateInteraction()
    var
        TempSegmentLine: Record "Segment Line" temporary;
        Contact: Record Contact;
    begin
        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        if "Contact Company No." <> '' then
            if Contact.Get("Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        TempSegmentLine.CreateInteractionFromInteractLogEntry(Rec);
    end;

    procedure CreateTask()
    var
        TempToDoTask: Record "To-do" temporary;
        Contact: Record Contact;
    begin
        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        if "Contact Company No." <> '' then
            if Contact.Get("Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        TempToDoTask.CreateTaskFromInteractLogEntry(Rec)
    end;

    procedure OpenAttachment()
    var
        Attachment: Record Attachment;
        SegmentLine: Record "Segment Line";
        WebRequestHelper: Codeunit "Web Request Helper";
        InStream: InStream;
        EmailMessageUrl: Text;
        IsHandled: Boolean;
    begin
        if "Attachment No." = 0 then
            exit;

        Attachment.Get("Attachment No.");

        IsHandled := false;
        OnBeforeOpenAttachment(Rec, IsHandled, Attachment);
        if IsHandled then
            exit;

        if Attachment."Storage Type" <> Attachment."Storage Type"::"Exchange Storage" then begin
            SegmentLine."Contact No." := "Contact No.";
            SegmentLine."Salesperson Code" := "Salesperson Code";
            SegmentLine."Contact Alt. Address Code" := "Contact Alt. Address Code";
            SegmentLine.Date := Date;
            SegmentLine."Campaign No." := "Campaign No.";
            SegmentLine."Segment No." := "Segment No.";
            SegmentLine."Line No." := "Entry No.";
            SegmentLine.Description := Description;
            SegmentLine.Subject := Subject;
            SegmentLine."Language Code" := "Interaction Language Code";
            OnOpenAttachmentOnBeforeShowAttachment(Rec, SegmentLine, Attachment);
            Attachment.ShowAttachment(SegmentLine, Format("Entry No.") + ' ' + Description);
        end else begin
            Attachment.CalcFields("Email Message Url");
            if Attachment."Email Message Url".HasValue() then begin
                Attachment."Email Message Url".CreateInStream(InStream);
                InStream.Read(EmailMessageUrl);
                if WebRequestHelper.IsHttpUrl(EmailMessageUrl) then begin
                    if Confirm(OpenMessageQst, true) then
                        HyperLink(EmailMessageUrl);
                    exit;
                end;
            end;
        end;

        OnAfterOpenAttachment(Rec, Attachment, SegmentLine);
    end;

    procedure ToggleCanceledCheckmark()
    var
        ErrorTxt: Text[80];
        MasterCanceledCheckmark: Boolean;
        RemoveUniqueAttachment: Boolean;
    begin
        if Find('-') then
            if ConfirmToggleCanceledCheckmark(Count, ErrorTxt) then begin
                MasterCanceledCheckmark := not Canceled;
                if FindUniqueAttachment() and MasterCanceledCheckmark then
                    RemoveUniqueAttachment := Confirm(ErrorTxt, false);
                SetCurrentKey("Entry No.");
                if Find('-') then
                    repeat
                        SetCanceledCheckmark(MasterCanceledCheckmark, RemoveUniqueAttachment);
                    until Next() = 0;
            end;
    end;

    procedure SetCanceledCheckmark(CanceledCheckmark: Boolean; RemoveUniqueAttachment: Boolean)
    var
        CampaignEntry: Record "Campaign Entry";
        LoggedSegment: Record "Logged Segment";
        Attachment: Record Attachment;
        IsHandled: Boolean;
    begin
        OnBeforeSetCanceledCheckmark(Rec, CanceledCheckmark, RemoveUniqueAttachment, IsHandled);
        if IsHandled then
            exit;

        if Canceled and not CanceledCheckmark then begin
            if "Logged Segment Entry No." <> 0 then begin
                LoggedSegment.SetLoadFields(Canceled);
                LoggedSegment.Get("Logged Segment Entry No.");
                LoggedSegment.TestField(Canceled, false);
            end;
            if "Campaign Entry No." <> 0 then begin
                CampaignEntry.SetLoadFields(Canceled);
                CampaignEntry.Get("Campaign Entry No.");
                CampaignEntry.TestField(Canceled, false);
            end;
        end;

        if not Canceled and CanceledCheckmark then
            if UniqueAttachment() and RemoveUniqueAttachment then begin
                if Attachment.Get("Attachment No.") then
                    Attachment.RemoveAttachment(false);
                "Attachment No." := 0;
            end;

        Canceled := CanceledCheckmark;
        Modify();
    end;

    local procedure ConfirmToggleCanceledCheckmark(NumberOfSelectedLines: Integer; var ErrorTxt: Text[80]): Boolean
    begin
        if NumberOfSelectedLines = 1 then begin
            ErrorTxt := RemoveAttachmentQst;
            if Canceled then
                exit(Confirm(
                    MarkedAsFormatTxt +
                    RemoveCheckmarkQst, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));

            exit(Confirm(
                MarkAsQst, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));
        end;
        ErrorTxt := RemoveUniqueAttachmentsQst;
        if Canceled then
            exit(Confirm(
                RemoveCheckmarkLinesQst, true, TableCaption));

        exit(Confirm(
            MarkLinesAsQst, true, TableCaption(), FieldCaption(Canceled)));
    end;

    procedure UniqueAttachment() IsUnique: Boolean
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        if "Attachment No." <> 0 then begin
            InteractLogEntry.SetCurrentKey("Attachment No.");
            InteractLogEntry.SetRange("Attachment No.", "Attachment No.");
            InteractLogEntry.SetFilter("Entry No.", '<>%1', "Entry No.");
            IsUnique := InteractLogEntry.IsEmpty();
        end;
    end;

    local procedure FindUniqueAttachment() IsUnique: Boolean
    begin
        if Find('-') then
            repeat
                IsUnique := UniqueAttachment();
            until (Next() = 0) or IsUnique;
    end;

    procedure ShowDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        PurchHeader: Record "Purchase Header";
        PurchHeaderArchive: Record "Purchase Header Archive";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ReturnRcptHeader: Record "Return Receipt Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDocument(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::"Sales Qte.":
                if "Version No." <> 0 then begin
                    SalesHeaderArchive.Get(
                      SalesHeaderArchive."Document Type"::Quote, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Quote);
                    SalesHeaderArchive.SetRange("No.", "Document No.");
                    SalesHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    Page.Run(Page::"Sales Quote Archive", SalesHeaderArchive);
                end else begin
                    SalesHeader.Get(SalesHeader."Document Type"::Quote, "Document No.");
                    PageManagement.PageRun(SalesHeader);
                end;
            "Document Type"::"Sales Blnkt. Ord":
                if "Version No." <> 0 then begin
                    SalesHeaderArchive.Get(SalesHeaderArchive."Document Type"::"Blanket Order", "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::"Blanket Order");
                    SalesHeaderArchive.SetRange("No.", "Document No.");
                    SalesHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    Page.Run(Page::"Blanket Sales Order Archive", SalesHeaderArchive);
                end else begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Blanket Order", "Document No.");
                    PageManagement.PageRun(SalesHeader);
                end;
            "Document Type"::"Sales Ord. Cnfrmn.":
                if "Version No." <> 0 then begin
                    SalesHeaderArchive.Get(
                      SalesHeaderArchive."Document Type"::Order, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
                    SalesHeaderArchive.SetRange("No.", "Document No.");
                    SalesHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    Page.Run(Page::"Sales Order Archive", SalesHeaderArchive);
                end else begin
                    SalesHeader.Get(SalesHeader."Document Type"::Order, "Document No.");
                    PageManagement.PageRun(SalesHeader);
                end;
            "Document Type"::"Sales Draft Invoice":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Invoice, "Document No.");
                    PageManagement.PageRun(SalesHeader);
                end;
            "Document Type"::"Sales Inv.":
                begin
                    SalesInvHeader.Get("Document No.");
                    PageManagement.PageRun(SalesInvHeader);
                end;
            "Document Type"::"Sales Shpt. Note":
                begin
                    SalesShptHeader.Get("Document No.");
                    PageManagement.PageRun(SalesShptHeader);
                end;
            "Document Type"::"Sales Cr. Memo":
                begin
                    SalesCrMemoHeader.Get("Document No.");
                    PageManagement.PageRun(SalesCrMemoHeader);
                end;
            "Document Type"::"Sales Stmnt.":
                Error(CantViewStatementsErr);
            "Document Type"::"Sales Rmdr.":
                begin
                    IssuedReminderHeader.Get("Document No.");
                    Page.Run(Page::"Issued Reminder", IssuedReminderHeader);
                end;
            "Document Type"::"Purch.Qte.":
                if "Version No." <> 0 then begin
                    PurchHeaderArchive.Get(
                      PurchHeaderArchive."Document Type"::Quote, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    PurchHeaderArchive.SetRange("Document Type", PurchHeaderArchive."Document Type"::Quote);
                    PurchHeaderArchive.SetRange("No.", "Document No.");
                    PurchHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    Page.Run(Page::"Purchase Quote Archive", PurchHeaderArchive);
                end else begin
                    PurchHeader.Get(PurchHeader."Document Type"::Quote, "Document No.");
                    PageManagement.PageRun(PurchHeader);
                end;
            "Document Type"::"Purch. Blnkt. Ord.":
                if "Version No." <> 0 then begin
                    PurchHeaderArchive.Get(
                      PurchHeaderArchive."Document Type"::"Blanket Order", "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    PurchHeaderArchive.SetRange("Document Type", PurchHeaderArchive."Document Type"::"Blanket Order");
                    PurchHeaderArchive.SetRange("No.", "Document No.");
                    PurchHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    Page.Run(Page::"Blanket Purchase Order Archive", PurchHeaderArchive);
                end else begin
                    PurchHeader.Get(PurchHeader."Document Type"::"Blanket Order", "Document No.");
                    PageManagement.PageRun(PurchHeader);
                end;
            "Document Type"::"Purch. Ord.":
                if "Version No." <> 0 then begin
                    PurchHeaderArchive.Get(
                      PurchHeaderArchive."Document Type"::Order, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    PurchHeaderArchive.SetRange("Document Type", PurchHeaderArchive."Document Type"::Order);
                    PurchHeaderArchive.SetRange("No.", "Document No.");
                    PurchHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    Page.Run(Page::"Purchase Order Archive", PurchHeaderArchive);
                end else begin
                    PurchHeader.Get(PurchHeader."Document Type"::Order, "Document No.");
                    PageManagement.PageRun(PurchHeader);
                end;
            "Document Type"::"Purch. Inv.":
                begin
                    PurchInvHeader.Get("Document No.");
                    PageManagement.PageRun(PurchInvHeader);
                end;
            "Document Type"::"Purch. Rcpt.":
                begin
                    PurchRcptHeader.Get("Document No.");
                    PageManagement.PageRun(PurchRcptHeader);
                end;
            "Document Type"::"Purch. Cr. Memo":
                begin
                    PurchCrMemoHeader.Get("Document No.");
                    PageManagement.PageRun(PurchCrMemoHeader);
                end;
            "Document Type"::"Cover Sheet":
                Error(CantShowCoverSheetsErr);
            "Document Type"::"Sales Return Order":
                if SalesHeader.Get(SalesHeader."Document Type"::"Return Order", "Document No.") then
                    PageManagement.PageRun(SalesHeader)
                else begin
                    ReturnRcptHeader.SetRange("Return Order No.", "Document No.");
                    if ReturnRcptHeader.Count() = 1 then
                        PageManagement.PageRun(ReturnRcptHeader)
                    else
                        PageManagement.PageRunList(ReturnRcptHeader);
                end;
            "Document Type"::"Sales Finance Charge Memo":
                begin
                    IssuedFinChargeMemoHeader.Get("Document No.");
                    Page.Run(Page::"Issued Finance Charge Memo", IssuedFinChargeMemoHeader);
                end;
            "Document Type"::"Sales Return Receipt":
                begin
                    ReturnReceiptHeader.Get("Document No.");
                    PageManagement.PageRun(ReturnReceiptHeader);
                end;
            "Document Type"::"Purch. Return Shipment":
                begin
                    ReturnShipmentHeader.Get("Document No.");
                    PageManagement.PageRun(ReturnShipmentHeader);
                end;
            "Document Type"::"Purch. Return Ord. Cnfrmn.":
                if PurchHeader.Get(PurchHeader."Document Type"::"Return Order", "Document No.") then
                    PageManagement.PageRun(PurchHeader)
                else begin
                    ReturnShipmentHeader.SetRange("Return Order No.", "Document No.");
                    if ReturnShipmentHeader.Count() = 1 then
                        PageManagement.PageRun(ReturnShipmentHeader)
                    else
                        PageManagement.PageRunList(ReturnShipmentHeader);
                end;
        end;

        OnAfterShowDocument(Rec);
    end;

    procedure EvaluateInteraction()
    var
        Selected: Integer;
    begin
        if Find('-') then begin
            Selected := Dialog.StrMenu(EvaluationOptionsTxt);
            if Selected <> 0 then
                repeat
                    Evaluation := Enum::"Interaction Evaluation".FromInteger(Selected);
                    Modify();
                until Next() = 0;
        end;
    end;

    procedure ResumeInteraction()
    var
        TempSegmentLine: Record "Segment Line" temporary;
        IsHandled: Boolean;
    begin
        TempSegmentLine.CopyFromInteractLogEntry(Rec);
        TempSegmentLine.Validate(Date, WorkDate());
        OnResumeInteractionOnAfterDateValidation(TempSegmentLine);

        if TempSegmentLine."To-do No." <> '' then
            TempSegmentLine.SetRange("To-do No.", TempSegmentLine."To-do No.");

        if TempSegmentLine."Contact Company No." <> '' then
            TempSegmentLine.SetRange("Contact Company No.", TempSegmentLine."Contact Company No.");

        if TempSegmentLine."Contact No." <> '' then
            TempSegmentLine.SetRange("Contact No.", TempSegmentLine."Contact No.");

        if TempSegmentLine."Salesperson Code" <> '' then
            TempSegmentLine.SetRange("Salesperson Code", TempSegmentLine."Salesperson Code");

        if TempSegmentLine."Campaign No." <> '' then
            TempSegmentLine.SetRange("Campaign No.", TempSegmentLine."Campaign No.");

        if TempSegmentLine."Opportunity No." <> '' then
            TempSegmentLine.SetRange("Opportunity No.", TempSegmentLine."Opportunity No.");

        IsHandled := false;
        OnResumeInteractionOnBeforeStartWizard(Rec, TempSegmentLine, IsHandled);
        if not IsHandled then
            TempSegmentLine.StartWizard();
    end;

    procedure GetEntryTitle() EntryTitle: Text
    var
        InteractionTemplate: Record "Interaction Template";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        User: Record User;
    begin
        InteractionTemplate.SetLoadFields("Description", "Information Flow");
        if InteractionTemplate.Get("Interaction Template Code") then begin
            EntryTitle := InteractionTemplate.Description;
            case InteractionTemplate."Information Flow" of
                InteractionTemplate."Information Flow"::Outbound:
                    begin
                        SalespersonPurchaser.SetLoadFields(Name);
                        if ("Salesperson Code" <> '') and SalespersonPurchaser.Get("Salesperson Code") then
                            EntryTitle := StrSubstNo(TitleByLbl, InteractionTemplate.Description, SalespersonPurchaser.Name)
                        else begin
                            User.SetLoadFields("Full Name");
                            User.SetRange("User Name", "User ID");
                            if User.FindFirst() then
                                EntryTitle := StrSubstNo(TitleByLbl, InteractionTemplate.Description, User."Full Name");
                        end;
                    end;
                InteractionTemplate."Information Flow"::Inbound:
                    begin
                        CalcFields("Contact Name");
                        EntryTitle := StrSubstNo(TitleFromLbl, InteractionTemplate.Description, "Contact Name");
                    end;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSegment(var InteractionLogEntry: Record "Interaction Log Entry"; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocument(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; var IsHandled: Boolean; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocument(var InteractionLogEntry: Record "Interaction Log Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCanceledCheckmark(var InteractionLogEntry: Record "Interaction Log Entry"; CanceledCheckmark: Boolean; RemoveUniqueAttachment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; Attachment: Record Attachment; var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenAttachmentOnBeforeShowAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; var SegmentLine: Record "Segment Line"; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResumeInteractionOnBeforeStartWizard(InteractionLogEntry: Record "Interaction Log Entry"; var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResumeInteractionOnAfterDateValidation(var TempSegmentLine: Record "Segment Line" temporary)
    begin
    end;
}
