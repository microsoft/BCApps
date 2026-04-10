// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Reports;
using System.Reflection;

table 209 "Job Journal Template"
{
    Caption = 'Project Journal Template';
    DrillDownPageID = "Job Journal Template List";
    LookupPageID = "Job Journal Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of this journal template. You can enter a maximum of 10 characters, both numbers and letters.';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the project journal template for easy identification.';
        }
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            ToolTip = 'Specifies the test report that is printed when you create a Test Report.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Recurring);
            end;
        }
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            ToolTip = 'Specifies the posting report you want to be associated with this journal. To see the available IDs, choose the field.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(8; "Force Posting Report"; Boolean)
        {
            Caption = 'Force Posting Report';
            ToolTip = 'Specifies whether a report is printed automatically when you post.';
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                JobJnlLine.SetRange("Journal Template Name", Name);
                JobJnlLine.ModifyAll("Source Code", "Source Code");
                Modify();
            end;
        }
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(12; Recurring; Boolean)
        {
            Caption = 'Recurring';
            ToolTip = 'Specifies whether the journal is to contain recurring entries. Leave the field blank if the journal should not contain recurring entries.';

            trigger OnValidate()
            begin
                if Recurring then
                    "Page ID" := PAGE::"Recurring Job Jnl."
                else
                    "Page ID" := PAGE::"Job Journal";
                "Test Report ID" := REPORT::"Job Journal - Test";
                "Posting Report ID" := 1015; // REPORT::"Job Register";
                SourceCodeSetup.Get();
                "Source Code" := SourceCodeSetup."Job Journal";
                if Recurring then
                    TestField("No. Series", '');
            end;
        }
        field(13; "Test Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Test Report ID")));
            Caption = 'Test Report Caption';
            ToolTip = 'Specifies the name of the test report that you selected in the Test Report ID field.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Posting Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Posting Report ID")));
            Caption = 'Posting Report Caption';
            ToolTip = 'Specifies the name of the posting report that is printed when you print the project journal.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then begin
                    if Recurring then
                        Error(
                          Text000,
                          FieldCaption("Posting No. Series"));
                    if "No. Series" = "Posting No. Series" then
                        "Posting No. Series" := '';
                end;
            end;
        }
        field(17; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            ToolTip = 'Specifies the code for the number series that will be used to assign document numbers to ledger entries that are posted from journals using this template.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001, "Posting No. Series"));
            end;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
            ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
        key(Key2; "Page ID", Recurring)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        JobJnlLine.SetRange("Journal Template Name", Name);
        JobJnlLine.DeleteAll(true);
        JobJnlBatch.SetRange("Journal Template Name", Name);
        JobJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    trigger OnRename()
    begin
        ReservEngineMgt.RenamePointer(DATABASE::"Job Journal Line",
          0, xRec.Name, '', 0, 0,
          0, Name, '', 0, 0);
    end;

    var
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlLine: Record "Job Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

