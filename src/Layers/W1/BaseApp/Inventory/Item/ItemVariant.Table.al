// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Structure;

table 5401 "Item Variant"
{
    Caption = 'Item Variant';
    DataCaptionFields = "Item No.", "Code", Description;
    LookupPageID = "Item Variants";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            OptimizeForTextSearch = true;
            NotBlank = true;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Item No." = '' then
                    Clear("Item Id")
                else
                    if Item.Get("Item No.") then
                        "Item Id" := Item.SystemId;
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            OptimizeForTextSearch = true;
        }
        field(5; "Item Id"; Guid)
        {
            Caption = 'Item Id';
            TableRelation = Item.SystemId;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                Item.SetLoadFields("No.");
                if IsNullGuid("Item Id") then
                    "Item No." := ''
                else
                    if Item.GetBySystemId("Item Id") then
                        "Item No." := Item."No.";
            end;
        }
        field(54; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
        }
        field(8003; "Sales Blocked"; Boolean)
        {
            Caption = 'Sales Blocked';
            DataClassification = CustomerContent;
        }
        field(8004; "Purchasing Blocked"; Boolean)
        {
            Caption = 'Purchasing Blocked';
            DataClassification = CustomerContent;
        }
        field(8010; "Service Blocked"; Boolean)
        {
            Caption = 'Service Blocked';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Code")
        {
        }
        key(Key3; Description)
        {
        }
        key(Key4; "Item Id", "Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Code", Description)
        {
        }
    }

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if xRec."Item No." <> "Item No." then begin
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            SalesLine.SetRange("No.", xRec."Item No.");
            SalesLine.SetRange("Variant Code", xRec.Code);
            if not SalesLine.IsEmpty() then
                Error(CannotRenameItemUsedInSalesLinesErr, FieldCaption("Item No."), TableCaption());

            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("No.", xRec."Item No.");
            PurchaseLine.SetRange("Variant Code", xRec.Code);
            if not PurchaseLine.IsEmpty() then
                Error(CannotRenameItemUsedInPurchaseLinesErr, FieldCaption("Item No."), TableCaption());
        end;
    end;

    trigger OnDelete()
    var
        ItemTranslation: Record "Item Translation";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemIdentifier: Record "Item Identifier";
        ItemReference: Record "Item Reference";
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        AssemblyHeader: Record "Assembly Header";
        ItemSubstitution: Record "Item Substitution";
        ItemVendor: Record "Item Vendor";
        PlanningAssignment: Record "Planning Assignment";
        BinContent: Record "Bin Content";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        AssemblyLine: Record "Assembly Line";
    begin
        BOMComponent.SetCurrentKey(Type, "No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.SetRange("No.", "Item No.");
        BOMComponent.SetRange("Variant Code", Code);
        if not BOMComponent.IsEmpty() then
            Error(Text001, Code, BOMComponent.TableCaption());

        AssemblyHeader.SetCurrentKey("Document Type", "Item No.");
        AssemblyHeader.SetRange("Item No.", "Item No.");
        AssemblyHeader.SetRange("Variant Code", Code);
        if not AssemblyHeader.IsEmpty() then
            Error(Text001, Code, AssemblyHeader.TableCaption());

        AssemblyLine.SetCurrentKey("Document Type", Type, "No.");
        AssemblyLine.SetRange("No.", "Item No.");
        AssemblyLine.SetRange("Variant Code", Code);
        if not AssemblyLine.IsEmpty() then
            Error(Text001, Code, AssemblyLine.TableCaption());

        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "Item No.");
        BinContent.SetRange("Variant Code", Code);
        if not BinContent.IsEmpty() then
            Error(Text001, Code, BinContent.TableCaption());

        TransferLine.SetCurrentKey("Item No.");
        TransferLine.SetRange("Item No.", "Item No.");
        TransferLine.SetRange("Variant Code", Code);
        if not TransferLine.IsEmpty() then
            Error(Text001, Code, TransferLine.TableCaption());

        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", "Item No.");
        RequisitionLine.SetRange("Variant Code", Code);
        if not RequisitionLine.IsEmpty() then
            Error(Text001, Code, RequisitionLine.TableCaption());

        PurchaseLine.SetCurrentKey(Type, "No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", "Item No.");
        PurchaseLine.SetRange("Variant Code", Code);
        if not PurchaseLine.IsEmpty() then
            Error(Text001, Code, PurchaseLine.TableCaption());

        SalesLine.SetCurrentKey(Type, "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", "Item No.");
        SalesLine.SetRange("Variant Code", Code);
        if not SalesLine.IsEmpty() then
            Error(Text001, Code, SalesLine.TableCaption());

        ItemJournalLine.SetCurrentKey("Item No.");
        ItemJournalLine.SetRange("Item No.", "Item No.");
        ItemJournalLine.SetRange("Variant Code", Code);
        if not ItemJournalLine.IsEmpty() then
            Error(Text001, Code, ItemJournalLine.TableCaption());

        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", "Item No.");
        ItemLedgerEntry.SetRange("Variant Code", Code);
        if not ItemLedgerEntry.IsEmpty() then
            Error(Text001, Code, ItemLedgerEntry.TableCaption());

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", "Item No.");
        ValueEntry.SetRange("Variant Code", Code);
        if not ValueEntry.IsEmpty() then
            Error(Text001, Code, ValueEntry.TableCaption());

        OnDeleteOnAfterCheck(Rec);

        ItemTranslation.SetRange("Item No.", "Item No.");
        ItemTranslation.SetRange("Variant Code", Code);
        ItemTranslation.DeleteAll();

        ItemIdentifier.SetCurrentKey("Item No.");
        ItemIdentifier.SetRange("Item No.", "Item No.");
        ItemIdentifier.SetRange("Variant Code", Code);
        ItemIdentifier.DeleteAll();

        ItemReference.SetRange("Item No.", "Item No.");
        ItemReference.SetRange("Variant Code", Code);
        ItemReference.DeleteAll();

        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", "Item No.");
        ItemSubstitution.SetRange("Substitute Type", ItemSubstitution."Substitute Type"::Item);
        ItemSubstitution.SetRange("Variant Code", Code);
        ItemSubstitution.DeleteAll();

        ItemVendor.SetCurrentKey("Item No.");
        ItemVendor.SetRange("Item No.", "Item No.");
        ItemVendor.SetRange("Variant Code", Code);
        ItemVendor.DeleteAll();

        StockkeepingUnit.SetRange("Item No.", "Item No.");
        StockkeepingUnit.SetRange("Variant Code", Code);
        StockkeepingUnit.DeleteAll(true);

        PlanningAssignment.SetRange("Item No.", "Item No.");
        PlanningAssignment.SetRange("Variant Code", Code);
        PlanningAssignment.DeleteAll();

        OnAfterOnDelete(Rec);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot delete item variant %1 because there is at least one %2 that includes this Variant Code.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CannotRenameItemUsedInSalesLinesErr: Label 'You cannot rename %1 in a %2, because it is used in sales document lines.', Comment = '%1 = Item No. caption, %2 = Table caption.';
        CannotRenameItemUsedInPurchaseLinesErr: Label 'You cannot rename %1 in a %2, because it is used in purchase document lines.', Comment = '%1 = Item No. caption, %2 = Table caption.';

    procedure UpdateReferencedIds()
    var
        Item: Record Item;
    begin
        if "Item No." = '' then begin
            Clear("Item Id");
            exit;
        end;

        Item.SetLoadFields(SystemId);
        if not Item.Get("Item No.") then
            exit;

        "Item Id" := Item.SystemId;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDelete(ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterCheck(var ItemVariant: Record "Item Variant")
    begin
    end;
}

