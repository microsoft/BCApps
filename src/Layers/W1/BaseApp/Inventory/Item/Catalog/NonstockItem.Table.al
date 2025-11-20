// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;

table 5718 "Nonstock Item"
{
    Caption = 'Nonstock Item';
    DrillDownPageID = "Catalog Item List";
    LookupPageID = "Catalog Item List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Code[20])
        {
            Caption = 'Entry No.';
            OptimizeForTextSearch = true;
            Editable = true;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "Entry No." <> xRec."Entry No." then begin
                    GetInvtSetup();
                    NoSeries.TestManual(InvtSetup."Nonstock Item Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            TableRelation = Manufacturer.Code;

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Manufacturer Code"));
            end;
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            OptimizeForTextSearch = true;
            TableRelation = Vendor."No.";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                OnBeforeValidateVendorNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                ValidateField(Rec.FieldNo("Vendor No."));

                if "Vendor No." <> xRec."Vendor No." then
                    if CheckVendorItemNo("Vendor No.", "Vendor Item No.", Rec.FieldNo("Vendor No.")) then
                        Error(Text002, "Vendor No.", "Vendor Item No.");
            end;
        }
        field(4; "Vendor Item No."; Code[50])
        {
            Caption = 'Vendor Item No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVendorItemNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                ValidateField(Rec.FieldNo("Vendor Item No."));

                if "Vendor Item No." <> xRec."Vendor Item No." then
                    if CheckVendorItemNo("Vendor No.", "Vendor Item No.", Rec.FieldNo("Vendor Item No.")) then
                        Error(Text002, "Vendor No.", "Vendor Item No.");
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;
            Editable = true;

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo(Description));
            end;
        }
        field(6; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Unit of Measure"));
            end;
        }
        field(7; "Published Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Published Cost';

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Published Cost"));
            end;
        }
        field(8; "Negotiated Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Negotiated Cost';

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Negotiated Cost"));
            end;
        }
        field(9; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Unit Price"));
            end;
        }
        field(10; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Gross Weight"));
            end;
        }
        field(11; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Net Weight"));
            end;
        }
        field(14; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(15; "Bar Code"; Code[20])
        {
            Caption = 'Bar Code';

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Bar Code"));
            end;
        }
        field(16; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Item No."));
            end;
        }
        field(17; "Item No. Series"; Code[20])
        {
            Caption = 'Item No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(53; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("Nonstock Item"),
                                                      "No." = field("Entry No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(98; "Item Templ. Code"; Code[20])
        {
            Caption = 'Item Template Code';
            TableRelation = "Item Templ.";

            trigger OnValidate()
            begin
                ValidateField(Rec.FieldNo("Item Templ. Code"));
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Vendor Item No.", "Manufacturer Code")
        {
        }
        key(Key3; "Item No.")
        {
        }
        key(Key4; "Vendor No.", "Vendor Item No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Vendor Item No.", "Manufacturer Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        Item: Record Item;
    begin
        if Item.Get("Item No.") then begin
            Item."Created From Nonstock Item" := false;
            Item.Modify();
        end;
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        NonStockItem.LockTable();
        if "Entry No." = '' then begin
            GetInvtSetup();
            InvtSetup.TestField("Nonstock Item Nos.");
            "No. Series" := InvtSetup."Nonstock Item Nos.";
            if NoSeries.AreRelated(InvtSetup."Nonstock Item Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "Entry No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnModify()
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        "Last Date Modified" := Today;
        MfrLength := StrLen("Manufacturer Code");
        VenLength := StrLen("Vendor Item No.");

        NonStockItemSetup.Get();
        case NonStockItemSetup."No. Format" of
            NonStockItemSetup."No. Format"::"Entry No.":
                ItemNo := "Entry No.";
            NonStockItemSetup."No. Format"::"Vendor Item No.":
                ItemNo := CopyStr("Vendor Item No.", 1, MaxStrLen("Item No."));
            NonStockItemSetup."No. Format"::"Mfr. + Vendor Item No.":
                if NonStockItemSetup."No. Format Separator" = '' then begin
                    if MfrLength + VenLength <= 20 then
                        ItemNo := CopyStr(InsStr("Manufacturer Code", "Vendor Item No.", 6), 1, MaxStrLen("Item No."))
                    else
                        ItemNo := InsStr("Manufacturer Code", "Entry No.", 6);
                end else begin
                    TempItemNo :=
                      InsStr("Manufacturer Code", NonStockItemSetup."No. Format Separator", 6);
                    if MfrLength + VenLength < 20 then
                        ItemNo := CopyStr(InsStr(TempItemNo, "Vendor Item No.", 7), 1, MaxStrLen("Item No."))
                    else
                        ItemNo := InsStr(TempItemNo, "Entry No.", 7);
                end;
            NonStockItemSetup."No. Format"::"Vendor Item No. + Mfr.":
                if NonStockItemSetup."No. Format Separator" = '' then begin
                    if VenLength + MfrLength <= 20 then
                        ItemNo := CopyStr(InsStr("Vendor Item No.", "Manufacturer Code", 11), 1, MaxStrLen("Item No."))
                    else
                        ItemNo := InsStr("Entry No.", "Manufacturer Code", 11);
                end else begin
                    TempItemNo :=
                      CopyStr(InsStr("Vendor Item No.", NonStockItemSetup."No. Format Separator", 10), 1, MaxStrLen("Item No."));
                    if VenLength + MfrLength < 20 then
                        ItemNo := InsStr(TempItemNo, "Manufacturer Code", 11);
                end;
            NonStockItemSetup."No. Format"::"Item No. Series":
                ItemNo := "Item No.";
            else
                OnModifyOnNoFormatElseCase(NonStockItemSetup, Rec, ItemNo);
        end;

        OnModifyOnBeforeError(Rec, IsHandled);
        if IsHandled then
            exit;

        if ItemNo <> '' then begin
            Item.SetRange("No.", ItemNo);
            if not Item.IsEmpty() then
                Error(Text001);
        end;
    end;

    trigger OnRename()
    begin
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Nonstock Item", xRec."Entry No.", "Entry No.");
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'Modification not allowed, item record already exists.';
#pragma warning restore AA0074
        NonStockItem: Record "Nonstock Item";
        NonStockItemSetup: Record "Nonstock Item Setup";
        InvtSetup: Record "Inventory Setup";
        ItemNo: Code[20];
        TempItemNo: Code[20];
        MfrLength: Integer;
        VenLength: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'No.=<%1> and Vendor Item No.=<%2> already exists.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        HasInvtSetup: Boolean;

    protected var
        CommentLine: Record "Comment Line";

    procedure AssistEdit(): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        GetInvtSetup();
        InvtSetup.TestField("Nonstock Item Nos.");
        if NoSeries.LookupRelatedNoSeries(InvtSetup."Nonstock Item Nos.", xRec."No. Series", "No. Series") then begin
            "Entry No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    procedure CheckVendorItemNo(VendorNo: Code[20]; VendorItemNo: Code[50]; CalledByFieldNo: Integer) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVendorItemNo(Rec, xRec, VendorNo, VendorItemNo, CalledByFieldNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        NonStockItem.Reset();
        NonStockItem.SetCurrentKey("Vendor No.", "Vendor Item No.");
        NonStockItem.SetRange("Vendor No.", VendorNo);
        NonStockItem.SetRange("Vendor Item No.", VendorItemNo);
        exit(NonStockItem.FindFirst());
    end;

    local procedure GetInvtSetup()
    begin
        if not HasInvtSetup then begin
            InvtSetup.Get();
            HasInvtSetup := true;
        end;
    end;

    local procedure ValidateField(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateField(Rec, xRec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Item No." <> '') and CalledByFieldNoChanged(CalledByFieldNo) then
            Error(Text001);
    end;

    local procedure CalledByFieldNoChanged(CalledByFieldNo: Integer): Boolean
    begin
        case CalledByFieldNo of
            Rec.FieldNo("Manufacturer Code"):
                exit(Rec."Manufacturer Code" <> xRec."Manufacturer Code");
            Rec.FieldNo("Vendor No."):
                exit(Rec."Vendor No." <> xRec."Vendor No.");
            Rec.FieldNo("Vendor Item No."):
                exit(Rec."Vendor Item No." <> xRec."Vendor Item No.");
            Rec.FieldNo(Description):
                exit(Rec.Description <> xRec.Description);
            Rec.FieldNo("Unit of Measure"):
                exit(Rec."Unit of Measure" <> xRec."Unit of Measure");
            Rec.FieldNo("Published Cost"):
                exit(Rec."Published Cost" <> xRec."Published Cost");
            Rec.FieldNo("Negotiated Cost"):
                exit(Rec."Negotiated Cost" <> xRec."Negotiated Cost");
            Rec.FieldNo("Unit Price"):
                exit(Rec."Unit Price" <> xRec."Unit Price");
            Rec.FieldNo("Gross Weight"):
                exit(Rec."Gross Weight" <> xRec."Gross Weight");
            Rec.FieldNo("Net Weight"):
                exit(Rec."Net Weight" <> xRec."Net Weight");
            Rec.FieldNo("Bar Code"):
                exit(Rec."Bar Code" <> xRec."Bar Code");
            Rec.FieldNo("Item No."):
                exit(Rec."Item No." <> xRec."Item No.");
            Rec.FieldNo("Item Templ. Code"):
                exit(Rec."Item Templ. Code" <> xRec."Item Templ. Code");
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVendorItemNo(var NonstockItem: Record "Nonstock Item"; xNonstockItem: Record "Nonstock Item"; VendorNo: Code[20]; VendorItemNo: Code[50]; CalledByFieldNo: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateField(var NonstockItem: Record "Nonstock Item"; xNonstockItem: Record "Nonstock Item"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVendorNo(var NonstockItem: Record "Nonstock Item"; xNonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeError(var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnNoFormatElseCase(NonStockItemSetup: Record "Nonstock Item Setup"; NonstockItem: Record "Nonstock Item"; var ItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVendorItemNo(var NonstockItem: Record "Nonstock Item"; xNonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;
}