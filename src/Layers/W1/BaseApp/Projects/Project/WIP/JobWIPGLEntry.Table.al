// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Projects.Project.Job;
using Microsoft.Utilities;

table 1005 "Job WIP G/L Entry"
{
    Caption = 'Project WIP G/L Entry';
    DrillDownPageID = "Job WIP G/L Entries";
    LookupPageID = "Job WIP G/L Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            TableRelation = Job;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number you entered in the Document No. field on the Options FastTab in the Project Post WIP to G/L batch job.';
        }
        field(4; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            ToolTip = 'Specifies the general ledger account number to which the WIP, on this entry, is posted.';
            TableRelation = "G/L Account";
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date you entered in the Posting Date field, on the Options FastTab, in the Project Post WIP to G/L batch job.';
        }
        field(6; "WIP Entry Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'WIP Entry Amount';
            ToolTip = 'Specifies the WIP amount that was posted in the general ledger for this entry.';
        }
        field(7; "Job Posting Group"; Code[20])
        {
            Caption = 'Project Posting Group';
            ToolTip = 'Specifies the posting group related to this entry.';
            TableRelation = "Job Posting Group";
        }
        field(8; Type; Enum "Job WIP Buffer Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the WIP type for this entry.';
        }
        field(9; "G/L Bal. Account No."; Code[20])
        {
            Caption = 'G/L Bal. Account No.';
            ToolTip = 'Specifies the general ledger balancing account number that WIP on this entry was posted to.';
            TableRelation = "G/L Account";
        }
        field(10; "WIP Method Used"; Code[20])
        {
            Caption = 'WIP Method Used';
            ToolTip = 'Specifies the WIP method that was specified for the project when you ran the Project Calculate WIP batch job.';
            Editable = false;
            TableRelation = "Job WIP Method";
        }
        field(11; "WIP Posting Method Used"; Option)
        {
            Caption = 'WIP Posting Method Used';
            ToolTip = 'Specifies the WIP posting method used in the context of the general ledger. The information in this field comes from the setting you have specified on the project card.';
            OptionCaption = 'Per Project,Per Project Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
        }
        field(12; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
            ToolTip = 'Specifies the posting date you entered in the Posting Date field, on the Options FastTab, in the Project Calculate WIP batch job.';
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "G/L Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'G/L Entry No.';
            ToolTip = 'Specifies the G/L Entry No. to which this entry is linked.';
            TableRelation = "G/L Entry";
        }
        field(15; Reversed; Boolean)
        {
            Caption = 'Reversed';
            ToolTip = 'Specifies whether the entry has been reversed. If the check box is selected, the entry has been reversed from the G/L.';
        }
        field(16; Reverse; Boolean)
        {
            Caption = 'Reverse';
            ToolTip = 'Specifies whether the entry has been part of a reverse transaction (correction) made by the reverse function.';
            InitValue = true;
        }
        field(17; "WIP Transaction No."; Integer)
        {
            Caption = 'WIP Transaction No.';
            ToolTip = 'Specifies the transaction number assigned to all the entries involved in the same transaction.';
        }
        field(18; "Reverse Date"; Date)
        {
            Caption = 'Reverse Date';
            ToolTip = 'Specifies the reverse date. If the WIP on this entry is reversed, you can see the date of the reversal in the Reverse Date field.';
        }
        field(19; "Job Complete"; Boolean)
        {
            Caption = 'Project Complete';
            ToolTip = 'Specifies whether a project is complete. This check box is selected if the Project WIP G/L Entry was created for a Project with a Completed status.';
        }
        field(20; "Job WIP Total Entry No."; Integer)
        {
            Caption = 'Project WIP Total Entry No.';
            ToolTip = 'Specifies the entry number from the associated project WIP total.';
            TableRelation = "Job WIP Total";
        }
        field(60; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(61; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Job No.", Reversed, "Job Complete", Type)
        {
            SumIndexFields = "WIP Entry Amount";
        }
        key(Key3; "Job No.", Reverse, "Job Complete", Type)
        {
            SumIndexFields = "WIP Entry Amount";
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
        key(Key5; "WIP Transaction No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;
}

