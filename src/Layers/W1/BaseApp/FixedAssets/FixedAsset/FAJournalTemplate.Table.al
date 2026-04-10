// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Reports;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using System.Reflection;

table 5619 "FA Journal Template"
{
    Caption = 'FA Journal Template';
    LookupPageID = "FA Journal Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the journal template you are creating.';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the journal template you are creating.';
        }
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            ToolTip = 'Specifies the report that will be printed if you choose to print a test report from a journal batch.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if Recurring then
                    "Page ID" := PAGE::"Recurring Fixed Asset Journal"
                else
                    if "Page ID" = 0 then
                        "Page ID" := PAGE::"Fixed Asset Journal";
                "Test Report ID" := REPORT::"Fixed Asset Journal - Test";
                "Posting Report ID" := REPORT::"Fixed Asset Register";
                "Maint. Posting Report ID" := REPORT::"Maintenance Register";
                SourceCodeSetup.Get();
                "Source Code" := SourceCodeSetup."Fixed Asset Journal";
            end;
        }
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            ToolTip = 'Specifies the report that is printed when you click Post and Print from a journal batch.';
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
                FAJnlLine.SetRange("Journal Template Name", Name);
                FAJnlLine.ModifyAll("Source Code", "Source Code");
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
            ToolTip = 'Specifies whether the journal template will be a recurring journal.';

            trigger OnValidate()
            begin
                if not Recurring then
                    "Page ID" := 0;
                Validate("Page ID");
                if Recurring then
                    TestField("No. Series", '');
            end;
        }
        field(13; "Test Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Test Report ID")));
            Caption = 'Test Report Caption';
            ToolTip = 'Specifies the name of the report that is specified in the Test Report ID field.';
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
            ToolTip = 'Specifies the name of the report that is specified in the Posting Report ID field.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Maint. Posting Report ID"; Integer)
        {
            Caption = 'Maint. Posting Report ID';
            ToolTip = 'Specifies the report that is printed when you post a journal line, where the FA Posting Type field = Maintenance, by clicking Post and Print.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(17; "Maint. Posting Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Maint. Posting Report ID")));
            Caption = 'Maint. Posting Report Caption';
            ToolTip = 'Specifies the name of the report that is specified in the Maint. Posting Report ID field.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "No. Series"; Code[20])
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
        field(19; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            ToolTip = 'Specifies the code for the number series used to assign document numbers to ledger entries posted from journals.';
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
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        FAJnlLine.SetRange("Journal Template Name", Name);
        FAJnlLine.DeleteAll(true);
        FAJnlBatch.SetRange("Journal Template Name", Name);
        FAJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        FAJnlLine: Record "FA Journal Line";
        FAJnlBatch: Record "FA Journal Batch";
        SourceCodeSetup: Record "Source Code Setup";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

