// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.IO;

codeunit 5051 SegManagement
{
    Permissions = tabledata "Interaction Log Entry" = rimd,
                  tabledata "Interaction Template" = r,
                  tabledata "Inter. Log Entry Comment Line" = rd,
                  tabledata Contact = r;

    trigger OnRun()
    begin
    end;

    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InterTemplateSalesInvoicesNotSpecifiedErr: Label 'The Invoices field on the Sales FastTab in the Interaction Template Setup window must be filled in.';
        SegmentSendContactEmailFaxMissingErr: Label 'Make sure that the %1 field is specified for either contact no. %2 or the contact alternative address.', Comment = '%1 - Email or Fax No. field caption, %2 - Contact No.';
        LoggedSegmentExistsErr: Label '%1 for Segment No. %2 already exists.', Comment = '%1 - Logged Segment Table Caption, %2 - Segment No.';
        EmptySegmentErr: Label 'Segment %1 is empty.', Comment = '%1 - Segment No.';
        FollowUpOnSegmentLbl: Label 'Follow-up on segment %1', Comment = '%1 - Segment No.';
        InteractionTemplateAssignedLanguageErr: Label 'Interaction Template %1 has assigned Interaction Template Language %2.\It is not allowed to have languages assigned to templates used for system document logging.', Comment = '%1 - Interaction Template Code, %2 - Interaction Template Language Code';
        InteractionsLbl: Label 'Interactions';

    [InherentPermissions(PermissionObjectType::TableData, Database::"Interaction Log Entry", 'r')]
    procedure LogSegment(SegmentHeader: Record "Segment Header"; Deliver: Boolean; Followup: Boolean)
    var
        SegmentLine: Record "Segment Line";
        LoggedSegment: Record "Logged Segment";
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
        InteractionTemplate: Record "Interaction Template";
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        SegmentNo: Code[20];
        CampaignNo: Code[20];
        ShowIsNotEmptyError: Boolean;
        ShouldModifyAttachment: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeLogSegment(SegmentHeader, Deliver, Followup);
        LoggedSegment.LockTable();
        LoggedSegment.SetCurrentKey("Segment No.");
        LoggedSegment.SetRange("Segment No.", SegmentHeader."No.");
        ShowIsNotEmptyError := not LoggedSegment.IsEmpty();
        OnLogSegmentOnAfterCalcShowIsNotEmptyError(LoggedSegment, Deliver, ShowIsNotEmptyError);
        if ShowIsNotEmptyError then
            Error(LoggedSegmentExistsErr, LoggedSegment.TableCaption(), SegmentHeader."No.");

        SegmentHeader.TestField(Description);

        IsHandled := false;
        OnLogSegmentOnBeforeInitLoggedSegment(SegmentHeader, Deliver, Followup, IsHandled);
        if IsHandled then
            exit;

        LoggedSegment.Reset();
        LoggedSegment.Init();
        LoggedSegment."Entry No." := GetNextLoggedSegmentEntryNo();
        LoggedSegment."Segment No." := SegmentHeader."No.";
        LoggedSegment.Description := SegmentHeader.Description;
        LoggedSegment."Creation Date" := Today;
        LoggedSegment."User ID" := CopyStr(UserId(), 1, MaxStrLen(LoggedSegment."User ID"));
        OnBeforeLoggedSegmentInsert(LoggedSegment);
        LoggedSegment.Insert();
        OnLogSegmentOnAfterLoggedSegmentInsert(LoggedSegment, SegmentHeader);

        SegmentLine.LockTable();
        SegmentLine.SetCurrentKey("Segment No.", "Campaign No.", Date);
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.SetFilter("Campaign No.", '<>%1', '');
        SegmentLine.SetFilter("Contact No.", '<>%1', '');
        if SegmentLine.FindSet() then
            repeat
                SegmentLine."Campaign Entry No." := GetCampaignEntryNo(SegmentLine, LoggedSegment."Entry No.");
                OnBeforeCampaignEntryNoModify(SegmentLine);
                SegmentLine.Modify();
            until SegmentLine.Next() = 0;

        SegmentLine.Reset();
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.SetFilter("Contact No.", '<>%1', '');

        SegmentHeader.CalcFields("Modified Word Template");
        if SegmentHeader."Modified Word Template" > 0 then begin
            Attachment.Get(SegmentHeader."Modified Word Template");
            Attachment."Read Only" := true;
            Attachment.Modify(true);
        end;

        if SegmentLine.FindSet() then
            repeat
                if InteractionTemplate.Get(SegmentLine."Interaction Template Code") then;
                CheckSegmentLine(SegmentLine, Deliver);
                InteractionLogEntry.Init();
                InteractionLogEntry."Entry No." := SequenceNoMgt.GetNextSeqNo(Database::"Interaction Log Entry");
                InteractionLogEntry."Logged Segment Entry No." := LoggedSegment."Entry No.";

                InteractionLogEntry.CopyFromSegment(SegmentLine);
                SegmentHeader.CalcFields("Modified Word Template");
                if SegmentLine."Attachment No." = 0 then
                    InteractionLogEntry."Modified Word Template" := SegmentHeader."Modified Word Template";
                InteractionLogEntry."Word Template Code" := SegmentLine."Word Template Code";
                InteractionLogEntry.InsertRecord();

                // Unwrap the attachment custom layout if only code is specified in the blob
                UnwrapAttachmentCustomLayout(SegmentLine);

                if Deliver and
                   ((SegmentLine."Correspondence Type".AsInteger() <> 0) or (InteractionTemplate."Correspondence Type (Default)".AsInteger() <> 0))
                then begin
                    InteractionLogEntry."Delivery Status" := InteractionLogEntry."Delivery Status"::"In Progress";
                    if InteractionLogEntry."Word Template Code" = '' then
                        SegmentLine.TestField("Attachment No.");
                    TempDeliverySorter."No." := InteractionLogEntry."Entry No.";
                    if InteractionLogEntry."Modified Word Template" > 0 then
                        TempDeliverySorter."Attachment No." := InteractionLogEntry."Modified Word Template"
                    else
                        TempDeliverySorter."Attachment No." := InteractionLogEntry."Attachment No.";
                    TempDeliverySorter."Correspondence Type" := InteractionLogEntry."Correspondence Type";
                    TempDeliverySorter.Subject := InteractionLogEntry.Subject;
                    TempDeliverySorter."Send Word Docs. as Attmt." := InteractionLogEntry."Send Word Docs. as Attmt.";
                    TempDeliverySorter."Language Code" := SegmentLine."Language Code";
                    TempDeliverySorter."Word Template Code" := InteractionLogEntry."Word Template Code";
                    TempDeliverySorter."Wizard Action" := InteractionTemplate."Wizard Action";
                    TempDeliverySorter."Force Hide Email Dialog" := true;
                    OnBeforeDeliverySorterInsert(TempDeliverySorter, SegmentLine);
                    TempDeliverySorter.Insert();
                end;
                OnBeforeInteractLogEntryInsert(InteractionLogEntry, SegmentLine);
                InteractionLogEntry.Modify();
                OnLogSegmentOnAfterInteractLogEntryInsert(InteractionLogEntry, SegmentLine);
                Attachment.LockTable();
                ShouldModifyAttachment := Attachment.Get(SegmentLine."Attachment No.") and (not Attachment."Read Only");
                OnLogSegmentOnAfterCalcShouldModifyAttachment(Attachment, SegmentLine, SegmentHeader, ShouldModifyAttachment);
                if ShouldModifyAttachment then begin
                    Attachment."Read Only" := true;
                    Attachment.Modify(true);
                end;
            until SegmentLine.Next() = 0
        else
            Error(EmptySegmentErr, SegmentHeader."No.");

        OnLogSegmentOnAfterCreateInteractionLogEntries(SegmentHeader, LoggedSegment);

        SegmentNo := SegmentHeader."No.";
        CampaignNo := SegmentHeader."Campaign No.";
        SegmentHeader.Delete(true);

        if Followup then begin
            Clear(SegmentHeader);
            SegmentHeader."Campaign No." := CampaignNo;
            SegmentHeader.Description := CopyStr(StrSubstNo(FollowUpOnSegmentLbl, SegmentNo), 1, 50);
            OnLogSegmentOnBeforeFollowupSegmentHeaderInsert(SegmentHeader, LoggedSegment);
            SegmentHeader.Insert(true);
            SegmentHeader.ReuseLogged(LoggedSegment."Entry No.");
            OnAfterInsertFollowUpSegment(SegmentHeader, LoggedSegment);
        end;

        if Deliver then
            AttachmentManagement.Send(TempDeliverySorter);

        OnAfterLogSegment(TempDeliverySorter, LoggedSegment, SegmentHeader, SegmentNo, InteractionLogEntry."Entry No.");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Interaction Log Entry", 'r')]
    procedure LogInteraction(SegmentLine: Record "Segment Line"; var AttachmentTemp: Record Attachment; var TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; Deliver: Boolean; Postponed: Boolean) NextInteractLogEntryNo: Integer
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        AttachmentManagement: Codeunit AttachmentManagement;
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        WizardAction: Enum "Interaction Template Wizard Action";
        FileExported: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeLogInteraction(SegmentLine, AttachmentTemp, TempInterLogEntryCommentLine, Deliver, Postponed);

        TestFieldsFromLogInteraction(SegmentLine, Deliver, Postponed);
        if (SegmentLine."Campaign No." <> '') and (not Postponed) then
            SegmentLine."Campaign Entry No." := GetCampaignEntryNo(SegmentLine, 0);

        IsHandled := false;
        OnLogInteractionOnBeforeCheckAttachmentFileValue(SegmentLine, AttachmentTemp, TempInterLogEntryCommentLine, Deliver, Postponed, NextInteractLogEntryNo, IsHandled);
        if IsHandled then
            exit(NextInteractLogEntryNo);

        if AttachmentTemp."Attachment File".HasValue() then begin
            Attachment.LockTable();
            if (SegmentLine."Line No." <> 0) and Attachment.Get(SegmentLine."Attachment No.") then begin
                Attachment.RemoveAttachment(false);
                AttachmentTemp."No." := SegmentLine."Attachment No.";
            end;

            Attachment.Copy(AttachmentTemp);
            Attachment."Read Only" := true;
            OnLogInteractionOnBeforeWizSaveAttachment(SegmentLine, AttachmentTemp, Attachment);
            Attachment.WizSaveAttachment();
            OnBeforeAttachmentInsert(SegmentLine, AttachmentTemp, Attachment);
            Attachment.Insert(true);

            ExportAttachmentFile(SegmentLine, Attachment, AttachmentTemp, FileExported);

            SegmentLine."Attachment No." := Attachment."No.";
            OnAfterHandleAttachmentFile(SegmentLine, Attachment, FileExported);
        end;

        InteractionTemplate.SetRange(Code, SegmentLine."Interaction Template Code");
        if InteractionTemplate.FindFirst() then
            WizardAction := InteractionTemplate."Wizard Action";

        if SegmentLine."Line No." = 0 then begin
            NextInteractLogEntryNo := SequenceNoMgt.GetNextSeqNo(Database::"Interaction Log Entry");

            InteractionLogEntry.Init();
            InteractionLogEntry."Entry No." := NextInteractLogEntryNo;
            InteractionLogEntry.CopyFromSegment(SegmentLine);
            InteractionLogEntry.Postponed := Postponed;
            OnLogInteractionOnBeforeInteractionLogEntryInsert(InteractionLogEntry, Attachment, SegmentLine);
            InteractionLogEntry.InsertRecord();
            NextInteractLogEntryNo := InteractionLogEntry."Entry No.";
        end else begin
            IsHandled := false;
            OnLogInteractionOnBeforeInteractLogEntryGet(NextInteractLogEntryNo, SegmentLine, Postponed, IsHandled);
            if not IsHandled then begin
                InteractionLogEntry.Get(SegmentLine."Line No.");
                OnLogInteractionOnAfterGetInteractLogEntryFromSegmentLine(InteractionLogEntry, SegmentLine, Postponed);
                InteractionLogEntry.CopyFromSegment(SegmentLine);
                InteractionLogEntry.Postponed := Postponed;
                OnLogInteractionOnBeforeInteractionLogEntryModify(InteractionLogEntry);
                InteractionLogEntry.Modify();
                InterLogEntryCommentLine.SetRange("Entry No.", InteractionLogEntry."Entry No.");
                InterLogEntryCommentLine.DeleteAll();
            end;
        end;

        if TempInterLogEntryCommentLine.FindSet() then
            repeat
                InterLogEntryCommentLine.Init();
                InterLogEntryCommentLine := TempInterLogEntryCommentLine;
                InterLogEntryCommentLine."Entry No." := InteractionLogEntry."Entry No.";
                OnLogInteractionOnBeforeInterLogEntryCommentLineInsert(InterLogEntryCommentLine);
                InterLogEntryCommentLine.Insert();
            until TempInterLogEntryCommentLine.Next() = 0;

        OnLogInteractionOnAfterInterLogEntryCommentLineInsert(InterLogEntryCommentLine, SegmentLine, NextInteractLogEntryNo);

        if Deliver and (SegmentLine."Correspondence Type".AsInteger() <> 0) and (not Postponed) then begin
            InteractionLogEntry."Delivery Status" := InteractionLogEntry."Delivery Status"::"In Progress";

            TempDeliverySorter."Word Template Code" := InteractionLogEntry."Word Template Code";
            TempDeliverySorter."No." := InteractionLogEntry."Entry No.";
            TempDeliverySorter."Attachment No." := Attachment."No.";
            TempDeliverySorter."Correspondence Type" := InteractionLogEntry."Correspondence Type";
            TempDeliverySorter.Subject := InteractionLogEntry.Subject;
            TempDeliverySorter."Send Word Docs. as Attmt." := false;
            TempDeliverySorter."Language Code" := SegmentLine."Language Code";
            TempDeliverySorter."Wizard Action" := WizardAction;
            TempDeliverySorter."Force Hide Email Dialog" := true;
            OnLogInteractionOnBeforeTempDeliverySorterInsert(TempDeliverySorter, SegmentLine, InteractionLogEntry);
            TempDeliverySorter.Insert();
            AttachmentManagement.Send(TempDeliverySorter);
        end;
        OnAfterLogInteraction(SegmentLine, InteractionLogEntry, Deliver, Postponed);
    end;

    local procedure TestFieldsFromLogInteraction(var SegmentLine: Record "Segment Line"; Deliver: Boolean; Postponed: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestFieldsFromLogInteraction(SegmentLine, Deliver, Postponed, IsHandled);
        if IsHandled then
            exit;

        if not Postponed then
            CheckSegmentLine(SegmentLine, Deliver);
    end;

    procedure LogDocument(DocumentType: Integer; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer; AccountTableNo: Integer; AccountNo: Code[20]; SalespersonCode: Code[20]; CampaignNo: Code[20]; Description: Text[100]; OpportunityNo: Code[20]) Result: Integer
    var
        InteractionTemplate: Record "Interaction Template";
        TempSegmentLine: Record "Segment Line" temporary;
        ContactBusinessRelation: Record "Contact Business Relation";
        Attachment: Record Attachment;
        Contact: Record Contact;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line" temporary;
        InteractTmplCode: Code[10];
        ContNo: Code[20];
        IsHandled: Boolean;
    begin
        InteractTmplCode := FindInteractionTemplateCode("Interaction Log Entry Document Type".FromInteger(DocumentType));
        OnLogDocumentOnAfterFindInteractTmplCode(InteractTmplCode, Attachment, DocumentType);
        if InteractTmplCode = '' then
            exit;

        InteractionTemplate.Get(InteractTmplCode);

        IsHandled := false;
        OnLogDocumentOnBeforeTestTmplLanguage(InteractTmplCode, IsHandled);
        if not IsHandled then begin
            InteractionTmplLanguage.SetRange("Interaction Template Code", InteractTmplCode);
            if InteractionTmplLanguage.FindFirst() then
                Error(InteractionTemplateAssignedLanguageErr, InteractTmplCode, InteractionTmplLanguage."Language Code");
        end;

        if Description = '' then
            Description := InteractionTemplate.Description;

        case AccountTableNo of
            Database::Customer:
                begin
                    ContNo := FindContactFromContBusRelation(ContactBusinessRelation."Link to Table"::Customer, AccountNo);
                    if ContNo = '' then
                        exit;
                end;
            Database::Vendor:
                begin
                    ContNo := FindContactFromContBusRelation(ContactBusinessRelation."Link to Table"::Vendor, AccountNo);
                    if ContNo = '' then
                        exit;
                end;
            Database::Contact:
                begin
                    if not Contact.Get(AccountNo) then
                        exit;
                    if SalespersonCode = '' then
                        SalespersonCode := Contact."Salesperson Code";
                    ContNo := AccountNo;
                end;
            else begin
                OnLogDocumentOnCaseElse(AccountTableNo, AccountNo, ContNo);
                if ContNo = '' then
                    exit;
            end;
        end;

        IsHandled := false;
        OnLogDocumentOnBeforeTempSegmentLineInit(AccountTableNo, AccountNo, ContNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempSegmentLine.Init();
        TempSegmentLine."Document Type" := "Interaction Log Entry Document Type".FromInteger(DocumentType);
        TempSegmentLine."Document No." := DocumentNo;
        TempSegmentLine."Doc. No. Occurrence" := DocNoOccurrence;
        TempSegmentLine."Version No." := VersionNo;
        TempSegmentLine.Validate("Contact No.", ContNo);
        TempSegmentLine.Date := Today;
        TempSegmentLine."Time of Interaction" := Time;
        TempSegmentLine.Description := Description;
        TempSegmentLine."Salesperson Code" := SalespersonCode;
        TempSegmentLine."Opportunity No." := OpportunityNo;
        OnBeforeTempSegmentLineInsert(TempSegmentLine);
        TempSegmentLine.Insert();
        TempSegmentLine.Validate("Interaction Template Code", InteractTmplCode);
        if CampaignNo <> '' then
            TempSegmentLine."Campaign No." := CampaignNo;
        OnLogDocumentOnBeforeTempSegmentLineModify(TempSegmentLine, AccountTableNo, AccountNo);
        TempSegmentLine.Modify();

        exit(LogInteraction(TempSegmentLine, Attachment, TempInterLogEntryCommentLine, false, false));
    end;

    internal procedure UnwrapAttachmentCustomLayout(var SegmentLine: Record "Segment Line")
    var
        Attachment: Record Attachment;
        TempAttachment: Record Attachment temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
    begin
        // Unwrap the attachment custom layout if only code is specified in the blob
        if SegmentLine."Attachment No." <> 0 then begin
            Attachment.Get(SegmentLine."Attachment No.");

            // Don't do double processing of attachments.
            if Attachment."Read Only" then
                exit;

            Attachment.CalcFields("Attachment File");
            if Attachment.IsHTMLCustomLayout() then begin
                TempAttachment.Copy(Attachment);
                TempAttachment.WizEmbeddAttachment(Attachment);
                TempAttachment.Insert();
                AttachmentManagement.GenerateHTMLContent(TempAttachment, SegmentLine);
                if TempAttachment."Attachment File".HasValue() then begin
                    Attachment.RemoveAttachment(false);
                    TempAttachment."No." := SegmentLine."Attachment No.";
                end;

                Attachment.Copy(TempAttachment);
                Attachment."Read Only" := true;
                Attachment.WizSaveAttachment();
                Attachment.Insert(true);
                SegmentLine."Attachment No." := Attachment."No.";
            end;
        end;
    end;

    procedure FindInteractionTemplateCode(DocumentType: Enum "Interaction Log Entry Document Type") InteractTmplCode: Code[10]
    begin
        if not InteractionTemplateSetup.ReadPermission() then
            exit('');
        if InteractionTemplateSetup.Get() then
            case DocumentType of
                Enum::"Interaction Log Entry Document Type"::"Sales Qte.":
                    InteractTmplCode := InteractionTemplateSetup."Sales Quotes";
                Enum::"Interaction Log Entry Document Type"::"Sales Blnkt. Ord":
                    InteractTmplCode := InteractionTemplateSetup."Sales Blnkt. Ord";
                Enum::"Interaction Log Entry Document Type"::"Sales Ord. Cnfrmn.":
                    InteractTmplCode := InteractionTemplateSetup."Sales Ord. Cnfrmn.";
                Enum::"Interaction Log Entry Document Type"::"Sales Inv.":
                    InteractTmplCode := InteractionTemplateSetup."Sales Invoices";
                Enum::"Interaction Log Entry Document Type"::"Sales Shpt. Note":
                    InteractTmplCode := InteractionTemplateSetup."Sales Shpt. Note";
                Enum::"Interaction Log Entry Document Type"::"Sales Cr. Memo":
                    InteractTmplCode := InteractionTemplateSetup."Sales Cr. Memo";
                Enum::"Interaction Log Entry Document Type"::"Sales Stmnt.":
                    InteractTmplCode := InteractionTemplateSetup."Sales Statement";
                Enum::"Interaction Log Entry Document Type"::"Sales Rmdr.":
                    InteractTmplCode := InteractionTemplateSetup."Sales Rmdr.";
                Enum::"Interaction Log Entry Document Type"::"Serv. Ord. Create":
                    InteractTmplCode := InteractionTemplateSetup."Serv Ord Create";
                Enum::"Interaction Log Entry Document Type"::"Serv. Ord. Post":
                    InteractTmplCode := InteractionTemplateSetup."Serv Ord Post";
                Enum::"Interaction Log Entry Document Type"::"Purch.Qte.":
                    InteractTmplCode := InteractionTemplateSetup."Purch. Quotes";
                Enum::"Interaction Log Entry Document Type"::"Purch. Blnkt. Ord.":
                    InteractTmplCode := InteractionTemplateSetup."Purch Blnkt Ord";
                Enum::"Interaction Log Entry Document Type"::"Purch. Ord.":
                    InteractTmplCode := InteractionTemplateSetup."Purch. Orders";
                Enum::"Interaction Log Entry Document Type"::"Purch. Inv.":
                    InteractTmplCode := InteractionTemplateSetup."Purch Invoices";
                Enum::"Interaction Log Entry Document Type"::"Purch. Rcpt.":
                    InteractTmplCode := InteractionTemplateSetup."Purch. Rcpt.";
                Enum::"Interaction Log Entry Document Type"::"Purch. Cr. Memo":
                    InteractTmplCode := InteractionTemplateSetup."Purch Cr Memos";
                Enum::"Interaction Log Entry Document Type"::"Cover Sheet":
                    InteractTmplCode := InteractionTemplateSetup."Cover Sheets";
                Enum::"Interaction Log Entry Document Type"::"Sales Return Order":
                    InteractTmplCode := InteractionTemplateSetup."Sales Return Order";
                Enum::"Interaction Log Entry Document Type"::"Sales Finance Charge Memo":
                    InteractTmplCode := InteractionTemplateSetup."Sales Finance Charge Memo";
                Enum::"Interaction Log Entry Document Type"::"Sales Return Receipt":
                    InteractTmplCode := InteractionTemplateSetup."Sales Return Receipt";
                Enum::"Interaction Log Entry Document Type"::"Purch. Return Shipment":
                    InteractTmplCode := InteractionTemplateSetup."Purch. Return Shipment";
                Enum::"Interaction Log Entry Document Type"::"Purch. Return Ord. Cnfrmn.":
                    InteractTmplCode := InteractionTemplateSetup."Purch. Return Ord. Cnfrmn.";
                Enum::"Interaction Log Entry Document Type"::"Service Contract":
                    InteractTmplCode := InteractionTemplateSetup."Service Contract";
                Enum::"Interaction Log Entry Document Type"::"Service Contract Quote":
                    InteractTmplCode := InteractionTemplateSetup."Service Contract Quote";
                Enum::"Interaction Log Entry Document Type"::"Service Quote":
                    InteractTmplCode := InteractionTemplateSetup."Service Quote";
                Enum::"Interaction Log Entry Document Type"::"Sales Draft Invoice":
                    InteractTmplCode := InteractionTemplateSetup."Sales Draft Invoices";
            end;

        OnAfterFindInteractTemplateCode(DocumentType, InteractionTemplateSetup, InteractTmplCode);

        exit(InteractTmplCode);
    end;

    procedure CheckSegmentLine(var SegmentLine: Record "Segment Line"; Deliver: Boolean)
    var
        Contact: Record Contact;
        Campaign: Record Campaign;
        InteractionTemplate: Record "Interaction Template";
        ContactAltAddress: Record "Contact Alt. Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSegmentLine(SegmentLine, Deliver, IsHandled);
        if IsHandled then
            exit;

        SegmentLine.TestField(Date);
        SegmentLine.TestField("Contact No.");
        Contact.Get(SegmentLine."Contact No.");
        CheckSalesperson(SegmentLine);
        SegmentLine.TestField("Interaction Template Code");
        InteractionTemplate.Get(SegmentLine."Interaction Template Code");
        if SegmentLine."Campaign No." <> '' then
            Campaign.Get(SegmentLine."Campaign No.");
        case SegmentLine."Correspondence Type" of
            "Correspondence Type"::Email:
                AssignCorrespondenceTypeForEmail(SegmentLine, Contact, ContactAltAddress, Deliver);
            else
                OnTestFieldsOnSegmentLineCorrespondenceTypeCaseElse(SegmentLine, Contact);
        end;
    end;

    local procedure CheckSalesperson(var SegmentLine: Record "Segment Line")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesperson(SegmentLine, IsHandled);
        if IsHandled then
            exit;

        if SegmentLine."Document Type" = SegmentLine."Document Type"::" " then begin
            SegmentLine.TestField("Salesperson Code");
            SalespersonPurchaser.Get(SegmentLine."Salesperson Code");
        end;
    end;

    local procedure AssignCorrespondenceTypeForEmail(var SegmentLine: Record "Segment Line"; var Contact: Record Contact; var ContactAltAddress: Record "Contact Alt. Address"; Deliver: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignCorrespondenceTypeForEmail(SegmentLine, Contact, ContactAltAddress, IsHandled);
        if IsHandled then
            exit;

        if Contact."E-Mail" = '' then
            SegmentLine."Correspondence Type" := "Correspondence Type"::" ";

        if ContactAltAddress.Get(SegmentLine."Contact No.", SegmentLine."Contact Alt. Address Code") then begin
            if ContactAltAddress."E-Mail" <> '' then
                SegmentLine."Correspondence Type" := "Correspondence Type"::Email;
        end else
            if (Deliver and (Contact."E-Mail" = '')) then
                Error(SegmentSendContactEmailFaxMissingErr, Contact.FieldCaption("E-Mail"), Contact."No.")
    end;

    procedure CopyFieldsToCampaignEntry(var CampaignEntry: Record "Campaign Entry"; var SegmentLine: Record "Segment Line")
    var
        SegmentHeader: Record "Segment Header";
    begin
        CampaignEntry.CopyFromSegment(SegmentLine);
        if SegmentLine."Segment No." <> '' then begin
            SegmentHeader.Get(SegmentLine."Segment No.");
            CampaignEntry.Description := SegmentHeader.Description;
        end else begin
            CampaignEntry.Description :=
              CopyStr(FindInteractTmplSetupCaption(SegmentLine."Document Type"), 1, MaxStrLen(CampaignEntry.Description));
            if CampaignEntry.Description = '' then
                CampaignEntry.Description := InteractionsLbl;
        end;
        OnAfterCopyFieldsToCampaignEntry(CampaignEntry, SegmentLine);
    end;

    local procedure FindInteractTmplSetupCaption(DocumentType: Enum "Interaction Log Entry Document Type") InteractTmplSetupCaption: Text[80]
    begin
        InteractionTemplateSetup.Get();
        case DocumentType of
            "Interaction Log Entry Document Type"::"Sales Qte.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Quotes"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Blnkt. Ord":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Blnkt. Ord"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Ord. Cnfrmn.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Ord. Cnfrmn."), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Inv.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Invoices"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Shpt. Note":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Shpt. Note"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Cr. Memo":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Cr. Memo"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Stmnt.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Statement"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Rmdr.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Rmdr."), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Serv. Ord. Create":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Serv Ord Create"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Serv. Ord. Post":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Serv Ord Post"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch.Qte.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch. Quotes"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch. Blnkt. Ord.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch Blnkt Ord"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch. Ord.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch. Orders"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch. Inv.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch Invoices"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch. Rcpt.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch. Rcpt."), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch. Cr. Memo":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch Cr Memos"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Cover Sheet":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Cover Sheets"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Return Order":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Return Order"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Finance Charge Memo":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Finance Charge Memo"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Return Receipt":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Return Receipt"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch. Return Shipment":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch. Return Shipment"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Purch. Return Ord. Cnfrmn.":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Purch. Return Ord. Cnfrmn."), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Service Contract":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Service Contract"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Service Contract Quote":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Service Contract Quote"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Service Quote":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Service Quote"), 1, MaxStrLen(InteractTmplSetupCaption));
            "Interaction Log Entry Document Type"::"Sales Draft Invoice":
                InteractTmplSetupCaption := CopyStr(InteractionTemplateSetup.FieldCaption("Sales Draft Invoices"), 1, MaxStrLen(InteractTmplSetupCaption));
        end;

        OnAfterFindInteractTmplSetupCaption(DocumentType.AsInteger(), InteractionTemplateSetup, InteractTmplSetupCaption);
        exit(InteractTmplSetupCaption);
    end;

    local procedure FindContactFromContBusRelation(LinkToTable: Enum "Contact Business Relation Link To Table"; AccountNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", AccountNo);
        if ContactBusinessRelation.FindFirst() then
            exit(ContactBusinessRelation."Contact No.");
    end;

    procedure CreateCampaignEntryOnSalesInvoicePosting(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Campaign: Record Campaign;
        CampaignTargetGroup: Record "Campaign Target Group";
        ContactBusinessRelation: Record "Contact Business Relation";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        InteractionTemplateCode: Code[10];
        ContNo: Code[20];
    begin
        CampaignTargetGroup.SetRange(Type, CampaignTargetGroup.Type::Customer);
        CampaignTargetGroup.SetRange("No.", SalesInvoiceHeader."Bill-to Customer No.");
        if not CampaignTargetGroup.FindFirst() then
            exit;

        Campaign.Get(CampaignTargetGroup."Campaign No.");
        if (SalesInvoiceHeader."Posting Date" < Campaign."Starting Date") or (SalesInvoiceHeader."Posting Date" > Campaign."Ending Date") then
            exit;

        ContNo := FindContactFromContBusRelation(ContactBusinessRelation."Link to Table"::Customer, SalesInvoiceHeader."Bill-to Customer No.");

        // Check if Interaction Log Entry already exist for initial Sales Order
        InteractionTemplateCode := FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.");
        if InteractionTemplateCode = '' then
            Error(InterTemplateSalesInvoicesNotSpecifiedErr);
        InteractionTemplate.Get(InteractionTemplateCode);
        InteractionLogEntry.SetRange("Contact No.", ContNo);
        InteractionLogEntry.SetRange("Document Type", "Interaction Log Entry Document Type"::"Sales Inv.");
        InteractionLogEntry.SetRange("Document No.", SalesInvoiceHeader."Order No.");
        InteractionLogEntry.SetRange("Interaction Group Code", InteractionTemplate."Interaction Group Code");
        if not InteractionLogEntry.IsEmpty() then
            exit;

        LogDocument(
            "Interaction Log Entry Document Type"::"Sales Inv.".AsInteger(),
            SalesInvoiceHeader."No.", 0, 0, Database::Contact, SalesInvoiceHeader."Bill-to Contact No.", SalesInvoiceHeader."Salesperson Code",
            CampaignTargetGroup."Campaign No.", SalesInvoiceHeader."Posting Description", '');
    end;

    procedure InterLogEntryCommentLineInsert(var TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; InteractionLogEntryNo: Integer)
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
    begin
        DeleteExistingInteractionLogEntryComments(InteractionLogEntryNo);
        if TempInterLogEntryCommentLine.FindSet() then
            repeat
                InterLogEntryCommentLine.Init();
                InterLogEntryCommentLine := TempInterLogEntryCommentLine;
                InterLogEntryCommentLine."Entry No." := InteractionLogEntryNo;
                InterLogEntryCommentLine.Insert();
            until TempInterLogEntryCommentLine.Next() = 0;
    end;

    local procedure DeleteExistingInteractionLogEntryComments(InteractionLogEntryNo: Integer)
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
    begin
        InterLogEntryCommentLine.SetRange("Entry No.", InteractionLogEntryNo);
        if not InterLogEntryCommentLine.IsEmpty() then
            InterLogEntryCommentLine.DeleteAll();
    end;

    local procedure GetNextLoggedSegmentEntryNo(): Integer
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        LoggedSegment: Record "Logged Segment";
    begin
        LoggedSegment.LockTable();
        if LoggedSegment.FindLast() then;
        exit(LoggedSegment."Entry No." + 1);
    end;

    local procedure GetNextCampaignEntryNo(): Integer
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        CampaignEntry: Record "Campaign Entry";
    begin
        CampaignEntry.LockTable();
        if CampaignEntry.FindLast() then;
        exit(CampaignEntry."Entry No." + 1);
    end;

    local procedure GetCampaignEntryNo(SegmentLine: Record "Segment Line"; LoggedSegmentEntryNo: Integer): Integer
    var
        CampaignEntry: Record "Campaign Entry";
    begin
        CampaignEntry.SetCurrentKey("Campaign No.", Date, "Document Type");
        CampaignEntry.SetRange("Document Type", SegmentLine."Document Type");
        CampaignEntry.SetRange("Campaign No.", SegmentLine."Campaign No.");
        CampaignEntry.SetRange("Segment No.", SegmentLine."Segment No.");
        if CampaignEntry.FindFirst() then
            exit(CampaignEntry."Entry No.");

        CampaignEntry.Reset();
        CampaignEntry.Init();
        CampaignEntry."Entry No." := GetNextCampaignEntryNo();
        if LoggedSegmentEntryNo <> 0 then
            CampaignEntry."Register No." := LoggedSegmentEntryNo;
        CopyFieldsToCampaignEntry(CampaignEntry, SegmentLine);
        CampaignEntry.Insert();
        exit(CampaignEntry."Entry No.");
    end;

    local procedure ExportAttachmentFile(SegmentLine: Record "Segment Line"; var Attachment: Record Attachment; var AttachmentTemp: Record Attachment; var FileExported: Boolean)
    var
        MarketingSetup: Record "Marketing Setup";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportAttachmentFile(SegmentLine, Attachment, AttachmentTemp, FileExported, IsHandled);
        if IsHandled then
            exit;

        MarketingSetup.SetLoadFields("Attachment Storage Type");
        MarketingSetup.Get();
        if MarketingSetup."Attachment Storage Type" = MarketingSetup."Attachment Storage Type"::"Disk File" then
            if Attachment."No." <> 0 then begin
                FileName := Attachment.ConstDiskFileName();
                if FileName <> '' then begin
                    FileManagement.DeleteServerFile(FileName);
                    FileExported := AttachmentTemp.ExportAttachmentToServerFile(FileName);
                end;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindInteractTemplateCode(DocumentType: Enum "Interaction Log Entry Document Type"; InteractionTemplateSetup: Record "Interaction Template Setup"; var InteractionTemplateCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindInteractTmplSetupCaption(DocumentType: Integer; InteractionTemplateSetup: Record "Interaction Template Setup"; var InteractionTemplateCaption: Text[80])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertFollowUpSegment(var SegmentHeader: Record "Segment Header"; LoggedSegment: Record "Logged Segment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleAttachmentFile(var SegmentLine: Record "Segment Line"; Attachment: Record Attachment; FileExported: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogInteraction(var SegmentLine: Record "Segment Line"; var InteractionLogEntry: Record "Interaction Log Entry"; Deliver: Boolean; Postponed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogSegment(var TempDeliverySorter: Record "Delivery Sorter" temporary; var LoggedSegment: Record "Logged Segment"; SegmentHeader: Record "Segment Header"; SegmentNo: Code[20]; LastInteractLogEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttachmentInsert(SegmentLine: Record "Segment Line"; var AttachmentTemp: Record Attachment; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignCorrespondenceTypeForEmail(var SegmentLine: Record "Segment Line"; Contact: Record Contact; ContactAltAddr: Record "Contact Alt. Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCampaignEntryNoModify(var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesperson(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeliverySorterInsert(var TempDeliverySorter: Record "Delivery Sorter" temporary; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInteractLogEntryInsert(var InteractionLogEntry: Record "Interaction Log Entry"; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogInteraction(var SegmentLine: Record "Segment Line"; var Attachment: Record Attachment; var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; var Deliver: Boolean; var Postponed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogSegment(SegmentHeader: Record "Segment Header"; Deliver: Boolean; Followup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLoggedSegmentInsert(var LoggedSegment: Record "Logged Segment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempSegmentLineInsert(var TempSegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFieldsFromLogInteraction(var SegmentLine: Record "Segment Line"; Deliver: Boolean; Postponed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogDocumentOnAfterFindInteractTmplCode(var InteractTmplCode: Code[10]; var Attachment: Record Attachment; DocumentType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogDocumentOnCaseElse(AccountTableNo: Integer; AccountNo: Code[20]; var ContNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogDocumentOnBeforeTempSegmentLineModify(var TempSegmentLine: Record "Segment Line" temporary; AccountTableNo: Integer; AccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnBeforeInteractionLogEntryInsert(var InteractionLogEntry: Record "Interaction Log Entry"; Attachment: Record Attachment; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnBeforeInteractionLogEntryModify(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnAfterGetInteractLogEntryFromSegmentLine(var InteractionLogEntry: Record "Interaction Log Entry"; SegmentLine: Record "Segment Line"; Postponed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnBeforeInterLogEntryCommentLineInsert(var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnBeforeTempDeliverySorterInsert(var DeliverySorter: Record "Delivery Sorter"; SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSegmentOnAfterCreateInteractionLogEntries(var SegmentHeader: Record "Segment Header"; var LoggedSegment: Record "Logged Segment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSegmentOnAfterCalcShowIsNotEmptyError(var LoggedSegment: Record "Logged Segment"; Deliver: Boolean; var ShowIsNotEmptyError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSegmentOnAfterCalcShouldModifyAttachment(var Attachment: Record Attachment; SegmentLine: Record "Segment Line"; SegmentHeader: Record "Segment Header"; var ShouldModifyAttachment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFieldsOnSegmentLineCorrespondenceTypeCaseElse(var SegmentLine: Record "Segment Line"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSegmentOnAfterLoggedSegmentInsert(var LoggedSegment: Record "Logged Segment"; SegmentHeader: Record "Segment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSegmentOnAfterInteractLogEntryInsert(var InteractionLogEntry: Record "Interaction Log Entry"; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSegmentOnBeforeFollowupSegmentHeaderInsert(var SegmentHeader: Record "Segment Header"; LoggedSegment: Record "Logged Segment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogDocumentOnBeforeTempSegmentLineInit(AccountTableNo: Integer; AccountNo: Code[20]; var ContNo: Code[20]; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnBeforeCheckAttachmentFileValue(SegmentLine: Record "Segment Line"; var AttachmentTemp: Record Attachment; var TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; Deliver: Boolean; Postponed: Boolean; var NextInteractLogEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSegmentOnBeforeInitLoggedSegment(SegmentHeader: Record "Segment Header"; Deliver: Boolean; Followup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSegmentLine(var SegmentLine: Record "Segment Line"; Deliver: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogDocumentOnBeforeTestTmplLanguage(InteractTmplCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsToCampaignEntry(var CampaignEntry: Record "Campaign Entry"; var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnAfterInterLogEntryCommentLineInsert(var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; SegmentLine: Record "Segment Line"; NextInteractLogEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnBeforeInteractLogEntryGet(var NextInteractLogEntryNo: Integer; SegmentLine: Record "Segment Line"; Postponed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInteractionOnBeforeWizSaveAttachment(SegmentLine: Record "Segment Line"; var AttachmentTemp: Record Attachment; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportAttachmentFile(var SegmentLine: Record "Segment Line"; Attachment: Record Attachment; var AttachmentTemp: Record Attachment; var FileExported: Boolean; var IsHandled: Boolean)
    begin
    end;
}

