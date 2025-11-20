// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;

table 5628 Insurance
{
    Caption = 'Insurance';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Insurance List";
    LookupPageID = "Insurance List";
    Permissions = TableData "Ins. Coverage Ledger Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    FASetup.Get();
                    NoSeries.TestManual(FASetup."Insurance Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
        }
        field(3; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(4; "Policy No."; Text[30])
        {
            Caption = 'Policy No.';
        }
        field(6; "Annual Premium"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Annual Premium';
            MinValue = 0;
        }
        field(7; "Policy Coverage"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Policy Coverage';
            MinValue = 0;
        }
        field(10; "Total Value Insured"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Ins. Coverage Ledger Entry".Amount where("Insurance No." = field("No."),
                                                                         "Disposed FA" = const(false),
                                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Total Value Insured';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const(Insurance),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Insurance Type"; Code[10])
        {
            Caption = 'Insurance Type';
            TableRelation = "Insurance Type";
        }
        field(13; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(14; "Insurance Vendor No."; Code[20])
        {
            Caption = 'Insurance Vendor No.';
            TableRelation = Vendor;
        }
        field(15; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(16; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }
        field(17; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(18; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(19; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(32; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(33; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
            end;
        }
        field(34; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(35; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(36; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Policy No.")
        {
        }
    }

    trigger OnDelete()
    begin
        FAMoveEntries.MoveInsuranceEntries(Rec);
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Insurance);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::Insurance, "No.");
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            FASetup.Get();
            FASetup.TestField("Insurance Nos.");
			if NoSeries.AreRelated(FASetup."Insurance Nos.", xRec."No. Series") then
				"No. Series" := xRec."No. Series"
			else
				"No. Series" := FASetup."Insurance Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        DimMgt.UpdateDefaultDim(
          DATABASE::Insurance, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::Insurance, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Insurance, xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        CommentLine: Record "Comment Line";
        FASetup: Record "FA Setup";
        Insurance: Record Insurance;
        NoSeries: Codeunit "No. Series";
        FAMoveEntries: Codeunit "FA MoveEntries";
        DimMgt: Codeunit DimensionManagement;

    procedure AssistEdit(OldInsurance: Record Insurance) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldInsurance, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Insurance := Rec;
        FASetup.Get();
        FASetup.TestField("Insurance Nos.");
        if NoSeries.LookupRelatedNoSeries(FASetup."Insurance Nos.", OldInsurance."No. Series", Insurance."No. Series") then begin
            Insurance."No." := NoSeries.GetNextNo(Insurance."No. Series");
            Rec := Insurance;
            exit(true);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Insurance, "No.", FieldNumber, ShortcutDimCode);
            Modify(true);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Insurance: Record Insurance; var xInsurance: Record Insurance; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Insurance: Record Insurance; OldInsurance: Record Insurance; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Insurance: Record Insurance; var xInsurance: Record Insurance; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}
