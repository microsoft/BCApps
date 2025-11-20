// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using System.Globalization;
using System.Integration.Word;
using System.Utilities;

table 5104 "Segment Interaction Language"
{
    Caption = 'Segment Interaction Language';
    DataClassification = CustomerContent;
    LookupPageID = "Segment Interaction Languages";

    fields
    {
        field(1; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(2; "Segment Line No."; Integer)
        {
            Caption = 'Segment Line No.';
            TableRelation = "Segment Line"."Line No." where("Segment No." = field("Segment No."));
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
        }
        field(6; Subject; Text[100])
        {
            Caption = 'Subject';

            trigger OnValidate()
            var
                SegmentHeader: Record "Segment Header";
                SegLine: Record "Segment Line";
                UpdateLines: Boolean;
            begin
                SegmentHeader.Get("Segment No.");
                if "Segment Line No." = 0 then
                    if SegmentHeader.SegLinesExist('') then
                        UpdateLines := Confirm(StrSubstNo(UpdateSegmentLinesQst, FieldCaption(Subject)), true);

                if SegmentHeader."Language Code (Default)" = "Language Code" then
                    if SegmentHeader."Subject (Default)" = xRec.Subject then begin
                        SegmentHeader."Subject (Default)" := Subject;
                        SegmentHeader.Modify();
                        Modify();
                    end;

                if not UpdateLines then
                    exit;

                SegLine.SetRange("Segment No.", "Segment No.");
                if "Segment Line No." = 0 then
                    SegLine.SetRange("Interaction Template Code", SegmentHeader."Interaction Template Code")
                else begin
                    SegLine.Get("Segment No.", "Segment Line No.");
                    SegLine.SetRange("Interaction Template Code", SegLine."Interaction Template Code");
                end;
                SegLine.SetRange("Language Code", "Language Code");
                SegLine.SetRange(Subject, xRec.Subject);
                SegLine.ModifyAll(Subject, Subject);
            end;
        }
        field(7; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
            TableRelation = "Word Template".Code where("Table ID" = const(5106)); // Only Interaction Merge Data word templates are allowed
        }
    }

    keys
    {
        key(Key1; "Segment No.", "Segment Line No.", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        SegmentHeader.Get(Rec."Segment No.");
        if (Rec."Segment Line No." = 0) and
           (Rec."Language Code" = SegmentHeader."Language Code (Default)")
        then begin
            SegmentInteractionLanguage.SetRange("Segment No.", Rec."Segment No.");
            SegmentInteractionLanguage.SetRange("Segment Line No.", 0);
            SegmentInteractionLanguage.SetFilter("Language Code", '<>%1', Rec."Language Code");
            if SegmentInteractionLanguage.FindFirst() then begin
                SegmentHeader."Language Code (Default)" := SegmentInteractionLanguage."Language Code";
                SegmentHeader."Subject (Default)" := SegmentInteractionLanguage.Subject;
            end else begin
                SegmentHeader."Language Code (Default)" := '';
                SegmentHeader."Subject (Default)" := '';
            end;
            SegmentHeader.Modify();
        end;
        SegmentHeader.CalcFields("Attachment No.");

        if Rec."Segment Line No." = 0 then begin
            SegmentLine.SetRange("Segment No.", Rec."Segment No.");
            SegmentLine.SetRange("Attachment No.", Rec."Attachment No.");
            if SegmentLine.Find('-') then
                repeat
                    if Contact.Get(SegmentLine."Contact No.") then begin
                        if (Contact."Language Code" <> "Language Code") and
                           SegmentInteractionLanguage.Get("Segment No.", 0, Contact."Language Code")
                        then begin
                            SegmentLine."Language Code" := Contact."Language Code";
                            SegmentLine.Subject := SegmentInteractionLanguage.Subject;
                            SegmentLine."Attachment No." := SegmentInteractionLanguage."Attachment No.";
                            SegmentLine."Word Template Code" := SegmentInteractionLanguage."Word Template Code";
                        end else begin
                            SegmentLine."Language Code" := SegmentHeader."Language Code (Default)";
                            SegmentLine.Subject := SegmentHeader."Subject (Default)";
                            SegmentLine."Attachment No." := SegmentHeader."Attachment No.";
                            SegmentLine."Word Template Code" := SegmentHeader."Word Template Code";
                        end;
                        SegmentLine.Modify();
                    end;
                until SegmentLine.Next() = 0;
        end else begin // UNIQUE Attachment
            SegmentLine.Get("Segment No.", Rec."Segment Line No.");
            if SegmentLine."Attachment No." = Rec."Attachment No." then begin
                SegmentInteractionLanguage.SetRange("Segment No.", Rec."Segment No.");
                SegmentInteractionLanguage.SetRange("Segment Line No.", Rec."Segment Line No.");
                SegmentInteractionLanguage.SetFilter("Language Code", '<>%1', Rec."Language Code");
                if SegmentInteractionLanguage.FindFirst() then begin
                    SegmentLine."Language Code" := SegmentInteractionLanguage."Language Code";
                    SegmentLine.Subject := SegmentInteractionLanguage.Subject;
                    SegmentLine."Attachment No." := SegmentInteractionLanguage."Attachment No.";
                    SegmentLine."Word Template Code" := SegmentInteractionLanguage."Word Template Code";
                end else
                    if SegmentLine."Interaction Template Code" = SegmentHeader."Interaction Template Code" then begin
                        Contact.Get(SegmentLine."Contact No.");
                        if SegmentInteractionLanguage.Get("Segment No.", 0, Contact."Language Code") then begin
                            SegmentLine."Language Code" := Contact."Language Code";
                            SegmentLine.Subject := SegmentInteractionLanguage.Subject;
                            SegmentLine."Attachment No." := SegmentInteractionLanguage."Attachment No.";
                            SegmentLine."Word Template Code" := SegmentInteractionLanguage."Word Template Code";
                        end else begin
                            SegmentLine."Language Code" := SegmentHeader."Language Code (Default)";
                            SegmentLine.Subject := SegmentHeader."Subject (Default)";
                            SegmentLine."Attachment No." := SegmentHeader."Attachment No.";
                            SegmentLine."Word Template Code" := SegmentHeader."Word Template Code";
                        end;
                    end else begin
                        SegmentLine."Language Code" := '';
                        SegmentLine.Subject := '';
                        SegmentLine."Attachment No." := 0;
                        SegmentLine."Word Template Code" := '';
                    end;
                SegmentLine.Modify();
            end;
        end;

        RemoveAttachment(false);
    end;

    trigger OnInsert()
    var
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        FirstSegIntLanguage: Boolean;
    begin
        if Rec."Segment Line No." = 0 then begin
            SegmentInteractionLanguage.SetRange("Segment No.", Rec."Segment No.");
            SegmentInteractionLanguage.SetRange("Segment Line No.", 0);
            FirstSegIntLanguage := SegmentInteractionLanguage.IsEmpty();

            SegmentLine.SetRange("Segment No.", Rec."Segment No.");
            SegmentHeader.Get(Rec."Segment No.");
            SegmentLine.SetRange("Interaction Template Code", SegmentHeader."Interaction Template Code");
            if SegmentLine.Find('-') then
                repeat
                    if FirstSegIntLanguage then begin
                        if SegmentLine.AttachmentInherited() or
                           (SegmentLine."Attachment No." = 0)
                        then begin
                            SegmentLine."Language Code" := Rec."Language Code";
                            SegmentLine.Subject := Rec.Subject;
                            SegmentLine."Attachment No." := Rec."Attachment No.";
                            SegmentLine."Word Template Code" := Rec."Word Template Code";
                            SegmentLine.Modify();
                        end
                    end else
                        if SegmentLine.AttachmentInherited() or (SegmentLine."Attachment No." = 0) then
                            if Contact.Get(SegmentLine."Contact No.") then
                                if Contact."Language Code" = "Language Code" then begin
                                    SegmentLine."Language Code" := Rec."Language Code";
                                    SegmentLine.Subject := Rec.Subject;
                                    SegmentLine."Attachment No." := Rec."Attachment No.";
                                    SegmentLine."Word Template Code" := Rec."Word Template Code";
                                    SegmentLine.Modify();
                                end;
                until SegmentLine.Next() = 0;
        end else begin
            SegmentLine.Get("Segment No.", Rec."Segment Line No.");
            SegmentLine."Language Code" := Rec."Language Code";
            SegmentLine.Subject := Rec.Subject;
            SegmentLine."Attachment No." := Rec."Attachment No.";
            SegmentLine."Word Template Code" := Rec."Word Template Code";
            SegmentLine.Modify();
        end;
    end;

    trigger OnRename()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        SegmentHeader.Get("Segment No.");
        SegmentHeader.CalcFields("Attachment No.");
        if (Rec."Segment Line No." = 0) and
           (SegmentHeader."Language Code (Default)" = xRec."Language Code")
        then begin
            SegmentHeader."Language Code (Default)" := Rec."Language Code";
            SegmentHeader.Modify();
        end;

        if Rec."Segment Line No." = 0 then begin
            SegmentLine.SetRange("Segment No.", Rec."Segment No.");
            SegmentLine.SetRange("Attachment No.", Rec."Attachment No.");
            if SegmentLine.Find('-') then
                repeat
                    SegmentLine."Language Code" := SegmentHeader."Language Code (Default)";
                    SegmentLine."Attachment No." := SegmentHeader."Attachment No.";
                    SegmentLine."Word Template Code" := SegmentHeader."Word Template Code";
                    SegmentLine.Modify();
                until SegmentLine.Next() = 0;

            SegmentLine.Reset();
            SegmentLine.SetRange("Segment No.", Rec."Segment No.");
            SegmentLine.SetRange("Interaction Template Code", SegmentHeader."Interaction Template Code");
            if SegmentLine.Find('-') then
                repeat
                    if SegmentLine.AttachmentInherited() or (SegmentLine."Attachment No." = 0) then
                        if Contact.Get(SegmentLine."Contact No.") then
                            if Contact."Language Code" = Rec."Language Code" then begin
                                SegmentLine."Language Code" := Rec."Language Code";
                                SegmentLine.Subject := Rec.Subject;
                                SegmentLine."Attachment No." := Rec."Attachment No.";
                                SegmentLine."Word Template Code" := Rec."Word Template Code";
                                SegmentLine.Modify();
                            end;
                until SegmentLine.Next() = 0;
        end else begin
            SegmentLine.Get(Rec."Segment No.", Rec."Segment Line No.");
            if SegmentLine."Language Code" = xRec."Language Code" then begin
                SegmentLine."Language Code" := Rec."Language Code";
                SegmentLine."Attachment No." := Rec."Attachment No.";
                SegmentLine."Word Template Code" := Rec."Word Template Code";
                SegmentLine.Modify();
            end;
        end;
    end;

    var
        CreateProcessCanceledLbl: Label 'You have canceled the create process.';
        ReplaceExistingAttachmentQst: Label 'Replace existing attachment?';
        ImportFailedMsg: Label 'The import was canceled or the specified file could not be accessed. The import failed.';
        InheritedLbl: Label 'Inherited';
        UniqueLbl: Label 'Unique';
        UpdateSegmentLinesQst: Label 'You have modified %1.\\Do you want to update the segment lines with the same Interaction Template Code and Language Code?', Comment = '%1 = Subject caption';

    [Scope('OnPrem')]
    procedure CreateAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        Attachment: Record Attachment;
        NewAttachmentNo: Integer;
    begin
        if "Attachment No." <> 0 then begin
            if not Confirm(ReplaceExistingAttachmentQst, false) then
                exit;
            RemoveAttachment(false);
        end;

        if GuiAllowed() then
            if Attachment.ImportAttachmentFromClientFile('', false, true) then
                NewAttachmentNo := Attachment."No.";

        if NewAttachmentNo <> 0 then begin
            "Attachment No." := NewAttachmentNo;
            if SegmentInteractionLanguage.Get("Segment No.", "Segment Line No.", "Language Code") then
                Modify()
            else
                Insert(true);
            UpdateSegLineAttachment(0);
        end else
            Error(CreateProcessCanceledLbl);
    end;

    internal procedure CreateWordTemplateAttachment(var TempBlob: Codeunit "Temp Blob"; FileName: Text)
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        Attachment: Record Attachment;
        NewAttachmentNo: Integer;
        InStream: InStream;
    begin
        if "Attachment No." <> 0 then begin
            if not Confirm(ReplaceExistingAttachmentQst, false) then
                exit;
            RemoveAttachment(false);
        end;

        if GuiAllowed() then begin
            TempBlob.CreateInStream(InStream);
            NewAttachmentNo := Attachment.ImportAttachmentFromStream(InStream, FileName);
        end;

        if NewAttachmentNo <> 0 then begin
            "Attachment No." := NewAttachmentNo;
            if SegmentInteractionLanguage.Get("Segment No.", "Segment Line No.", "Language Code") then
                Modify()
            else
                Insert(true);
            UpdateSegLineWordTemplateAttachment(NewAttachmentNo);
        end else
            Error(CreateProcessCanceledLbl);
    end;

    [Scope('OnPrem')]
    procedure OpenAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." = 0 then
            exit;
        Attachment.Get("Attachment No.");
        Attachment.OpenAttachment("Segment No." + ' ' + Description, false, "Language Code");
    end;

    [Scope('OnPrem')]
    procedure CopyFromAttachment()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        AttachmentManagement: Codeunit AttachmentManagement;
        NewAttachNo: Integer;
    begin
        if "Attachment No." <> 0 then begin
            if not Confirm(ReplaceExistingAttachmentQst, false) then
                exit;
            RemoveAttachment(false);
            Commit();
        end;

        SegmentInteractionLanguage.SetRange("Segment No.", "Segment No.");
        SegmentInteractionLanguage.SetFilter("Attachment No.", '<>%1&<>%2', 0, "Attachment No.");
        if PAGE.RunModal(0, SegmentInteractionLanguage) = ACTION::LookupOK then begin
            NewAttachNo := AttachmentManagement.InsertAttachment(SegmentInteractionLanguage."Attachment No.");
            if NewAttachNo <> 0 then begin
                "Attachment No." := NewAttachNo;
                Modify();
                UpdateSegLineAttachment(0);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." <> 0 then begin
            if not Confirm(ReplaceExistingAttachmentQst, false) then
                exit;
            RemoveAttachment(false);
        end;

        if Attachment.ImportAttachmentFromClientFile('', false, false) then begin
            "Attachment No." := Attachment."No.";
            Modify();
            UpdateSegLineAttachment(0);
        end else
            Error(ImportFailedMsg);
    end;

    [Scope('OnPrem')]
    procedure ExportAttachment()
    var
        Attachment: Record Attachment;
        FileName: Text[1024];
    begin
        if Attachment.Get("Attachment No.") then begin
            if Attachment."Storage Type" = Attachment."Storage Type"::Embedded then
                Attachment.CalcFields("Attachment File");
            Attachment.ExportAttachmentToClientFile(FileName);
        end;
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachment(Prompt: Boolean)
    var
        Attachment: Record Attachment;
        OldAttachmentNo: Integer;
    begin
        OldAttachmentNo := "Attachment No.";
        if Attachment.Get("Attachment No.") and (not Attachment."Read Only") then
            if Attachment.RemoveAttachment(Prompt) then begin
                "Attachment No." := 0;
                Modify();
            end;
        UpdateSegLineAttachment(OldAttachmentNo);
    end;

    local procedure UpdateSegLineAttachment(OldAttachmentNo: Integer)
    var
        SegmentLine: Record "Segment Line";
        SegmentHeader: Record "Segment Header";
    begin
        if "Segment Line No." = 0 then begin
            SegmentHeader.Get("Segment No.");
            SegmentLine.SetRange("Segment No.", "Segment No.");
            SegmentLine.SetRange("Interaction Template Code", SegmentHeader."Interaction Template Code");
            SegmentLine.SetRange("Language Code", "Language Code");
            SegmentLine.SetRange("Attachment No.", OldAttachmentNo);
            SegmentLine.ModifyAll("Attachment No.", "Attachment No.");
        end else begin
            SegmentLine.SetRange("Segment No.", "Segment No.");
            SegmentLine.SetRange("Line No.", "Segment Line No.");
            SegmentLine.SetRange("Attachment No.", OldAttachmentNo);
            if SegmentLine.FindFirst() then begin
                SegmentLine."Attachment No." := "Attachment No.";
                SegmentLine.Modify();
            end;
        end;
    end;

    local procedure UpdateSegLineWordTemplateAttachment(AttachmentNo: Integer)
    var
        SegmentHeader: Record "Segment Header";
    begin
        SegmentHeader.Get("Segment No.");
        SegmentHeader."Modified Word Template" := AttachmentNo;
        SegmentHeader.Modify();
    end;

    procedure AttachmentText(): Text[30]
    begin
        if "Attachment No." = 0 then
            exit('');

        if "Segment Line No." = 0 then
            exit(InheritedLbl);

        exit(UniqueLbl);
    end;

    procedure Caption() CaptionText: Text
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        SegmentHeader.Get("Segment No.");
        CaptionText := Format("Segment No.") + ' ' + SegmentHeader.Description;
        if "Segment Line No." <> 0 then begin
            SegmentLine.Get("Segment No.", "Segment Line No.");
            if Contact.Get(SegmentLine."Contact No.") then;
            CaptionText := CaptionText + ' ' + Format(SegmentLine."Contact No.") + ' ' + Contact.Name;
        end;
    end;
}

