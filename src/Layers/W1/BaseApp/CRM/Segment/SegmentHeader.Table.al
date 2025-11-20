// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Ledger;
using System.Globalization;
using System.Integration;
using System.Integration.Word;
using System.Reflection;
using System.Security.User;
using System.Utilities;

table 5076 "Segment Header"
{
    Caption = 'Segment Header';
    DataCaptionFields = "No.", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Segment List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    RMSetup.Get();
                    NoSeries.TestManual(RMSetup."Segment Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo(Description), CurrFieldNo <> 0);
            end;
        }
        field(3; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Campaign No."), CurrFieldNo <> 0);
            end;
        }
        field(4; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Salesperson Code"), CurrFieldNo <> 0);
            end;
        }
        field(5; "Correspondence Type (Default)"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type (Default)';

            trigger OnValidate()
            var
                Attachment: Record Attachment;
                InteractionTemplate: Record "Interaction Template";
                TemplateFound: Boolean;
            begin
                if InteractionTemplate.Get(Rec."Interaction Template Code") then
                    if InteractionTemplate."Word Template Code" <> '' then
                        TemplateFound := true;
                if Attachment.Get("Attachment No.") then
                    TemplateFound := true;

                if not TemplateFound then
                    exit;
                if "Correspondence Type (Default)" <> "Correspondence Type (Default)"::" " then
                    UpdateSegLinesByFieldNo(FieldNo("Correspondence Type (Default)"), CurrFieldNo <> 0);
            end;
        }
        field(6; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            TableRelation = "Interaction Template".Code;

            trigger OnValidate()
            var
                InteractionTemplate: Record "Interaction Template";
            begin
                InteractionTemplate.Get(Rec."Interaction Template Code");
                Rec.Validate("Word Template Code", InteractionTemplate."Word Template Code");

                UpdateSegLinesByFieldNo(FieldNo("Interaction Template Code"), CurrFieldNo <> 0);
            end;
        }
        field(7; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Unit Cost (LCY)"), CurrFieldNo <> 0);
            end;
        }
        field(8; "Unit Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Duration (Min.)';
            DecimalPlaces = 0 : 0;
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Unit Duration (Min.)"), CurrFieldNo <> 0);
            end;
        }
        field(9; "Attachment No."; Integer)
        {
            CalcFormula = lookup("Segment Interaction Language"."Attachment No." where("Segment No." = field("No."),
                                                                                        "Segment Line No." = const(0),
                                                                                        "Language Code" = field("Language Code (Default)"),
                                                                                        "Word Template Code" = const('')));
            Caption = 'Attachment No.';
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Attachment No."), CurrFieldNo <> 0);
            end;
        }
        field(10; Date; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo(Date), CurrFieldNo <> 0);
            end;
        }
        field(11; "Campaign Target"; Boolean)
        {
            Caption = 'Campaign Target';

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Campaign Target"), CurrFieldNo <> 0);
            end;
        }
        field(12; "Information Flow"; Option)
        {
            BlankZero = true;
            Caption = 'Information Flow';
            OptionCaption = ' ,Outbound,Inbound';
            OptionMembers = " ",Outbound,Inbound;

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Information Flow"), CurrFieldNo <> 0);
            end;
        }
        field(13; "Initiated By"; Option)
        {
            BlankZero = true;
            Caption = 'Initiated By';
            OptionCaption = ' ,Us,Them';
            OptionMembers = " ",Us,Them;

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Initiated By"), CurrFieldNo <> 0);
            end;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(15; "Campaign Response"; Boolean)
        {
            Caption = 'Campaign Response';

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Campaign Response"), CurrFieldNo <> 0);
            end;
        }
        field(16; "No. of Lines"; Integer)
        {
            CalcFormula = count("Segment Line" where("Segment No." = field("No.")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Segment Line"."Cost (LCY)" where("Segment No." = field("No.")));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Segment Line"."Duration (Min.)" where("Segment No." = field("No.")));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Language Code (Default)"; Code[10])
        {
            Caption = 'Language Code (Default)';
            TableRelation = Language;

            trigger OnLookup()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
            begin
                Modify();
                Commit();

                SegInteractLanguage.SetRange("Segment No.", "No.");
                SegInteractLanguage.SetRange("Segment Line No.", 0);
                if "Language Code (Default)" <> '' then
                    SegInteractLanguage.Get("No.", 0, "Language Code (Default)");
                if PAGE.RunModal(0, SegInteractLanguage) = ACTION::LookupOK then begin
                    Get("No.");
                    "Language Code (Default)" := SegInteractLanguage."Language Code";
                    "Subject (Default)" := SegInteractLanguage.Subject;
                    Modify();
                end else
                    Get("No.");
                CalcFields("Attachment No.");
            end;

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
            begin
                if "Language Code (Default)" = xRec."Language Code (Default)" then
                    exit;

                if not SegInteractLanguage.Get("No.", 0, "Language Code (Default)") then begin
                    "Subject (Default)" := '';
                    if Confirm(Text010, true, SegInteractLanguage.TableCaption(), "Language Code (Default)") then begin
                        SegInteractLanguage.Init();
                        SegInteractLanguage."Segment No." := "No.";
                        SegInteractLanguage."Segment Line No." := 0;
                        SegInteractLanguage."Language Code" := "Language Code (Default)";
                        SegInteractLanguage.Description := Format("Interaction Template Code") + ' ' + Format("Language Code (Default)");
                        SegInteractLanguage.Insert(true);
                    end else
                        Error('');
                end else
                    "Subject (Default)" := SegInteractLanguage.Subject;
            end;
        }
        field(20; "Interaction Group Code"; Code[10])
        {
            Caption = 'Interaction Group Code';
            TableRelation = "Interaction Group";
        }
        field(21; "No. of Criteria Actions"; Integer)
        {
            CalcFormula = count("Segment Criteria Line" where("Segment No." = field("No."),
                                                               Type = const(Action)));
            Caption = 'No. of Criteria Actions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Send Word Docs. as Attmt."; Boolean)
        {
            Caption = 'Send Word Docs. as Attmt.';

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Send Word Docs. as Attmt."), CurrFieldNo <> 0);
            end;
        }
        field(23; "Ignore Contact Corres. Type"; Boolean)
        {
            Caption = 'Ignore Contact Corres. Type';
        }
        field(24; "Subject (Default)"; Text[100])
        {
            Caption = 'Subject (Default)';

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
                UpdateLines: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSubjectDefault(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if SegLinesExist(FieldCaption("Subject (Default)")) then
                    UpdateLines := Confirm(StrSubstNo(Text011, FieldCaption("Subject (Default)")), true);

                if SegInteractLanguage.Get("No.", 0, "Language Code (Default)") then begin
                    SegInteractLanguage.Subject := "Subject (Default)";
                    SegInteractLanguage.Modify();
                    Modify();
                end;

                if not UpdateLines then
                    exit;

                SegLine.SetRange("Segment No.", "No.");
                SegLine.SetRange("Interaction Template Code", "Interaction Template Code");
                SegLine.SetRange("Language Code", "Language Code (Default)");
                SegLine.SetRange(Subject, xRec."Subject (Default)");
                SegLine.ModifyAll(Subject, "Subject (Default)");
            end;
        }
        field(25; "Campaign Description"; Text[100])
        {
            CalcFormula = lookup(Campaign.Description where("No." = field("Campaign No.")));
            Caption = 'Campaign Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
            TableRelation = "Word Template".Code where("Table ID" = const(5106)); // Only Interaction Merge Data word templates are allowed

            trigger OnValidate()
            begin
                UpdateSegLinesByFieldNo(FieldNo("Word Template Code"), CurrFieldNo <> 0);
            end;
        }
        field(27; "Modified Word Template"; Integer)
        {
            CalcFormula = lookup("Segment Interaction Language"."Attachment No." where("Segment No." = field("No."),
                                                                                        "Segment Line No." = const(0),
                                                                                        "Language Code" = field("Language Code (Default)"),
                                                                                        "Word Template Code" = field("Word Template Code")));
            Caption = 'Modified Word Template';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Salesperson Code")
        {
        }
        key(Key3; "Campaign No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Campaign No.")
        {
        }
    }

    trigger OnDelete()
    var
        SegmentHistory: Record "Segment History";
        SegmentCriteriaLine: Record "Segment Criteria Line";
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        SegmentCriteriaLine.SetRange("Segment No.", "No.");
        SegmentCriteriaLine.DeleteAll(); // Must be deleted first!
        SegmentHistory.SetRange("Segment No.", "No.");
        SegmentHistory.DeleteAll();

        SegmentInteractionLanguage.SetRange("Segment No.", "No.");
        SegmentInteractionLanguage.DeleteAll(true);

        SegLine.SetRange("Segment No.", "No.");
        SegLine.DeleteAll(true);

        Get("No.");
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            RMSetup.Get();
            RMSetup.TestField("Segment Nos.");
            if NoSeries.AreRelated(RMSetup."Segment Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := RMSetup."Segment Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        if "Salesperson Code" = '' then
            SetDefaultSalesperson();

        Date := WorkDate();
    end;

    var
        RMSetup: Record "Marketing Setup";
        SegHeader: Record "Segment Header";
        SegLine: Record "Segment Line";
        NoSeries: Codeunit "No. Series";
        SegCriteriaManagement: Codeunit SegCriteriaManagement;
        SegHistMgt: Codeunit SegHistoryManagement;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'You have modified %1.\\Do you want to update the segment lines where the Interaction Template Code is %2?';
        Text003: Label '%1 may not be modified without updating lines when inherited attachments exist.';
        Text005: Label 'Segment %1 already contains %2 %3.\Are you sure you want to reuse a %4?';
        Text006: Label 'Segment %1 already contains %2 %3.\Are you sure you want to reuse a %4?';
        Text010: Label 'Do you want to create %1 %2?';
        Text011: Label 'You have modified %1.\\Do you want to update the corresponding segment lines?';
        Text012: Label 'You have modified %1.\\Do you want to apply the %1 %2 to all segment lines?', Comment = 'You have modified Meeting.\\Do you want to apply the Meeting BUS to all segment lines?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        WordTemplateUsedErr: Label 'You cannot use an attachment when a Word template has been specified.';
        TempTemplateFileNameLbl: Label 'Temp Template';
        TempTemplateExtensionLbl: Label '.docx', Locked = true;
        ModifyExistingWordTemplateMsg: Label 'Modify existing modified Word template?';

    procedure AssistEdit(OldSegHeader: Record "Segment Header"): Boolean
    begin
        SegHeader := Rec;
        RMSetup.Get();
        RMSetup.TestField("Segment Nos.");
        if NoSeries.LookupRelatedNoSeries(RMSetup."Segment Nos.", OldSegHeader."No. Series", SegHeader."No. Series") then begin
            SegHeader."No." := NoSeries.GetNextNo(SegHeader."No. Series");
            Rec := SegHeader;
            exit(true);
        end;
    end;

    procedure CreateOpportunities()
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", "No.");
        SegmentLine.SetFilter("Contact No.", '<>%1', '');
        if SegmentLine.FindSet() then
            repeat
                SegmentLine.CreateOpportunity();
            until SegmentLine.Next() = 0;
    end;

    procedure CreateSegInteractions(InteractionTemplateCode: Code[10]; SegmentNo: Code[20]; SegmentLineNo: Integer)
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        SegInteractLanguage: Record "Segment Interaction Language";
        Attachment: Record Attachment;
        AttachmentManagement: Codeunit AttachmentManagement;
        IsHandled: Boolean;
    begin
        SegInteractLanguage.SetRange("Segment No.", SegmentNo);
        SegInteractLanguage.SetRange("Segment Line No.", SegmentLineNo);
        SegInteractLanguage.DeleteAll(true);

        IsHandled := false;
        OnCreateSegInteractionsOnAfterDeleteAll(InteractionTemplateCode, SegmentNo, SegmentLineNo, IsHandled);
        if IsHandled then
            exit;

        InteractionTmplLanguage.Reset();
        InteractionTmplLanguage.SetRange("Interaction Template Code", InteractionTemplateCode);
        if InteractionTmplLanguage.Find('-') then
            repeat
                SegInteractLanguage.Init();
                SegInteractLanguage."Segment No." := SegmentNo;
                SegInteractLanguage."Segment Line No." := SegmentLineNo;
                SegInteractLanguage."Language Code" := InteractionTmplLanguage."Language Code";
                SegInteractLanguage.Description := InteractionTmplLanguage.Description;
                SegInteractLanguage."Word Template Code" := InteractionTmplLanguage."Word Template Code";
                if Attachment.Get(InteractionTmplLanguage."Attachment No.") then
                    SegInteractLanguage."Attachment No." := AttachmentManagement.InsertAttachment(InteractionTmplLanguage."Attachment No.");
                SegInteractLanguage.Insert(true);
            until InteractionTmplLanguage.Next() = 0;
    end;

    local procedure CopyFromTemplate(InteractionTemplate: Record "Interaction Template")
    begin
        "Language Code (Default)" := InteractionTemplate."Language Code (Default)";
        "Interaction Group Code" := InteractionTemplate."Interaction Group Code";
        "Unit Cost (LCY)" := InteractionTemplate."Unit Cost (LCY)";
        "Unit Duration (Min.)" := InteractionTemplate."Unit Duration (Min.)";
        "Information Flow" := InteractionTemplate."Information Flow";
        "Initiated By" := InteractionTemplate."Initiated By";
        "Campaign Target" := InteractionTemplate."Campaign Target";
        "Campaign Response" := InteractionTemplate."Campaign Response";
        "Correspondence Type (Default)" := InteractionTemplate."Correspondence Type (Default)";
        "Ignore Contact Corres. Type" := InteractionTemplate."Ignore Contact Corres. Type";
        "Word Template Code" := InteractionTemplate."Word Template Code";

        UpdateSegLinesByFieldNo(FieldNo("Correspondence Type (Default)"), false);
        UpdateSegLinesByFieldNo(FieldNo("Language Code (Default)"), false);
        UpdateSegLinesByFieldNo(FieldNo("Word Template Code"), false);
    end;

    procedure UpdateSegLinesByFieldNo(ChangedFieldNo: Integer; AskQuestion: Boolean)
    var
        "Field": Record "Field";
        Question: Text[260];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSegLinesByFieldNo(Rec, ChangedFieldNo, AskQuestion, IsHandled);
        if IsHandled then
            exit;

        Field.Get(DATABASE::"Segment Header", ChangedFieldNo);

        if not SegLinesExist(Field."Field Caption") then begin
            if "No." <> '' then
                UpdateSegHeader("Interaction Template Code",
                  ChangedFieldNo = FieldNo("Interaction Template Code"));
            exit;
        end;

        if AskQuestion then begin
            if ChangedFieldNo = FieldNo("Interaction Template Code") then
                Question := StrSubstNo(Text012, Field."Field Caption", "Interaction Template Code")
            else
                Question := StrSubstNo(Text002, Field."Field Caption", "Interaction Template Code");
            if not Confirm(Question, true) then begin
                if ChangedFieldNo = FieldNo("Interaction Template Code") then begin
                    SegLine.SetRange("Segment No.", "No.");
                    if SegLine.Find('-') then
                        repeat
                            if SegLine.AttachmentInherited() then
                                Error(Text003, FieldCaption("Interaction Template Code"));
                        until SegLine.Next() = 0;
                end;
                UpdateSegHeader("Interaction Template Code",
                  ChangedFieldNo = FieldNo("Interaction Template Code"));
                exit;
            end;
        end;

        SegLine.Reset();
        SegLine.SetRange("Segment No.", "No.");
        if ChangedFieldNo <> FieldNo("Interaction Template Code") then
            SegLine.SetRange("Interaction Template Code", "Interaction Template Code");

        if not SegLine.IsEmpty() then
            case ChangedFieldNo of
                FieldNo(Description):
                    SegLine.ModifyAll(Description, Description);
                FieldNo("Campaign No."):
                    SegLine.ModifyAll("Campaign No.", "Campaign No.");
                FieldNo("Salesperson Code"):
                    SegLine.ModifyAll("Salesperson Code", "Salesperson Code");
                FieldNo("Correspondence Type (Default)"):
                    SegLine.ModifyAll("Correspondence Type", "Correspondence Type (Default)");
                FieldNo("Interaction Template Code"):
                    begin
                        SegLine.ModifyAll("Interaction Template Code", "Interaction Template Code");

                        UpdateSegHeader("Interaction Template Code", true);
                    end;
                FieldNo("Unit Cost (LCY)"):
                    SegLine.ModifyAll("Cost (LCY)", "Unit Cost (LCY)");
                FieldNo("Unit Duration (Min.)"):
                    SegLine.ModifyAll("Duration (Min.)", "Unit Duration (Min.)");
                FieldNo(Date):
                    SegLine.ModifyAll(Date, Date);
                FieldNo("Campaign Target"):
                    SegLine.ModifyAll("Campaign Target", "Campaign Target");
                FieldNo("Information Flow"):
                    SegLine.ModifyAll("Information Flow", "Information Flow");
                FieldNo("Initiated By"):
                    SegLine.ModifyAll("Initiated By", "Initiated By");
                FieldNo("Campaign Response"):
                    SegLine.ModifyAll("Campaign Response", "Campaign Response");
                FieldNo("Interaction Group Code"):
                    SegLine.ModifyAll("Interaction Group Code", "Interaction Group Code");
                FieldNo("Send Word Docs. as Attmt."):
                    SegLine.ModifyAll("Send Word Doc. As Attmt.", "Send Word Docs. as Attmt.");
                FieldNo("Attachment No."):
                    SegLine.ModifyAll("Attachment No.", "Attachment No.");
                FieldNo("Word Template Code"):
                    SegLine.ModifyAll("Word Template Code", "Word Template Code");
            end;

        OnAfterUpdateSegLinesByFieldNo(Rec, ChangedFieldNo);
    end;

    procedure SegLinesExist(ChangedFieldName: Text[100]): Boolean
    begin
        SegLine.Reset();
        SegLine.SetRange("Segment No.", "No.");
        if ChangedFieldName <> FieldCaption("Interaction Template Code") then
            SegLine.SetRange("Interaction Template Code", "Interaction Template Code");
        exit(SegLine.Find('-'));
    end;

    procedure ReuseLogged(LoggedSegEntryNo: Integer)
    var
        LoggedSeg: Record "Logged Segment";
        InteractLogEntry: Record "Interaction Log Entry";
        SegmentLine: Record "Segment Line";
        NextLineNo: Integer;
    begin
        if LoggedSegEntryNo = 0 then begin
            CalcFields("No. of Criteria Actions");
            if "No. of Criteria Actions" <> 0 then
                if not Confirm(
                     Text005, false,
                     "No.", "No. of Criteria Actions", FieldCaption("No. of Criteria Actions"), LoggedSeg.TableCaption())
                then
                    exit;
            if PAGE.RunModal(PAGE::"Logged Segments", LoggedSeg) <> ACTION::LookupOK then
                exit;
        end else
            LoggedSeg.Get(LoggedSegEntryNo);

        SegmentLine.LockTable();
        SegmentLine.SetRange("Segment No.", "No.");
        if SegmentLine.FindLast() then
            NextLineNo := SegmentLine."Line No.";

        Clear(SegCriteriaManagement);
        SegCriteriaManagement.InsertReuseLogged("No.", LoggedSeg."Entry No.");

        InteractLogEntry.SetCurrentKey("Logged Segment Entry No.");
        InteractLogEntry.SetRange("Logged Segment Entry No.", LoggedSeg."Entry No.");
        if InteractLogEntry.Find('-') then
            repeat
                NextLineNo := NextLineNo + 10000;
                InsertSegmentLine(SegmentLine, InteractLogEntry, NextLineNo);
                SegHistMgt.InsertLine("No.", SegmentLine."Contact No.", SegmentLine."Line No.");
            until InteractLogEntry.Next() = 0;

        OnAfterReuseLogged(Rec, LoggedSeg);
    end;

    procedure ReuseCriteria()
    var
        SavedSegCriteria: Record "Saved Segment Criteria";
        SavedSegCriteriaLineAction: Record "Saved Segment Criteria Line";
        SavedSegCriteriaLineFilter: Record "Saved Segment Criteria Line";
        Cont: Record Contact;
        ContProfileAnswer: Record "Contact Profile Answer";
        ContMailingGrp: Record "Contact Mailing Group";
        InteractLogEntry: Record "Interaction Log Entry";
        ContJobResp: Record "Contact Job Responsibility";
        ContIndustGrp: Record "Contact Industry Group";
        ContBusRel: Record "Contact Business Relation";
        ValueEntry: Record "Value Entry";
        AddContacts: Report "Add Contacts";
        ReduceContacts: Report "Remove Contacts - Reduce";
        RefineContacts: Report "Remove Contacts - Refine";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReuseCriteria(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcFields("No. of Criteria Actions");
        if "No. of Criteria Actions" <> 0 then
            if not Confirm(
                 Text006, false,
                 "No.", "No. of Criteria Actions", FieldCaption("No. of Criteria Actions"), SavedSegCriteria.TableCaption())
            then
                exit;

        if PAGE.RunModal(PAGE::"Saved Segment Criteria List", SavedSegCriteria) <> ACTION::LookupOK then
            exit;

        SavedSegCriteriaLineAction.SetRange("Segment Criteria Code", SavedSegCriteria.Code);
        SavedSegCriteriaLineAction.SetRange(Type, SavedSegCriteriaLineAction.Type::Action);
        if SavedSegCriteriaLineAction.Find('-') then
            repeat
                SegHeader.SetRange("No.", "No.");
                Cont.Reset();
                ContProfileAnswer.Reset();
                ContMailingGrp.Reset();
                InteractLogEntry.Reset();
                ContJobResp.Reset();
                ContIndustGrp.Reset();
                ContBusRel.Reset();
                ValueEntry.Reset();
                SavedSegCriteriaLineFilter.SetRange("Segment Criteria Code", SavedSegCriteria.Code);
                SavedSegCriteriaLineFilter.SetRange(
                  "Line No.", SavedSegCriteriaLineAction."Line No." + 1,
                  SavedSegCriteriaLineAction."Line No." + SavedSegCriteriaLineAction."No. of Filters");
                if SavedSegCriteriaLineFilter.Find('-') then
                    repeat
                        case SavedSegCriteriaLineFilter."Table No." of
                            DATABASE::Contact:
                                Cont.SetView(SavedSegCriteriaLineFilter."Table View");
                            DATABASE::"Contact Profile Answer":
                                ContProfileAnswer.SetView(SavedSegCriteriaLineFilter."Table View");
                            DATABASE::"Contact Mailing Group":
                                ContMailingGrp.SetView(SavedSegCriteriaLineFilter."Table View");
                            DATABASE::"Interaction Log Entry":
                                InteractLogEntry.SetView(SavedSegCriteriaLineFilter."Table View");
                            DATABASE::"Contact Job Responsibility":
                                ContJobResp.SetView(SavedSegCriteriaLineFilter."Table View");
                            DATABASE::"Contact Industry Group":
                                ContIndustGrp.SetView(SavedSegCriteriaLineFilter."Table View");
                            DATABASE::"Contact Business Relation":
                                ContBusRel.SetView(SavedSegCriteriaLineFilter."Table View");
                            DATABASE::"Value Entry":
                                ValueEntry.SetView(SavedSegCriteriaLineFilter."Table View");
                        end;
                    until SavedSegCriteriaLineFilter.Next() = 0;
                case SavedSegCriteriaLineAction.Action of
                    SavedSegCriteriaLineAction.Action::"Add Contacts":
                        begin
                            Clear(AddContacts);
                            AddContacts.SetTableView(SegHeader);
                            AddContacts.SetTableView(Cont);
                            AddContacts.SetTableView(ContProfileAnswer);
                            AddContacts.SetTableView(ContMailingGrp);
                            AddContacts.SetTableView(InteractLogEntry);
                            AddContacts.SetTableView(ContJobResp);
                            AddContacts.SetTableView(ContIndustGrp);
                            AddContacts.SetTableView(ContBusRel);
                            AddContacts.SetTableView(ValueEntry);
                            AddContacts.SetOptions(
                              SavedSegCriteriaLineAction."Allow Existing Contacts",
                              SavedSegCriteriaLineAction."Expand Contact",
                              SavedSegCriteriaLineAction."Allow Company with Persons",
                              SavedSegCriteriaLineAction."Ignore Exclusion");
                            AddContacts.UseRequestPage(false);
                            OnReuseContactsOnBeforeAddContactsRun(AddContacts, SavedSegCriteriaLineAction);
                            AddContacts.RunModal();
                        end;
                    SavedSegCriteriaLineAction.Action::"Remove Contacts (Reduce)":
                        begin
                            Clear(ReduceContacts);
                            ReduceContacts.SetTableView(SegHeader);
                            ReduceContacts.SetTableView(Cont);
                            ReduceContacts.SetTableView(ContProfileAnswer);
                            ReduceContacts.SetTableView(ContMailingGrp);
                            ReduceContacts.SetTableView(InteractLogEntry);
                            ReduceContacts.SetTableView(ContJobResp);
                            ReduceContacts.SetTableView(ContIndustGrp);
                            ReduceContacts.SetTableView(ContBusRel);
                            ReduceContacts.SetTableView(ValueEntry);
                            ReduceContacts.SetOptions(SavedSegCriteriaLineAction."Entire Companies");
                            ReduceContacts.UseRequestPage(false);
                            OnReuseContactsOnBeforeReduceContactsRun(ReduceContacts, SavedSegCriteriaLineAction);
                            ReduceContacts.RunModal();
                        end;
                    SavedSegCriteriaLineAction.Action::"Remove Contacts (Refine)":
                        begin
                            Clear(RefineContacts);
                            RefineContacts.SetTableView(SegHeader);
                            RefineContacts.SetTableView(Cont);
                            RefineContacts.SetTableView(ContProfileAnswer);
                            RefineContacts.SetTableView(ContMailingGrp);
                            RefineContacts.SetTableView(InteractLogEntry);
                            RefineContacts.SetTableView(ContJobResp);
                            RefineContacts.SetTableView(ContIndustGrp);
                            RefineContacts.SetTableView(ContBusRel);
                            RefineContacts.SetTableView(ValueEntry);
                            ReduceContacts.SetOptions(SavedSegCriteriaLineAction."Entire Companies");
                            RefineContacts.UseRequestPage(false);
                            OnReuseContactsOnBeforeRefineContactsRun(RefineContacts, SavedSegCriteriaLineAction);
                            RefineContacts.RunModal();
                        end;
                    else
                        OnReuseCriteriaSavedSegmentCriteriaLineCaseElse(SegHeader, SavedSegCriteriaLineAction);
                end;
            until SavedSegCriteriaLineAction.Next() = 0;
    end;

    procedure SaveCriteria()
    var
        SegCriteriaLine: Record "Segment Criteria Line";
        SavedSegCriteria: Record "Saved Segment Criteria";
        SavedSegCriteriaLine: Record "Saved Segment Criteria Line";
        SaveSegCriteria: Page "Save Segment Criteria";
        FormAction: Action;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveCriteria(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcFields("No. of Criteria Actions");
        TestField("No. of Criteria Actions");
        SaveSegCriteria.RunModal();
        SaveSegCriteria.GetValues(FormAction, SavedSegCriteria.Code, SavedSegCriteria.Description);
        if FormAction = ACTION::OK then begin
            SavedSegCriteria.Insert(true);
            SegCriteriaLine.SetRange("Segment No.", "No.");
            SegCriteriaLine.Find('-');
            repeat
                SavedSegCriteriaLine.Init();
                SavedSegCriteriaLine."Segment Criteria Code" := SavedSegCriteria.Code;
                SavedSegCriteriaLine."Line No." := SegCriteriaLine."Line No.";
                SavedSegCriteriaLine.Action := SegCriteriaLine.Action;
                SavedSegCriteriaLine.Type := SegCriteriaLine.Type;
                SavedSegCriteriaLine."Table No." := SegCriteriaLine."Table No.";
                SavedSegCriteriaLine."Table View" := SegCriteriaLine."Table View";
                SavedSegCriteriaLine."Allow Existing Contacts" := SegCriteriaLine."Allow Existing Contacts";
                SavedSegCriteriaLine."Expand Contact" := SegCriteriaLine."Expand Contact";
                SavedSegCriteriaLine."Allow Company with Persons" := SegCriteriaLine."Allow Company with Persons";
                SavedSegCriteriaLine."Ignore Exclusion" := SegCriteriaLine."Ignore Exclusion";
                SavedSegCriteriaLine."Entire Companies" := SegCriteriaLine."Entire Companies";
                SavedSegCriteriaLine."No. of Filters" := SegCriteriaLine."No. of Filters";
                OnSaveCriteriaOnBeforeInsertSegmentCriteriaLine(SegCriteriaLine, SavedSegCriteriaLine);
                SavedSegCriteriaLine.Insert();
            until SegCriteriaLine.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure MaintainAttachment()
    begin
        if "Interaction Template Code" = '' then
            exit;

        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if "Attachment No." <> 0 then
            OpenAttachment()
        else begin
            CreateAttachment();
            CalcFields("Attachment No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if not SegmentInteractionLanguage.Get("No.", 0, "Language Code (Default)") then begin
            SegmentInteractionLanguage.Init();
            SegmentInteractionLanguage."Segment No." := "No.";
            SegmentInteractionLanguage."Segment Line No." := 0;
            SegmentInteractionLanguage."Language Code" := "Language Code (Default)";
            SegmentInteractionLanguage.Description := Format("Interaction Template Code") + ' ' + Format("Language Code (Default)");
            SegmentInteractionLanguage.Subject := "Subject (Default)";
        end;
        SegmentInteractionLanguage.CreateAttachment();
    end;

    internal procedure CreateWordTemplateAttachment()
    var
        Attachment: Record Attachment;
        WordTemplate: Record "Word Template";
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        CalcFields("Modified Word Template");

        if "Modified Word Template" <> 0 then begin
            if not Dialog.Confirm(ModifyExistingWordTemplateMsg, true) then begin
                WordTemplate.Get(Rec."Word Template Code");
                Attachment.Get("Modified Word Template");
                Attachment."Attachment File".CreateOutStream(OutStream);
                WordTemplate.Template.ExportStream(OutStream);
                Attachment.Modify();
            end;

            ModifyWordTemplateAttachment();
        end else begin
            if not SegmentInteractionLanguage.Get("No.", 0, "Language Code (Default)") then begin
                SegmentInteractionLanguage.Init();
                SegmentInteractionLanguage."Segment No." := "No.";
                SegmentInteractionLanguage."Segment Line No." := 0;
                SegmentInteractionLanguage."Language Code" := "Language Code (Default)";
                SegmentInteractionLanguage.Description := Format("Interaction Template Code") + ' ' + Format("Language Code (Default)");
                SegmentInteractionLanguage.Subject := "Subject (Default)";
                SegmentInteractionLanguage."Word Template Code" := "Word Template Code";
            end;

            WordTemplate.Get(Rec."Word Template Code");
            TempBlob.CreateOutStream(OutStream);
            WordTemplate.Template.ExportStream(OutStream);
            SegmentInteractionLanguage."Word Template Code" := Rec."Word Template Code";
            SegmentInteractionLanguage.CreateWordTemplateAttachment(TempBlob, TempTemplateFileNameLbl + TempTemplateExtensionLbl);
            CalcFields("Modified Word Template");

            if "Modified Word Template" <> 0 then
                ModifyWordTemplateAttachment();
        end;
    end;

    local procedure ModifyWordTemplateAttachment()
    var
        Attachment: Record Attachment;
        DocumentServiceManagement: Codeunit "Document Service Management";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        Attachment.Get("Modified Word Template");
        Attachment.CalcFields("Attachment File");
        Attachment."Attachment File".CreateInStream(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        if DocumentServiceManagement.EditInOneDrive(TempTemplateFileNameLbl + TempTemplateExtensionLbl, 'docx', Enum::"Doc. Sharing Conflict Behavior"::Replace, TempBlob) then begin
            Attachment."Attachment File".CreateOutStream(OutStream);
            TempBlob.CreateInStream(InStream);
            CopyStream(OutStream, InStream);
            Attachment.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if SegmentInteractionLanguage.Get("No.", 0, "Language Code (Default)") then
            if SegmentInteractionLanguage."Attachment No." <> 0 then
                SegmentInteractionLanguage.OpenAttachment();
    end;

    [Scope('OnPrem')]
    procedure ImportAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if not SegmentInteractionLanguage.Get("No.", 0, "Language Code (Default)") then begin
            SegmentInteractionLanguage.Init();
            SegmentInteractionLanguage."Segment No." := "No.";
            SegmentInteractionLanguage."Segment Line No." := 0;
            SegmentInteractionLanguage."Language Code" := "Language Code (Default)";
            SegmentInteractionLanguage.Description :=
              Format("Interaction Template Code") + ' ' + Format("Language Code (Default)");
            SegmentInteractionLanguage.Insert(true);
        end;
        SegmentInteractionLanguage.ImportAttachment();
    end;

    [Scope('OnPrem')]
    procedure ExportAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if SegmentInteractionLanguage.Get("No.", 0, "Language Code (Default)") then
            if SegmentInteractionLanguage."Attachment No." <> 0 then
                SegmentInteractionLanguage.ExportAttachment();
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachment(Prompt: Boolean)
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        if Rec."Word Template Code" <> '' then
            Error(WordTemplateUsedErr);

        if SegmentInteractionLanguage.Get("No.", 0, "Language Code (Default)") then
            if SegmentInteractionLanguage."Attachment No." <> 0 then
                SegmentInteractionLanguage.RemoveAttachment(Prompt);
    end;

    procedure UpdateSegHeader(InteractTmplCode: Code[10]; InteractTmplChange: Boolean)
    var
        InteractionTemplate: Record "Interaction Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSegHeader(Rec, InteractTmplCode, InteractTmplChange, IsHandled, CurrFieldNo);
        if not IsHandled then
            if InteractTmplChange then begin
                Modify();
                Get("No.");
                "Interaction Template Code" := InteractTmplCode;
                "Subject (Default)" := '';

                if InteractionTemplate.Get("Interaction Template Code") then begin
                    CopyFromTemplate(InteractionTemplate);
                    if (GetFilter("Campaign No.") = '') and (InteractionTemplate."Campaign No." <> '') then
                        "Campaign No." := InteractionTemplate."Campaign No.";

                    CreateSegInteractions("Interaction Template Code", "No.", 0);
                end else begin
                    CopyFromTemplate(InteractionTemplate);
                    if GetFilter("Campaign No.") = '' then
                        "Campaign No." := '';
                end;
                OnUpdateSegHeaderOnBeforeSecondModify(Rec);
                Modify();
                CalcFields("Attachment No.");
            end;
        OnAfterUpdateSegHeader(Rec);
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    local procedure InsertSegmentLine(var SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry"; LineNo: Integer)
    begin
        SegmentLine.Init();
        SegmentLine."Segment No." := "No.";
        SegmentLine."Line No." := LineNo;
        SegmentLine.Validate("Contact No.", InteractionLogEntry."Contact No.");
        SegmentLine."Campaign No." := InteractionLogEntry."Campaign No.";
        SegmentLine.Insert(true);

        OnAfterInsertSegmentLine(SegmentLine, InteractionLogEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReuseLogged(var SegmentHeader: Record "Segment Header"; LoggedSegment: Record "Logged Segment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSegHeader(var SegmentHeader: Record "Segment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSegLinesByFieldNo(var SegmentHeader: Record "Segment Header"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReuseCriteria(var SegmentHeader: Record "Segment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSegHeader(var SegmentHeader: Record "Segment Header"; InteractTmplCode: Code[10]; InteractTmplChange: Boolean; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSegLinesByFieldNo(SegmentHeader: Record "Segment Header"; ChangedFieldNo: Integer; var AskQuestion: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReuseCriteriaSavedSegmentCriteriaLineCaseElse(var SegmentHeader: Record "Segment Header"; var SavedSegmentCriteriaLine: Record "Saved Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSegmentLine(var SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveCriteria(var SegmentHeader: Record "Segment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReuseContactsOnBeforeAddContactsRun(var AddContacts: Report "Add Contacts"; var SavedSegCriteriaLineAction: Record "Saved Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReuseContactsOnBeforeReduceContactsRun(var ReduceContacts: Report "Remove Contacts - Reduce"; var SavedSegCriteriaLineAction: Record "Saved Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReuseContactsOnBeforeRefineContactsRun(var RefineContacts: Report "Remove Contacts - Refine"; var SavedSegCriteriaLineAction: Record "Saved Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSegHeaderOnBeforeSecondModify(var SegmentHeader: Record "Segment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSubjectDefault(var SegmentHeader: Record "Segment Header"; xSegmentHeader: Record "Segment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSegInteractionsOnAfterDeleteAll(InteractionTemplateCode: Code[10]; SegmentNo: Code[20]; SegmentLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveCriteriaOnBeforeInsertSegmentCriteriaLine(var SegmentCriteriaLine: Record "Segment Criteria Line"; var SavedSegmentCriteriaLine: Record "Saved Segment Criteria Line")
    begin
    end;
}
