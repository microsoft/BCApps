// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Sales.Customer;
using System.Globalization;
using System.Integration;
using System.Integration.Word;
using System.IO;
using System.Security.AccessControl;
using System.Security.User;
using System.Telemetry;
using System.Utilities;

table 5077 "Segment Line"
{
    Caption = 'Segment Line';
    DataClassification = CustomerContent;
    Permissions = tabledata Attachment = rd,
                  tabledata "Segment Line" = rim,
                  tabledata "Segment History" = rd,
                  tabledata "Segment Criteria Line" = rd,
                  tabledata "Segment Interaction Language" = rid,
                  tabledata Contact = r,
                  tabledata Customer = r;

    fields
    {
        field(1; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
                Attachment: Record Attachment;
                InteractTmpl: Record "Interaction Template";
            begin
                InitLine();

                if ContactGlobal.Get(Rec."Contact No.") then begin
                    Rec."Language Code" := FindLanguage(Rec."Interaction Template Code", ContactGlobal."Language Code");
                    Rec."Contact Company No." := ContactGlobal."Company No.";
                    Rec."Contact Alt. Address Code" := ContactGlobal.ActiveAltAddress(Rec.Date);
                    if SegmentHeaderGlobal.Get(Rec."Segment No.") then begin
                        if SegmentHeaderGlobal."Salesperson Code" = '' then
                            Rec."Salesperson Code" := ContactGlobal."Salesperson Code"
                        else
                            Rec."Salesperson Code" := SegmentHeaderGlobal."Salesperson Code";
                        if SegmentHeaderGlobal."Ignore Contact Corres. Type" and
                           (SegmentHeaderGlobal."Correspondence Type (Default)" <> SegmentHeaderGlobal."Correspondence Type (Default)"::" ")
                        then
                            Rec."Correspondence Type" := SegmentHeaderGlobal."Correspondence Type (Default)"
                        else
                            if InteractTmpl.Get(SegmentHeaderGlobal."Interaction Template Code") and
                               (InteractTmpl."Ignore Contact Corres. Type" or
                                ((InteractTmpl."Ignore Contact Corres. Type" = false) and
                                 (ContactGlobal."Correspondence Type" = ContactGlobal."Correspondence Type"::" ")))
                            then
                                Rec."Correspondence Type" := InteractTmpl."Correspondence Type (Default)"
                            else
                                Rec."Correspondence Type" := ContactGlobal."Correspondence Type";
                    end else begin
                        SetDefaultSalesperson();
                        if Rec."Salesperson Code" = '' then
                            if not SalespersonPurchaserGlobal.Get(GetFilter("Salesperson Code")) then
                                Rec."Salesperson Code" := ContactGlobal."Salesperson Code";
                    end;

                end else begin
                    Rec."Contact Company No." := '';
                    Rec."Contact Alt. Address Code" := '';
                    if SegmentHeaderGlobal.Get(Rec."Segment No.") then
                        Rec."Salesperson Code" := SegmentHeaderGlobal."Salesperson Code"
                    else begin
                        Rec."Salesperson Code" := '';
                        Rec."Language Code" := '';
                    end;
                end;
                Rec.CalcFields("Contact Name", "Contact Company Name");

                if Rec."Segment No." <> '' then begin
                    if UniqueAttachmentExists() then begin
                        Modify();
                        SegInteractLanguage.Reset();
                        SegInteractLanguage.SetRange("Segment No.", Rec."Segment No.");
                        SegInteractLanguage.SetRange("Segment Line No.", Rec."Line No.");
                        SegInteractLanguage.DeleteAll(true);
                        Rec.Get(Rec."Segment No.", Rec."Line No.");
                    end;

                    Rec."Language Code" := FindLanguage(Rec."Interaction Template Code", Rec."Language Code");
                    if SegInteractLanguage.Get(Rec."Segment No.", 0, Rec."Language Code") then begin
                        if Attachment.Get(SegInteractLanguage."Attachment No.") then
                            Rec."Attachment No." := SegInteractLanguage."Attachment No.";
                        Rec.Subject := SegInteractLanguage.Subject;
                        Rec."Word Template Code" := SegInteractLanguage."Word Template Code";
                    end;
                end;

                if xRec."Contact No." <> Rec."Contact No." then
                    SetCampaignTargetGroup();
            end;
        }
        field(4; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                if xRec."Campaign No." <> "Campaign No." then
                    SetCampaignTargetGroup();
            end;
        }
        field(5; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(6; "Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type';
        }
        field(7; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            TableRelation = "Interaction Template";

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
                InteractTemplLanguage: Record "Interaction Tmpl. Language";
                InteractTmpl: Record "Interaction Template";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateInteractionTemplateCode(Rec, ContactGlobal, IsHandled);
                if IsHandled then
                    exit;

                IsHandled := false;
                OnValidateInteractionTemplateCodeOnBeforeGettingContact(Rec, xRec, ContactGlobal, IsHandled);
                if not IsHandled then begin
                    Rec.TestField("Contact No.");
                    ContactGlobal.Get(Rec."Contact No.");
                end;
                Rec."Attachment No." := 0;
                Rec."Language Code" := '';
                Rec.Subject := '';
                Rec."Interaction Group Code" := '';
                Rec."Cost (LCY)" := 0;
                Rec."Duration (Min.)" := 0;
                Rec."Information Flow" := "Information Flow"::" ";
                Rec."Initiated By" := "Initiated By"::" ";
                Rec."Campaign Target" := false;
                Rec."Campaign Response" := false;
                Rec."Correspondence Type" := "Correspondence Type"::" ";
                if (Rec.GetFilter("Campaign No.") = '') and (InteractTmpl."Campaign No." <> '') then
                    Rec."Campaign No." := '';
                Modify();

                if (Rec."Segment No." <> '') and (Rec.Description <> '') then begin
                    SegInteractLanguage.Reset();
                    SegInteractLanguage.SetRange("Segment No.", Rec."Segment No.");
                    SegInteractLanguage.SetRange("Segment Line No.", Rec."Line No.");
                    SegInteractLanguage.DeleteAll(true);
                    Rec.Get(Rec."Segment No.", Rec."Line No.");
                    if Rec."Interaction Template Code" <> '' then begin
                        SegmentHeaderGlobal.Get(Rec."Segment No.");
                        if Rec."Interaction Template Code" <> SegmentHeaderGlobal."Interaction Template Code" then begin
                            SegmentHeaderGlobal.CreateSegInteractions(Rec."Interaction Template Code", Rec."Segment No.", Rec."Line No.");
                            Rec."Language Code" := FindLanguage(Rec."Interaction Template Code", ContactGlobal."Language Code");
                            IsHandled := false;
                            OnValidateInteractionTemplateCodeOnBeforeGetSegInteractTemplLanguage(Rec, IsHandled);
                            if not IsHandled then
                                if SegInteractLanguage.Get(Rec."Segment No.", Rec."Line No.", Rec."Language Code") then begin
                                    Rec."Attachment No." := SegInteractLanguage."Attachment No.";
                                    Rec."Word Template Code" := SegInteractLanguage."Word Template Code";
                                end;
                        end else begin
                            Rec."Language Code" := FindLanguage(Rec."Interaction Template Code", ContactGlobal."Language Code");
                            if SegInteractLanguage.Get(Rec."Segment No.", 0, Rec."Language Code") then begin
                                Rec."Attachment No." := SegInteractLanguage."Attachment No.";
                                Rec."Word Template Code" := SegInteractLanguage."Word Template Code";
                            end;
                        end;
                    end;
                end else begin
                    Rec."Language Code" := FindLanguage(Rec."Interaction Template Code", ContactGlobal."Language Code");

                    IsHandled := false;
                    OnInteractionTemplValidateOnBeforeGetInteractTemplLanguage(Rec, IsHandled);
                    if not IsHandled then
                        if InteractTemplLanguage.Get(Rec."Interaction Template Code", Rec."Language Code") then begin
                            Rec."Attachment No." := InteractTemplLanguage."Attachment No.";
                            Rec."Word Template Code" := InteractTemplLanguage."Word Template Code";
                        end else
                            if InteractTmpl.Get(Rec."Interaction Template Code") then
                                Rec."Word Template Code" := InteractTmpl."Word Template Code";
                end;

                if InteractTmpl.Get(Rec."Interaction Template Code") then begin
                    Rec."Interaction Group Code" := InteractTmpl."Interaction Group Code";
                    if (Rec.Description = '') or
                       ((xRec."Interaction Template Code" <> '') and (xRec."Interaction Template Code" <> Rec."Interaction Template Code"))
                    then
                        Rec.Description := InteractTmpl.Description;
                    Rec."Cost (LCY)" := InteractTmpl."Unit Cost (LCY)";
                    Rec."Duration (Min.)" := InteractTmpl."Unit Duration (Min.)";
                    Rec."Information Flow" := InteractTmpl."Information Flow";
                    Rec."Initiated By" := InteractTmpl."Initiated By";
                    Rec."Campaign Target" := InteractTmpl."Campaign Target";
                    Rec."Campaign Response" := InteractTmpl."Campaign Response";

                    SetCorrespondenceType(InteractTmpl);
                    if SegmentHeaderGlobal."Campaign No." <> '' then
                        Rec."Campaign No." := SegmentHeaderGlobal."Campaign No."
                    else
                        if (Rec.GetFilter("Campaign No.") = '') and (InteractTmpl."Campaign No." <> '') then
                            Rec."Campaign No." := InteractTmpl."Campaign No.";
                end;
                if GlobalCampaign.Get(Rec."Campaign No.") then
                    Rec."Campaign Description" := GlobalCampaign.Description;

                Modify();
            end;
        }
        field(8; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Cost (LCY)';
            MinValue = 0;
        }
        field(9; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            MinValue = 0;
        }
        field(10; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
            TableRelation = Attachment;
        }
        field(11; "Campaign Response"; Boolean)
        {
            Caption = 'Campaign Response';
        }
        field(12; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No."),
                                                     Type = const(Person)));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Information Flow"; Option)
        {
            BlankZero = true;
            Caption = 'Information Flow';
            OptionCaption = ' ,Outbound,Inbound';
            OptionMembers = " ",Outbound,Inbound;
        }
        field(14; "Initiated By"; Option)
        {
            BlankZero = true;
            Caption = 'Initiated By';
            OptionCaption = ' ,Us,Them';
            OptionMembers = " ",Us,Them;
        }
        field(15; "Contact Alt. Address Code"; Code[10])
        {
            Caption = 'Contact Alt. Address Code';
            TableRelation = "Contact Alt. Address".Code where("Contact No." = field("Contact No."));
        }
        field(16; Evaluation; Enum "Interaction Evaluation")
        {
            Caption = 'Evaluation';
        }
        field(17; "Campaign Target"; Boolean)
        {
            Caption = 'Campaign Target';

            trigger OnValidate()
            begin
                if xRec."Campaign Target" <> "Campaign Target" then
                    SetCampaignTargetGroup();
            end;
        }
        field(18; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact Company No."),
                                                     Type = const(Company)));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnLookup()
            begin
                LanguageCodeOnLookup();
            end;

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
                InteractTemplLanguage: Record "Interaction Tmpl. Language";
                IsHandled: Boolean;
            begin
                Rec.TestField("Interaction Template Code");

                if Rec."Language Code" = xRec."Language Code" then
                    exit;

                IsHandled := false;
                OnValidateLanguageCodeOnBeforeGetSegmentHeaderGlobal(Rec, IsHandled);
                if IsHandled then
                    exit;

                if SegmentHeaderGlobal.Get(Rec."Segment No.") then begin
                    if not UniqueAttachmentExists() then begin
                        if SegInteractLanguage.Get(Rec."Segment No.", 0, Rec."Language Code") then begin
                            Rec."Attachment No." := SegInteractLanguage."Attachment No.";
                            Rec."Word Template Code" := SegInteractLanguage."Word Template Code";
                            Rec.Subject := SegInteractLanguage.Subject;
                        end else begin
                            Rec."Attachment No." := 0;
                            Rec.Subject := '';
                        end;
                    end else
                        if SegInteractLanguage.Get(Rec."Segment No.", Rec."Line No.", Rec."Language Code") then begin
                            Rec."Attachment No." := SegInteractLanguage."Attachment No.";
                            Rec."Word Template Code" := SegInteractLanguage."Word Template Code";
                            Rec.Subject := SegInteractLanguage.Subject;
                        end else begin
                            Rec."Attachment No." := 0;
                            Rec.Subject := '';
                        end;
                    Modify();
                end else begin
                    InteractTemplLanguage.Get(Rec."Interaction Template Code", Rec."Language Code");
                    SetInteractionAttachment();
                end;
            end;
        }
        field(22; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(23; Date; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                if ContactGlobal.Get("Contact No.") then
                    if "Contact Alt. Address Code" = ContactGlobal.ActiveAltAddress(xRec.Date) then
                        "Contact Alt. Address Code" := ContactGlobal.ActiveAltAddress(Date);
            end;
        }
        field(24; "Time of Interaction"; Time)
        {
            Caption = 'Time of Interaction';
        }
        field(25; "Attempt Failed"; Boolean)
        {
            Caption = 'Attempt Failed';
        }
        field(26; "To-do No."; Code[20])
        {
            Caption = 'Task No.';
            TableRelation = "To-do";
        }
        field(27; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            TableRelation = Contact where(Type = const(Company));
        }
        field(28; "Campaign Entry No."; Integer)
        {
            Caption = 'Campaign Entry No.';
            Editable = false;
            TableRelation = "Campaign Entry";
        }
        field(29; "Interaction Group Code"; Code[10])
        {
            Caption = 'Interaction Group Code';
            TableRelation = "Interaction Group";
        }
        field(31; "Document Type"; Enum "Interaction Log Entry Document Type")
        {
            Caption = 'Document Type';
        }
        field(32; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(33; "Send Word Doc. As Attmt."; Boolean)
        {
            Caption = 'Send Word Doc. As Attmt.';
        }
        field(34; "Contact Via"; Text[80])
        {
            Caption = 'Contact Via';
        }
        field(35; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(36; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(37; Subject; Text[100])
        {
            Caption = 'Subject';
        }
        field(44; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        field(50; "Contact Phone No."; Text[30])
        {
            CalcFormula = lookup(Contact."Phone No." where("No." = field("Contact No.")));
            Caption = 'Contact Phone No.';
            Editable = false;
            FieldClass = FlowField;
            ExtendedDatatype = PhoneNo;

        }
        field(51; "Contact Mobile Phone No."; Text[30])
        {
            CalcFormula = lookup(Contact."Mobile Phone No." where("No." = field("Contact No.")));
            Caption = 'Contact Mobile Phone No.';
            Editable = false;
            FieldClass = FlowField;
            ExtendedDatatype = PhoneNo;

        }
        field(52; "Contact Email"; Text[80])
        {
            CalcFormula = lookup(Contact."E-Mail" where("No." = field("Contact No.")));
            Caption = 'Contact Email';
            Editable = false;
            FieldClass = FlowField;
            ExtendedDatatype = EMail;

        }
        field(53; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
            TableRelation = "Word Template".Code where("Table ID" = const(5106)); // Only Interaction Merge Data Word templates are allowed
        }
        field(54; Merged; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(9501; "Wizard Step"; Enum "Segment Line Wizard Step")
        {
            Caption = 'Wizard Step';
            Editable = false;
        }
        field(9502; "Wizard Contact Name"; Text[100])
        {
            Caption = 'Wizard Contact Name';
        }
        field(9503; "Opportunity Description"; Text[100])
        {
            Caption = 'Opportunity Description';
        }
        field(9504; "Campaign Description"; Text[100])
        {
            Caption = 'Campaign Description';
        }
        field(9505; "Interaction Successful"; Boolean)
        {
            Caption = 'Interaction Successful';
        }
        field(9506; "Dial Contact"; Boolean)
        {
            Caption = 'Dial Contact';
        }
        field(9507; "Mail Contact"; Boolean)
        {
            Caption = 'Mail Contact';
        }
    }

    keys
    {
        key(Key1; "Segment No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Segment No.", "Campaign No.", Date)
        {
        }
        key(Key3; "Contact No.", "Segment No.")
        {
        }
        key(Key4; "Campaign No.")
        {
        }
        key(Key5; "Campaign No.", "Contact Company No.", "Campaign Target")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SegmentLine: Record "Segment Line";
        SegmentCriteriaLine: Record "Segment Criteria Line";
        SegmentHistory: Record "Segment History";
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        TodoTask: Record "To-do";
    begin
        CampaignTargetGroupMgt.DeleteSegfromTargetGr(Rec);

        SegmentInteractionLanguage.Reset();
        SegmentInteractionLanguage.SetRange("Segment No.", "Segment No.");
        SegmentInteractionLanguage.SetRange("Segment Line No.", "Line No.");
        SegmentInteractionLanguage.DeleteAll(true);
        Get("Segment No.", "Line No.");

        SegmentLine.SetRange("Segment No.", "Segment No.");
        SegmentLine.SetFilter("Line No.", '<>%1', "Line No.");
        if SegmentLine.IsEmpty() then begin
            if SegmentHeaderGlobal.Get("Segment No.") then
                SegmentHeaderGlobal.CalcFields("No. of Criteria Actions");
            if SegmentHeaderGlobal."No. of Criteria Actions" > 1 then
                if Confirm(SegmentEmptyResetCriteriaActionsQst, true) then begin
                    SegmentCriteriaLine.SetRange("Segment No.", "Segment No.");
                    OnDeleteOnBeforeSegmentCriteriaLineDeleteAll(Rec, SegmentCriteriaLine);
                    SegmentCriteriaLine.DeleteAll();
                    SegmentHistory.SetRange("Segment No.", "Segment No.");
                    SegmentHistory.DeleteAll();
                end;
        end;
        if "Contact No." <> '' then begin
            SegmentLine.SetRange("Contact No.", "Contact No.");
            if SegmentLine.IsEmpty() then begin
                TodoTask.SetRange("Segment No.", "Segment No.");
                TodoTask.SetRange("Contact No.", "Contact No.");
                TodoTask.ModifyAll("Segment No.", '');
            end;
        end;
    end;

    var
        SegmentHeaderGlobal: Record "Segment Header";
        ContactGlobal: Record Contact;
        SalespersonPurchaserGlobal: Record "Salesperson/Purchaser";
        GlobalCampaign: Record Campaign;
        GlobalInteractionTemplate: Record "Interaction Template";
        GlobalAttachment: Record Attachment;
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        AttachmentManagement: Codeunit AttachmentManagement;
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        ResumedAttachmentNo: Integer;
        InteractionLogEntryNo: Integer;

        InheritedTxt: Label 'Inherited';
        UniqueTxt: Label 'Unique';
        NoAttachmentErr: Label 'No attachment found. You must either add an attachment or choose a template in the Word Template Code field on the Interaction Template page.';
        FieldNotFilledErr: Label 'You must fill in the %1 field.', Comment = '%1 - field name';
        AttachmentImportCancelledMsg: Label 'The program has stopped importing the attachment at your request.';
        SegmentEmptyResetCriteriaActionsQst: Label 'Your Segment is now empty.\Do you want to reset number of criteria actions?';
        FinishInteractionLaterQst: Label 'Do you want to finish this interaction later?';
        AttachmentRequiredErr: Label 'The correspondence type for this interaction is Email, which requires an interaction template with an attachment or Word template. To continue, you can either change the correspondence type for the contact, select an interaction template that has a different correspondence type, or select a template that ignores the contact correspondence type.';
        SelectContactErr: Label 'You must select a contact to interact with.';
        PhoneNumberErr: Label 'You must fill in the phone number.';
        WordTemplateUsedErr: Label 'You cannot change the attachment when a Word template has been specified.';
        OneDriveNotEnabledMsg: Label 'Onedrive is not enabled. Please enable it in the OneDrive Setup page.';
        ModifyExistingAttachmentMsg: Label 'Modify existing attachment?';

    protected var
        TempAttachment: Record Attachment temporary;
        TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line" temporary;

    procedure InitLine()
    begin
        if not SegmentHeaderGlobal.Get(Rec."Segment No.") then
            exit;

        Rec.Description := SegmentHeaderGlobal.Description;
        Rec."Campaign No." := SegmentHeaderGlobal."Campaign No.";
        Rec."Salesperson Code" := SegmentHeaderGlobal."Salesperson Code";
        Rec."Correspondence Type" := SegmentHeaderGlobal."Correspondence Type (Default)";
        Rec."Interaction Template Code" := SegmentHeaderGlobal."Interaction Template Code";
        Rec."Interaction Group Code" := SegmentHeaderGlobal."Interaction Group Code";
        Rec."Cost (LCY)" := SegmentHeaderGlobal."Unit Cost (LCY)";
        Rec."Duration (Min.)" := SegmentHeaderGlobal."Unit Duration (Min.)";
        SegmentHeaderGlobal.CalcFields("Attachment No.");
        Rec."Attachment No." := SegmentHeaderGlobal."Attachment No.";
        Rec.Date := SegmentHeaderGlobal.Date;
        Rec."Campaign Target" := SegmentHeaderGlobal."Campaign Target";
        Rec."Information Flow" := SegmentHeaderGlobal."Information Flow";
        Rec."Initiated By" := SegmentHeaderGlobal."Initiated By";
        Rec."Campaign Response" := SegmentHeaderGlobal."Campaign Response";
        Rec."Send Word Doc. As Attmt." := SegmentHeaderGlobal."Send Word Docs. as Attmt.";
        Rec."Word Template Code" := SegmentHeaderGlobal."Word Template Code";
        Rec.Merged := false;

        Clear(Evaluation);
        OnAfterInitLine(Rec, SegmentHeaderGlobal);
    end;

    procedure AttachmentText(): Text[30]
    begin
        if AttachmentInherited() then
            exit(InheritedTxt);

        if "Attachment No." <> 0 then
            exit(UniqueTxt);

        exit('');
    end;

    procedure MaintainSegLineAttachment()
    var
        Attachment: Record Attachment;
        Contact: Record Contact;
        SalutationFormula: Record "Salutation Formula";
        DocumentSharing: Codeunit "Document Sharing";
        Telemetry: Codeunit Telemetry;
        InStream: InStream;
    begin
        Rec.TestField("Interaction Template Code");

        if Rec."Word Template Code" <> '' then begin
            GlobalInteractionTemplate.Get("Interaction Template Code");
            if not DocumentSharing.ShareEnabled(Enum::"Document Sharing Source"::System) then begin
                Message(OneDriveNotEnabledMsg);
                Telemetry.LogMessage('0000K5K', 'OneDrive not enabled', Verbosity::Normal, DataClassification::SystemMetadata);
                exit;
            end;
            if Merged then
                LoadTempAttachment(true);
            MergeTemplate(true, Merged);

            Subject := Description;

            TempAttachment."Attachment File".CreateInStream(InStream);
            Rec."Attachment No." := Attachment.ImportAttachmentFromStream(InStream, 'docx');
            Merged := true;
            Modify();
        end else begin
            if Rec."Word Template Code" <> '' then
                Error(WordTemplateUsedErr);

            Contact.Get(Rec."Contact No.");
            if SalutationFormula.Get(Contact."Salutation Code", "Language Code", 0) then;
            if SalutationFormula.Get(Contact."Salutation Code", "Language Code", 1) then;

            if Rec."Attachment No." <> 0 then
                OpenSegLineAttachment()
            else
                CreateSegLineAttachment();
        end;
    end;

    procedure CreateSegLineAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if not SegmentInteractionLanguage.Get(Rec."Segment No.", Rec."Line No.", Rec."Language Code") then begin
            SegmentInteractionLanguage.Init();
            SegmentInteractionLanguage."Segment No." := Rec."Segment No.";
            SegmentInteractionLanguage."Segment Line No." := Rec."Line No.";
            SegmentInteractionLanguage."Language Code" := Rec."Language Code";
            SegmentInteractionLanguage.Description := Rec.Description;
            SegmentInteractionLanguage.Subject := Rec.Subject;
            SegmentInteractionLanguage."Word Template Code" := Rec."Word Template Code";
        end;

        SegmentInteractionLanguage.CreateAttachment();
    end;

    procedure OpenSegLineAttachment()
    var
        Attachment: Record Attachment;
        Attachment2: Record Attachment;
        SegInteractLanguage: Record "Segment Interaction Language";
        NewAttachmentNo: Integer;
    begin
        if Rec."Attachment No." = 0 then
            exit;

        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        Attachment.Get(Rec."Attachment No.");
        Attachment2 := Attachment;

        Attachment2.ShowAttachment(Rec, Rec."Segment No." + ' ' + Rec.Description);

        if AttachmentInherited() then begin
            NewAttachmentNo := Attachment2."No.";
            if (Attachment."Last Date Modified" <> Attachment2."Last Date Modified") or
               (Attachment."Last Time Modified" <> Attachment2."Last Time Modified")
            then begin
                SegInteractLanguage.Init();
                SegInteractLanguage."Segment No." := Rec."Segment No.";
                SegInteractLanguage."Segment Line No." := Rec."Line No.";
                SegInteractLanguage."Language Code" := Rec."Language Code";
                SegInteractLanguage.Description := Rec.Description;
                SegInteractLanguage.Subject := Rec.Subject;
                SegInteractLanguage."Attachment No." := NewAttachmentNo;
                SegInteractLanguage."Word Template Code" := Rec."Word Template Code";
                SegInteractLanguage.Insert(true);
                Rec.Get(Rec."Segment No.", Rec."Line No.");
                Rec."Attachment No." := NewAttachmentNo;
                Modify();
            end;
        end
    end;

    procedure ImportSegLineAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if not SegmentInteractionLanguage.Get("Segment No.", "Line No.", "Language Code") then begin
            SegmentInteractionLanguage.Init();
            SegmentInteractionLanguage."Segment No." := Rec."Segment No.";
            SegmentInteractionLanguage."Segment Line No." := Rec."Line No.";
            SegmentInteractionLanguage."Language Code" := Rec."Language Code";
            SegmentInteractionLanguage.Description := Rec.Description;
            SegmentInteractionLanguage."Word Template Code" := Rec."Word Template Code";
            SegmentInteractionLanguage.Insert(true);
        end;
        SegmentInteractionLanguage.ImportAttachment();
    end;

    procedure ExportSegLineAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if UniqueAttachmentExists() then begin
            if SegmentInteractionLanguage.Get("Segment No.", "Line No.", "Language Code") then
                if SegmentInteractionLanguage."Attachment No." <> 0 then
                    SegmentInteractionLanguage.ExportAttachment();
        end else
            if SegmentInteractionLanguage.Get("Segment No.", 0, "Language Code") then
                if SegmentInteractionLanguage."Attachment No." <> 0 then
                    SegmentInteractionLanguage.ExportAttachment();
    end;

    procedure RemoveAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if SegmentInteractionLanguage.Get("Segment No.", "Line No.", "Language Code") then begin
            SegmentInteractionLanguage.Delete(true);
            Get("Segment No.", "Line No.");
        end;
        "Attachment No." := 0;
    end;

    procedure CreatePhoneCall()
    var
        TempSegmentLine: Record "Segment Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePhoneCall(Rec, IsHandled);
        if IsHandled then
            exit;

        ContactGlobal.Get("Contact No.");
        TempSegmentLine."Segment No." := "Segment No.";
        TempSegmentLine."Contact No." := ContactGlobal."No.";
        TempSegmentLine."Contact Via" := ContactGlobal."Phone No.";
        TempSegmentLine."Contact Company No." := ContactGlobal."Company No.";
        TempSegmentLine."To-do No." := "To-do No.";
        TempSegmentLine."Salesperson Code" := "Salesperson Code";
        if "Contact Alt. Address Code" <> '' then
            TempSegmentLine."Contact Alt. Address Code" := "Contact Alt. Address Code";
        if "Campaign No." <> '' then
            TempSegmentLine."Campaign No." := "Campaign No.";

        TempSegmentLine."Campaign Target" := "Campaign Target";
        TempSegmentLine."Campaign Response" := "Campaign Response";
        TempSegmentLine.SetRange("Contact No.", TempSegmentLine."Contact No.");
        TempSegmentLine.SetRange("Campaign No.", TempSegmentLine."Campaign No.");

        OnCreatePhoneCallOnBeforeStartWizard2(TempSegmentLine, Rec);
        TempSegmentLine.StartWizard2();
    end;

    local procedure FindLanguage(InteractTmplCode: Code[10]; ContactLanguageCode: Code[10]) Language: Code[10]
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplateLocal: Record "Interaction Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLanguage(Rec, InteractTmplCode, ContactLanguageCode, Language, IsHandled);
        if IsHandled then
            exit;

        if SegmentHeaderGlobal.Get("Segment No.") then begin
            if not UniqueAttachmentExists() and
               ("Interaction Template Code" = SegmentHeaderGlobal."Interaction Template Code")
            then begin
                if SegmentInteractionLanguage.Get("Segment No.", 0, ContactLanguageCode) then
                    Language := ContactLanguageCode
                else
                    Language := SegmentHeaderGlobal."Language Code (Default)";
            end else
                if SegmentInteractionLanguage.Get("Segment No.", "Line No.", ContactLanguageCode) then
                    Language := ContactLanguageCode
                else begin
                    InteractionTemplateLocal.Get(InteractTmplCode);
                    if SegmentInteractionLanguage.Get("Segment No.", "Line No.", InteractionTemplateLocal."Language Code (Default)") then
                        Language := InteractionTemplateLocal."Language Code (Default)"
                    else begin
                        SegmentInteractionLanguage.SetRange("Segment No.", "Segment No.");
                        SegmentInteractionLanguage.SetRange("Segment Line No.", "Line No.");
                        if SegmentInteractionLanguage.FindFirst() then
                            Language := SegmentInteractionLanguage."Language Code";
                    end;
                end;
        end else  // Create Interaction:
            if InteractionTmplLanguage.Get(InteractTmplCode, ContactLanguageCode) then
                Language := ContactLanguageCode
            else
                if InteractionTemplateLocal.Get(InteractTmplCode) then
                    Language := InteractionTemplateLocal."Language Code (Default)";
    end;

    procedure AttachmentInherited(): Boolean
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if ("Attachment No." = 0) and ("Word Template Code" = '') then
            exit(false)
        else
            if ("Attachment No." <> 0) and ("Word Template Code" <> '') then
                exit(false);
        if not SegmentHeaderGlobal.Get("Segment No.") then
            exit(false);
        if "Interaction Template Code" = '' then
            exit(false);

        SegmentInteractionLanguage.SetRange("Segment No.", "Segment No.");
        SegmentInteractionLanguage.SetRange("Segment Line No.", "Line No.");
        SegmentInteractionLanguage.SetRange("Language Code", "Language Code");
        SegmentInteractionLanguage.SetRange("Attachment No.", "Attachment No.");
        if not SegmentInteractionLanguage.IsEmpty() then
            exit(false);

        SegmentHeaderGlobal.CalcFields("Modified Word Template");
        SegmentInteractionLanguage.SetRange("Segment Line No.", 0);
        if (not SegmentInteractionLanguage.IsEmpty()) or (SegmentHeaderGlobal."Modified Word Template" <> 0) then
            exit(true);
    end;

    procedure SetInteractionAttachment()
    var
        Attachment: Record Attachment;
        InteractionTemplLanguage: Record "Interaction Tmpl. Language";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetInteractionAttachment(Rec, IsHandled);
        if IsHandled then
            exit;

        if InteractionTemplLanguage.Get("Interaction Template Code", "Language Code") then
            if Attachment.Get(InteractionTemplLanguage."Attachment No.") then
                "Attachment No." := InteractionTemplLanguage."Attachment No."
            else
                "Attachment No." := 0;
        Modify();
    end;

    local procedure UniqueAttachmentExists(): Boolean
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if "Line No." <> 0 then begin
            SegmentInteractionLanguage.SetRange("Segment No.", "Segment No.");
            SegmentInteractionLanguage.SetRange("Segment Line No.", "Line No.");
            exit(not SegmentInteractionLanguage.IsEmpty);
        end;
        exit(false);
    end;

    local procedure SetCampaignTargetGroup()
    begin
        if GlobalCampaign.Get(xRec."Campaign No.") then begin
            GlobalCampaign.CalcFields(Activated);
            if GlobalCampaign.Activated then
                CampaignTargetGroupMgt.DeleteSegfromTargetGr(xRec);
        end;

        if GlobalCampaign.Get("Campaign No.") then begin
            GlobalCampaign.CalcFields(Activated);
            if GlobalCampaign.Activated then
                CampaignTargetGroupMgt.AddSegLinetoTargetGr(Rec);
        end;
    end;

    procedure CopyFromInteractLogEntry(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
        "Line No." := InteractionLogEntry."Entry No.";
        "Contact No." := InteractionLogEntry."Contact No.";
        "Contact Company No." := InteractionLogEntry."Contact Company No.";
        Date := InteractionLogEntry.Date;
        Description := InteractionLogEntry.Description;
        "Information Flow" := InteractionLogEntry."Information Flow";
        "Initiated By" := InteractionLogEntry."Initiated By";
        "Attachment No." := InteractionLogEntry."Attachment No.";
        "Cost (LCY)" := InteractionLogEntry."Cost (LCY)";
        "Duration (Min.)" := InteractionLogEntry."Duration (Min.)";
        "Interaction Group Code" := InteractionLogEntry."Interaction Group Code";
        "Interaction Template Code" := InteractionLogEntry."Interaction Template Code";
        "Language Code" := InteractionLogEntry."Interaction Language Code";
        Subject := InteractionLogEntry.Subject;
        "Campaign No." := InteractionLogEntry."Campaign No.";
        "Campaign Entry No." := InteractionLogEntry."Campaign Entry No.";
        "Campaign Response" := InteractionLogEntry."Campaign Response";
        "Campaign Target" := InteractionLogEntry."Campaign Target";
        "Segment No." := InteractionLogEntry."Segment No.";
        Evaluation := InteractionLogEntry.Evaluation;
        "Time of Interaction" := InteractionLogEntry."Time of Interaction";
        "Attempt Failed" := InteractionLogEntry."Attempt Failed";
        "To-do No." := InteractionLogEntry."To-do No.";
        "Salesperson Code" := InteractionLogEntry."Salesperson Code";
        "Correspondence Type" := InteractionLogEntry."Correspondence Type";
        "Contact Alt. Address Code" := InteractionLogEntry."Contact Alt. Address Code";
        "Document Type" := InteractionLogEntry."Document Type";
        "Document No." := InteractionLogEntry."Document No.";
        "Doc. No. Occurrence" := InteractionLogEntry."Doc. No. Occurrence";
        "Version No." := InteractionLogEntry."Version No.";
        "Send Word Doc. As Attmt." := InteractionLogEntry."Send Word Docs. as Attmt.";
        "Contact Via" := InteractionLogEntry."Contact Via";
        "Opportunity No." := InteractionLogEntry."Opportunity No.";

        OnAfterCopyFromInteractionLogEntry(Rec, InteractionLogEntry);
    end;

    procedure CreateSegLineInteractionFromContact(var Contact: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSegLineInteractionFromContact(Rec, Contact, IsHandled);
        if IsHandled then
            exit;

        DeleteAll();
        Init();
        if Contact.Type = Contact.Type::Person then
            SetRange("Contact Company No.", Contact."Company No.");
        SetRange("Contact No.", Contact."No.");
        Validate("Contact No.", Contact."No.");

        "Salesperson Code" := FindSalespersonByUserEmail();
        if "Salesperson Code" = '' then
            "Salesperson Code" := Contact."Salesperson Code";

        OnCreateInteractionFromContactOnBeforeStartWizard(Rec, Contact);

        StartWizard();
    end;

    procedure CreateInteractionFromSalesperson(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        DeleteAll();
        Init();
        Validate("Salesperson Code", SalespersonPurchaser.Code);
        SetRange("Salesperson Code", SalespersonPurchaser.Code);

        OnCreateInteractionFromSalespersonOnBeforeStartWizard(Rec, SalespersonPurchaser);

        StartWizard();
    end;

    procedure CreateInteractionFromInteractLogEntry(var InteractionLogEntry: Record "Interaction Log Entry")
    var
        Contact: Record Contact;
        SalespersonPurchaserLocal: Record "Salesperson/Purchaser";
        CampaignLocal: Record Campaign;
        Task: Record "To-do";
        Opportunity: Record Opportunity;
    begin
        OnBeforeCreateInteractionFromInteractLogEntry(Rec, SalespersonPurchaserLocal);

        if Task.Get(InteractionLogEntry.GetFilter("To-do No.")) then begin
            CreateFromTask(Task);
            SetRange("To-do No.", "To-do No.");
        end else begin
            if Contact.Get(InteractionLogEntry.GetFilter("Contact Company No.")) then begin
                Validate("Contact No.", Contact."Company No.");
                SetRange("Contact No.", "Contact No.");
            end;
            if Contact.Get(InteractionLogEntry.GetFilter("Contact No.")) then begin
                Validate("Contact No.", Contact."No.");
                SetRange("Contact No.", "Contact No.");
            end;
            if SalespersonPurchaserLocal.Get(InteractionLogEntry.GetFilter("Salesperson Code")) then begin
                "Salesperson Code" := SalespersonPurchaserLocal.Code;
                SetRange("Salesperson Code", "Salesperson Code");
            end;
            if CampaignLocal.Get(InteractionLogEntry.GetFilter("Campaign No.")) then begin
                "Campaign No." := CampaignLocal."No.";
                SetRange("Campaign No.", "Campaign No.");
            end;
            if Opportunity.Get(InteractionLogEntry.GetFilter("Opportunity No.")) then begin
                "Opportunity No." := Opportunity."No.";
                SetRange("Opportunity No.", "Opportunity No.");
            end;
        end;

        OnCreateInteractionFromInteractLogEntryOnBeforeStartWizard(Rec, InteractionLogEntry);

        StartWizard();
    end;

    procedure CreateInteractionFromTask(var Task: Record "To-do")
    begin
        Init();
        CreateFromTask(Task);
        SetRange("To-do No.", "To-do No.");

        OnCreateInteractionFromTaskOnBeforeStartWizard(Rec, Task);

        StartWizard();
    end;

    procedure CreateInteractionFromOpp(var Opportunity: Record Opportunity)
    var
        Contact: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
    begin
        Init();
        if Contact.Get(Opportunity."Contact Company No.") then begin
            Contact.CheckIfPrivacyBlockedGeneric();
            Validate("Contact No.", Contact."Company No.");
            SetRange("Contact No.", "Contact No.");
        end;
        if Contact.Get(Opportunity."Contact No.") then begin
            Contact.CheckIfPrivacyBlockedGeneric();
            Validate("Contact No.", Contact."No.");
            SetRange("Contact No.", "Contact No.");
        end;
        if Salesperson.Get(Opportunity."Salesperson Code") then begin
            Validate("Salesperson Code", Salesperson.Code);
            SetRange("Salesperson Code", "Salesperson Code");
        end;
        if Campaign.Get(Opportunity."Campaign No.") then begin
            Validate("Campaign No.", Campaign."No.");
            SetRange("Campaign No.", "Campaign No.");
        end;
        Validate("Opportunity No.", Opportunity."No.");
        SetRange("Opportunity No.", "Opportunity No.");

        OnCreateInteractionFromOppOnBeforeStartWizard(Rec, Opportunity);

        StartWizard();
    end;

    procedure CreateOpportunity(): Code[20]
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.CreateFromSegmentLine(Rec);
        exit(Opportunity."No.");
    end;

    local procedure CreateFromTask(Task: Record "To-do")
    begin
        "To-do No." := Task."No.";
        Validate("Contact No.", Task."Contact No.");
        "Salesperson Code" := Task."Salesperson Code";
        "Campaign No." := Task."Campaign No.";
        "Opportunity No." := Task."Opportunity No.";

        OnAfterCreateFromTask(Rec, Task);
    end;

    local procedure GetContactName(): Text[100]
    var
        Contact: Record Contact;
    begin
        if Contact.Get("Contact No.") then
            exit(Contact.Name);
        if Contact.Get("Contact Company No.") then
            exit(Contact.Name);
    end;

    procedure StartWizard()
    var
        Opportunity: Record Opportunity;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStartWizard(Rec, IsHandled);
        if IsHandled then
            exit;

        if GlobalCampaign.Get("Campaign No.") then
            "Campaign Description" := GlobalCampaign.Description;
        if Opportunity.Get("Opportunity No.") then
            "Opportunity Description" := Opportunity.Description;
        "Wizard Contact Name" := GetContactName();
        "Wizard Step" := "Wizard Step"::"1";
        "Interaction Successful" := true;
        Validate(Date, WorkDate());
        "Time of Interaction" := DT2Time(RoundDateTime(CurrentDateTime + 1000, 60000, '>'));
        Insert();

        RunCreateInteraction();
    end;

    local procedure RunCreateInteraction()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCreateInteraction(Rec, IsHandled);
        if IsHandled then
            exit;

        if PAGE.RunModal(PAGE::"Create Interaction", Rec, "Interaction Template Code") = ACTION::OK then;
        if "Wizard Step" = "Wizard Step"::"6" then
            SendCreateOpportunityNotification();
    end;

    procedure SendCreateOpportunityNotification()
    var
        RelationshipPerformanceMgt: Codeunit "Relationship Performance Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendCreateOpportunityNotification(Rec, IsHandled);
        if IsHandled then
            exit;

        RelationshipPerformanceMgt.SendCreateOpportunityNotification(Rec);
    end;

    procedure CheckStatus()
    var
        InteractionTemplate: Record "Interaction Template";
        SalutationFormula: Record "Salutation Formula";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatus(Rec, IsHandled, TempAttachment);
        if IsHandled then
            exit;

        if "Contact No." = '' then
            Error(SelectContactErr);
        if "Interaction Template Code" = '' then
            ErrorMessage(CopyStr(FieldCaption("Interaction Template Code"), 1, 1024));
        if "Salesperson Code" = '' then
            ErrorMessage(CopyStr(FieldCaption("Salesperson Code"), 1, 1024));
        if Date = 0D then
            ErrorMessage(CopyStr(FieldCaption(Date), 1, 1024));
        if Description = '' then
            ErrorMessage(CopyStr(FieldCaption(Description), 1, 1024));

        InteractionTemplate.Get("Interaction Template Code");
        if InteractionTemplate."Wizard Action" = InteractionTemplate."Wizard Action"::Open then
            if ("Attachment No." = 0) and (InteractionTemplate."Word Template Code" = '') then
                Error(NoAttachmentErr);

        ContactGlobal.Get("Contact No.");
        if SalutationFormula.Get(ContactGlobal."Salutation Code", "Language Code", 0) then;
        if SalutationFormula.Get(ContactGlobal."Salutation Code", "Language Code", 1) then;

        if TempAttachment.FindFirst() then
            TempAttachment.CalcFields("Attachment File");
        if ("Correspondence Type" = "Correspondence Type"::Email) and
           not TempAttachment."Attachment File".HasValue() and
           (InteractionTemplate."Word Template Code" = '')
        then
            Error(AttachmentRequiredErr);

        OnAfterCheckStatus(Rec);
    end;

    procedure FinishSegLineWizard(IsFinish: Boolean)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SegManagement: Codeunit SegManagement;
        Send: Boolean;
        Flag: Boolean;
        HTMLAttachment: Boolean;
        HTMLContentBodyText: Text;
        CustomLayoutCode: Code[20];
        ReportLayoutName: Text[250];
        ShouldAssignStep: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinishSegLineWizard(Rec, IsFinish, TempAttachment, TempInterLogEntryCommentLine, IsHandled);
        if not IsHandled then begin
            Flag := GetFinishInteractionFlag(IsFinish);

            if Flag then begin
                CheckStatus();

                ShouldAssignStep := "Opportunity No." = '';
                OnFinishSegLineWizardOnBeforeAssignEmptyOpportunityStep(Rec, ShouldAssignStep);
                if ShouldAssignStep then
                    "Wizard Step" := "Wizard Step"::"6";

                "Attempt Failed" := not "Interaction Successful";
                Subject := Description;
                if not HTMLAttachment then
                    ProcessPostponedAttachment();
                Send := (IsFinish and ("Correspondence Type" <> "Correspondence Type"::" "));
                OnFinishWizardOnAfterSetSend(Rec, Send);
                if Send and HTMLAttachment then begin
                    TempAttachment.ReadHTMLCustomLayoutAttachment(HTMLContentBodyText, CustomLayoutCode, ReportLayoutName);
                    AttachmentManagement.GenerateHTMLContent(TempAttachment, Rec);
                end;
                IsHandled := false;
                OnFinishSegLineWizardBeforeLogInteraction(Rec, IsHandled);
                if not IsHandled then
                    SegManagement.LogInteraction(Rec, TempAttachment, TempInterLogEntryCommentLine, send, not IsFinish);

                if Rec."Line No." <> 0 then
                    InteractionLogEntry.Get(Rec."Line No.")
                else
                    InteractionLogEntry.FindLast();
                if Send and (InteractionLogEntry."Delivery Status" = InteractionLogEntry."Delivery Status"::Error) then
                    if HTMLAttachment then begin
                        Clear(TempAttachment);
                        LoadTempAttachment(false);
                        if CustomLayoutCode <> '' then
                            TempAttachment.WriteHTMLCustomLayoutAttachment(HTMLContentBodyText, CustomLayoutCode)
                        else
                            TempAttachment.WriteHTMLCustomLayoutAttachment(HTMLContentBodyText, ReportLayoutName);
                        Commit();
                    end;
                InteractionLogEntryNo := InteractionLogEntry."Entry No.";
            end;
        end;

        OnAfterFinishWizard(Rec, InteractionLogEntry, IsFinish, Flag);
    end;

    internal procedure GetInteractionLogEntryNo(): Integer
    begin
        exit(InteractionLogEntryNo);
    end;

    local procedure GetFinishInteractionFlag(IsFinish: Boolean) Flag: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFinishInteractionFlag(Rec, IsFinish, Flag, IsHandled);
        if IsHandled then
            exit(Flag);

        Flag := false;
        if IsFinish then
            Flag := true
        else
            Flag := Confirm(FinishInteractionLaterQst);
    end;

    local procedure ErrorMessage(FieldName: Text[1024])
    begin
        Error(FieldNotFilledErr, FieldName);
    end;

    procedure ValidateCorrespondenceType()
    begin
        if "Correspondence Type" <> "Correspondence Type"::" " then
            if TempAttachment.FindFirst() then;
    end;

    internal procedure HandleTrigger()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        DocumentSharing: Codeunit "Document Sharing";
        Telemetry: Codeunit Telemetry;
        ImportedFileName: Text;
        IsHandled: Boolean;
    begin
        OnBeforeHandleTrigger(Rec, TempAttachment, Merged, IsHandled);
        if IsHandled then
            exit;

        GlobalInteractionTemplate.Get("Interaction Template Code");

        case GlobalInteractionTemplate."Wizard Action" of
            GlobalInteractionTemplate."Wizard Action"::" ":
                if "Attachment No." <> 0 then begin
                    LoadTempAttachment(false);
                    Subject := Description;
                end;
            GlobalInteractionTemplate."Wizard Action"::Open:
                begin
                    if ("Attachment No." = 0) and (GlobalInteractionTemplate."Word Template Code" = '') then
                        Error(NoAttachmentErr);

                    Subject := Description;

                    if GlobalInteractionTemplate."Word Template Code" = '' then begin
                        LoadTempAttachment(false);
                        if not DocumentSharing.ShareEnabled(Enum::"Document Sharing Source"::System) or not (Text.LowerCase(TempAttachment."File Extension") = 'docx') then begin
                            Telemetry.LogMessage('0000K88', 'OneDrive not enabled', Verbosity::Normal, DataClassification::SystemMetadata);

                            TempAttachment.OpenAttachment(Rec, Description);
                        end else
                            MergeTemplate(true, true);
                    end else begin
                        if not DocumentSharing.ShareEnabled(Enum::"Document Sharing Source"::System) then begin
                            Message(OneDriveNotEnabledMsg);
                            Telemetry.LogMessage('0000K5L', 'OneDrive not enabled', Verbosity::Normal, DataClassification::SystemMetadata);
                            exit;
                        end;

                        MergeTemplate(true, false);
                    end;

                    Merged := true;
                end;
            GlobalInteractionTemplate."Wizard Action"::Import:
                begin
                    ImportedFileName := FileMgt.BLOBImport(TempBlob, ImportedFileName);
                    if ImportedFileName = '' then
                        Message(AttachmentImportCancelledMsg)
                    else begin
                        TempAttachment.DeleteAll();
                        TempAttachment.SetAttachmentFileFromBlob(TempBlob);
                        TempAttachment."File Extension" := CopyStr(FileMgt.GetExtension(ImportedFileName), 1, 250);
                        TempAttachment.Insert();
                    end;
                    Merged := true;
                end;
            GlobalInteractionTemplate."Wizard Action"::Merge:
                if GlobalInteractionTemplate."Word Template Code" = '' then
                    Merged := false
                else begin
                    MergeTemplate(false, false);
                    Merged := true;
                end;
            else
                OnHandleTriggerCaseElse(Rec, GlobalInteractionTemplate);
        end;
    end;

    local procedure MergeTemplate(EditDocument: Boolean; UseTempAttachment: Boolean)
    var
        TempInteractionMergeData: Record "Interaction Merge Data" temporary;
        WordTemplate: Codeunit "Word Template";
        InStream: InStream;
        FileExtension: Text[250];
    begin
        CreateInteractionMergeData(TempInteractionMergeData);
        LoadTemplateAttachment(UseTempAttachment, WordTemplate);

        if UseTempAttachment then
            FileExtension := TempAttachment."File Extension"
        else
            FileExtension := 'docx';

        WordTemplate.Merge(TempInteractionMergeData, false, Enum::"Word Templates Save Format"::Docx, EditDocument, Enum::"Doc. Sharing Conflict Behavior"::Replace);

        WordTemplate.GetDocument(InStream);
        TempAttachment.DeleteAll();
        TempAttachment.SetAttachmentFileFromStream(InStream);
        TempAttachment."File Extension" := FileExtension;
        TempAttachment.Insert();
    end;

    local procedure CreateInteractionMergeData(var TempInteractionMergeData: Record "Interaction Merge Data" temporary)
    begin
        TempInteractionMergeData.Id := CreateGuid();
        TempInteractionMergeData."Contact No." := Rec."Contact No.";
        TempInteractionMergeData."Salesperson Code" := Rec."Salesperson Code";
        OnCreateInteractionMergeDataOnBeforeTempInteractionMergeDataInsert(TempInteractionMergeData, Rec);
        TempInteractionMergeData.Insert();
    end;

    local procedure LoadTemplateAttachment(UseTempAttachment: Boolean; var WordTemplate: Codeunit "Word Template")
    var
        Attachment: Record Attachment;
        InStream: InStream;
    begin
        if UseTempAttachment then begin
            TempAttachment.CalcFields("Attachment File");
            TempAttachment."Attachment File".CreateInStream(InStream);
            WordTemplate.Load(InStream);
        end else begin
            SegmentHeaderGlobal.CalcFields("Modified Word Template");
            if SegmentHeaderGlobal."Modified Word Template" <> 0 then begin
                if Dialog.Confirm(ModifyExistingAttachmentMsg, true) then begin
                    Attachment.Get(SegmentHeaderGlobal."Modified Word Template");
                    Attachment.CalcFields("Attachment File");
                    Attachment."Attachment File".CreateInStream(InStream);
                    WordTemplate.Load(InStream, GlobalInteractionTemplate."Word Template Code");
                end else
                    WordTemplate.Load(GlobalInteractionTemplate."Word Template Code");
            end else
                WordTemplate.Load(GlobalInteractionTemplate."Word Template Code");
        end;
    end;

    local procedure LoadTempAttachment(ForceReload: Boolean)
    begin
        if not ForceReload and TempAttachment."Attachment File".HasValue() then
            exit;
        GlobalAttachment.Get("Attachment No.");
        GlobalAttachment.CalcFields("Attachment File");
        TempAttachment.DeleteAll();
        TempAttachment.WizEmbeddAttachment(GlobalAttachment);
        TempAttachment."No." := 0;
        TempAttachment."Read Only" := false;
        if GlobalAttachment.IsHTML() then
            TempAttachment."File Extension" := GlobalAttachment."File Extension";
        OnLoadTempAttachmentOnBeforeInsertTempAttachment(Rec, TempAttachment);
        TempAttachment.Insert();
    end;

    procedure SetTempAttachment(var InStream: InStream; FileExtension: Text)
    begin
        TempAttachment.DeleteAll();
        TempAttachment.SetAttachmentFileFromStream(InStream);
        TempAttachment."File Extension" := CopyStr(FileExtension, 1, 250);
        TempAttachment.Insert();
    end;

    procedure LoadContentBodyTextFromCustomLayoutAttachment(): Text
    var
        ContentBodyText: Text;
        CustomLayoutCode: Code[20];
    begin
        TempAttachment.ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode);
        exit(ContentBodyText);
    end;

    procedure UpdateContentBodyTextInCustomLayoutAttachment(NewContentBodyText: Text)
    var
        OldContentBodyText: Text;
        CustomLayoutCode: Code[20];
        ReportLayoutName: Text[250];
    begin
        TempAttachment.Find();
        TempAttachment.ReadHTMLCustomLayoutAttachment(OldContentBodyText, CustomLayoutCode, ReportLayoutName);
        if CustomLayoutCode <> '' then
            TempAttachment.WriteHTMLCustomLayoutAttachment(NewContentBodyText, CustomLayoutCode)
        else
            TempAttachment.WriteHTMLCustomLayoutAttachment(NewContentBodyText, ReportLayoutName);
    end;

    procedure ProcessPostponedAttachment()
    begin
        if "Attachment No." <> 0 then begin
            LoadTempAttachment(false);
            if "Line No." <> 0 then
                "Attachment No." := ResumedAttachmentNo;
        end else
            if GlobalAttachment.Get(ResumedAttachmentNo) then
                GlobalAttachment.RemoveAttachment(false);
    end;

    procedure LoadSegLineAttachment(ForceReload: Boolean)
    begin
        if "Line No." <> 0 then begin
            InterLogEntryCommentLine.SetRange("Entry No.", "Line No.");
            if InterLogEntryCommentLine.Find('-') then
                repeat
                    TempInterLogEntryCommentLine.Init();
                    TempInterLogEntryCommentLine.TransferFields(InterLogEntryCommentLine, false);
                    TempInterLogEntryCommentLine."Line No." := InterLogEntryCommentLine."Line No.";
                    TempInterLogEntryCommentLine.Insert();
                until InterLogEntryCommentLine.Next() = 0;
            ResumedAttachmentNo := "Attachment No.";
        end;
        if "Attachment No." <> 0 then
            LoadTempAttachment(ForceReload)
        else begin
            TempAttachment.DeleteAll();
            Clear(TempAttachment);
        end;
    end;

    procedure MakePhoneCallFromContact(var Cont: Record Contact; Task: Record "To-do"; TableNo: Integer; PhoneNo: Text[30]; ContAltAddrCode: Code[10])
    begin
        Init();
        if Cont.Type = Cont.Type::Person then
            SetRange("Contact No.", Cont."No.")
        else
            SetRange("Contact Company No.", Cont."Company No.");
        if PhoneNo <> '' then
            "Contact Via" := PhoneNo
        else
            "Contact Via" := Cont."Phone No.";
        Validate("Contact No.", Cont."No.");
        "Contact Name" := Cont.Name;
        Validate(Date, Today);
        if ContAltAddrCode <> '' then
            "Contact Alt. Address Code" := ContAltAddrCode;
        if TableNo = DATABASE::"To-do" then
            "To-do No." := Task."No.";
        StartWizard2();
    end;

    procedure StartWizard2()
    var
        InteractionTmplSetup: Record "Interaction Template Setup";
        Campaign: Record Campaign;
    begin
        OnBeforeStartWizard2(Rec);

        InteractionTmplSetup.Get();
        InteractionTmplSetup.TestField("Outg. Calls");

        "Wizard Step" := "Wizard Step"::"1";
        if Date = 0D then
            Date := Today;
        "Time of Interaction" := Time;
        "Interaction Successful" := true;
        "Dial Contact" := true;

        if Campaign.Get(GetFilter("Campaign No.")) then
            "Campaign Description" := Campaign.Description;
        "Wizard Contact Name" := GetContactName();

        Insert();
        Validate("Interaction Template Code", InteractionTmplSetup."Outg. Calls");
        if PAGE.RunModal(PAGE::"Make Phone Call", Rec, "Contact Via") = ACTION::OK then;
    end;

    procedure CheckPhoneCallStatus()
    begin
        if "Wizard Step" = "Wizard Step"::"1" then begin
            if "Dial Contact" and ("Contact Via" = '') then
                Error(PhoneNumberErr);
            if Date = 0D then
                ErrorMessage(CopyStr(FieldCaption(Date), 1, 1024));
            if Description = '' then
                ErrorMessage(CopyStr(FieldCaption(Description), 1, 1024));
            if "Salesperson Code" = '' then
                ErrorMessage(CopyStr(FieldCaption("Salesperson Code"), 1, 1024));
        end;
    end;

    procedure LogSegLinePhoneCall()
    var
        TempLocalAttachment: Record Attachment temporary;
        SegmentLine: Record "Segment Line";
        SegManagement: Codeunit SegManagement;
    begin
        "Attempt Failed" := not "Interaction Successful";

        SegManagement.LogInteraction(Rec, TempLocalAttachment, TempInterLogEntryCommentLine, false, false);

        if SegmentLine.Get("Segment No.", "Line No.") then begin
            SegmentLine.LockTable();
            SegmentLine."Contact Via" := "Contact Via";
            SegmentLine."Wizard Step" := SegmentLine."Wizard Step"::" ";
            SegmentLine.Modify();
        end;
    end;

    procedure ShowComment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowComment(Rec, TempInterLogEntryCommentLine, IsHandled);
        if IsHandled then
            exit;

        PAGE.RunModal(PAGE::"Inter. Log Entry Comment Sheet", TempInterLogEntryCommentLine);
    end;

    procedure SetComments(var InterLogEntryCommentLineLocal: Record "Inter. Log Entry Comment Line")
    begin
        TempInterLogEntryCommentLine.DeleteAll();

        if InterLogEntryCommentLineLocal.FindSet() then
            repeat
                TempInterLogEntryCommentLine := InterLogEntryCommentLineLocal;
                TempInterLogEntryCommentLine.Insert();
            until InterLogEntryCommentLineLocal.Next() = 0;
    end;

    local procedure SetCorrespondenceType(InteractionTemplate: Record "Interaction Template")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCorrespondenceType(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        case true of
            SegmentHeaderGlobal."Ignore Contact Corres. Type" and
            (SegmentHeaderGlobal."Correspondence Type (Default)" <> SegmentHeaderGlobal."Correspondence Type (Default)"::" "):
                "Correspondence Type" := SegmentHeaderGlobal."Correspondence Type (Default)";
            InteractionTemplate."Ignore Contact Corres. Type" or
            ((InteractionTemplate."Ignore Contact Corres. Type" = false) and
            (ContactGlobal."Correspondence Type" = ContactGlobal."Correspondence Type"::" ") and
            (InteractionTemplate."Correspondence Type (Default)" <> InteractionTemplate."Correspondence Type (Default)"::" ")):
                "Correspondence Type" := InteractionTemplate."Correspondence Type (Default)";
            else
                if ContactGlobal."Correspondence Type" <> ContactGlobal."Correspondence Type"::" " then
                    "Correspondence Type" := ContactGlobal."Correspondence Type"
                else
                    "Correspondence Type" := xRec."Correspondence Type";
        end;
    end;

    procedure IsHTMLAttachment(): Boolean
    begin
        if not TempAttachment.Find() then
            exit(false);
        exit(TempAttachment.IsHTML());
    end;

    procedure PreviewSegLineHTMLContent()
    begin
        TempAttachment.Find();
        TempAttachment.ShowAttachment(Rec, '');
    end;

    procedure LanguageCodeOnLookup()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        TestField("Interaction Template Code");

        if SegmentHeaderGlobal.Get("Segment No.") then begin
            SegmentInteractionLanguage.SetRange("Segment No.", "Segment No.");
            if UniqueAttachmentExists() or
               ("Interaction Template Code" <> SegmentHeaderGlobal."Interaction Template Code")
            then
                SegmentInteractionLanguage.SetRange("Segment Line No.", "Line No.")
            else
                SegmentInteractionLanguage.SetRange("Segment Line No.", 0);

            if PAGE.RunModal(0, SegmentInteractionLanguage) = ACTION::LookupOK then begin
                Get("Segment No.", "Line No.");
                "Language Code" := SegmentInteractionLanguage."Language Code";
                "Attachment No." := SegmentInteractionLanguage."Attachment No.";
                Rec."Word Template Code" := SegmentInteractionLanguage."Word Template Code";
                Subject := SegmentInteractionLanguage.Subject;
                Modify();
            end else
                Get("Segment No.", "Line No.");
        end else begin  // Create Interaction
            InteractionTmplLanguage.SetRange("Interaction Template Code", "Interaction Template Code");
            if PAGE.RunModal(0, InteractionTmplLanguage) = ACTION::LookupOK then begin
                "Language Code" := InteractionTmplLanguage."Language Code";
                Modify();
            end;
            SetInteractionAttachment();
        end;
    end;

    procedure FilterContactCompanyOpportunities(var Opportunity: Record Opportunity)
    begin
        Opportunity.Reset();
        Opportunity.SetRange(Closed, false);
        if "Salesperson Code" <> '' then
            Opportunity.SetRange("Salesperson Code", "Salesperson Code");
        Opportunity.SetFilter("Contact Company No.", "Contact Company No.");
        if "Opportunity No." <> '' then begin
            Opportunity.SetRange("No.", "Opportunity No.");
            if Opportunity.FindFirst() then;
            Opportunity.SetRange("No.");
        end;
    end;

    local procedure FindSalespersonByUserEmail(): Code[20]
    var
        User: Record User;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Email: Text[250];
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            Email := User."Authentication Email";

        if Email <> '' then begin
            SalespersonPurchaser.SetRange("E-Mail", Email);
            if SalespersonPurchaser.Count = 1 then begin
                SalespersonPurchaser.FindFirst();
                "Salesperson Code" := SalespersonPurchaser.Code;
            end;
        end;
        exit("Salesperson Code");
    end;

    procedure ExportODataFields()
    var
        TenantWebService: Record "Tenant Web Service";
        ODataFieldsExport: Page "OData Fields Export";
        SegLineRecordRef: RecordRef;
    begin
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Query);
        TenantWebService.SetRange("Object ID", QUERY::"Segment Lines");
        TenantWebService.FindFirst();

        SegLineRecordRef.Open(DATABASE::"Segment Line");
        SegLineRecordRef.SetView(GetView());

        ODataFieldsExport.SetExportData(TenantWebService, SegLineRecordRef);
        ODataFieldsExport.RunModal();
    end;

    procedure ProcessInterLogEntryComments(InterLogEntryNo: Integer)
    var
        SegManagement: Codeunit SegManagement;
    begin
        SegManagement.InterLogEntryCommentLineInsert(TempInterLogEntryCommentLine, InterLogEntryNo);
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.GET(USERID) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            VALIDATE("Salesperson Code", UserSetup."Salespers./Purch. Code");

    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckStatus(var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromInteractionLogEntry(var SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateFromTask(var SegmentLine: Record "Segment Line"; Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitLine(var SegmentLine: Record "Segment Line"; SegmentHeader: Record "Segment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinishWizard(var SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry"; IsFinish: Boolean; Flag: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFinishInteractionFlag(var SegmentLine: Record "Segment Line"; IsFinish: Boolean; var Flag: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatus(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean; var AttachmentTmp: Record Attachment temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePhoneCall(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinishSegLineWizard(var SegmentLine: Record "Segment Line"; IsFinish: Boolean; var TempAttachment: Record Attachment temporary; var TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendCreateOpportunityNotification(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCorrespondenceType(var SegmentLine: Record "Segment Line"; var xSegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartWizard(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreateInteraction(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartWizard2(var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromContactOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromSalespersonOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromInteractLogEntryOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromTaskOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromOppOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePhoneCallOnBeforeStartWizard2(var TempSegmentLine: Record "Segment Line" temporary; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeSegmentCriteriaLineDeleteAll(SegmentLine: Record "Segment Line"; SegmentCriteriaLine: Record "Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizardOnAfterSetSend(var SegmentLine: Record "Segment Line"; var Send: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleTriggerCaseElse(SegmentLine: Record "Segment Line"; InteractionTemplate: Record "Interaction Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateInteractionTemplateCode(var SegmentLine: Record "Segment Line"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInteractionTemplValidateOnBeforeGetInteractTemplLanguage(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowComment(var SegmentLine: Record "Segment Line"; var TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSegLineInteractionFromContact(var SegmentLine: Record "Segment Line"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInteractionFromInteractLogEntry(var SegmentLine: Record "Segment Line"; var Salesperson: Record "Salesperson/Purchaser")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishSegLineWizardOnBeforeAssignEmptyOpportunityStep(var SegmentLine: Record "Segment Line"; var ShouldAssignStep: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishSegLineWizardBeforeLogInteraction(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateInteractionTemplateCodeOnBeforeGetSegInteractTemplLanguage(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLanguageCodeOnBeforeGetSegmentHeaderGlobal(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLanguage(var SegmentLine: Record "Segment Line"; InteractTmplCode: Code[10]; ContactLanguageCode: Code[10]; var Language: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetInteractionAttachment(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionMergeDataOnBeforeTempInteractionMergeDataInsert(var TempInteractionMergeData: Record "Interaction Merge Data" temporary; var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadTempAttachmentOnBeforeInsertTempAttachment(SegmentLine: Record "Segment Line"; var TempAttachment: Record Attachment temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateInteractionTemplateCodeOnBeforeGettingContact(SegmentLine: Record "Segment Line"; xSegmentLine: Record "Segment Line"; var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleTrigger(var SegmentLine: Record "Segment Line"; var TempAttachment: Record Attachment temporary; var Merged: Boolean; var IsHandled: Boolean)
    begin
    end;
}
