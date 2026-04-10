// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 5629 "Ins. Coverage Ledger Entry"
{
    Caption = 'Ins. Coverage Ledger Entry';
    DrillDownPageID = "Ins. Coverage Ledger Entries";
    LookupPageID = "Ins. Coverage Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            ToolTip = 'Specifies the number of the insurance policy the entry is linked to.';
            TableRelation = Insurance;
        }
        field(3; "Disposed FA"; Boolean)
        {
            Caption = 'Disposed FA';
            ToolTip = 'Specifies that the fixed asset linked to this entry has been disposed of.';
        }
        field(4; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            ToolTip = 'Specifies the number of the related fixed asset.';
            TableRelation = "Fixed Asset";
        }
        field(5; "FA Description"; Text[100])
        {
            Caption = 'FA Description';
            ToolTip = 'Specifies a description of the fixed asset that the insurance entry is linked to.';
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
        }
        field(7; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type that the entry belongs to.';
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(9; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number on the entry.';
        }
        field(10; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            ToolTip = 'Specifies the amount of the entry.';
        }
        field(16; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry.';
        }
        field(17; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(18; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }
        field(19; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(20; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(21; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(23; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(24; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        field(25; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(26; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(27; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
            ToolTip = 'Specifies that this entry is an index entry.';
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Insurance No.", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Insurance No.", "Disposed FA", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key4; "FA No.", "Insurance No.", "Disposed FA", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key5; "FA No.", "Disposed FA", "Posting Date")
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Insurance No.", "FA No.", "FA Description", "Posting Date")
        {
        }
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

