// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Service.Document;
using System.Utilities;

table 5941 "Service Item Component"
{
    Caption = 'Service Item Component';
    DrillDownPageID = "Service Item Component List";
    LookupPageID = "Service Item Component List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Parent Service Item No."; Code[20])
        {
            Caption = 'Parent Service Item No.';
            TableRelation = "Service Item";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(5; Type; Enum "Service Item Component Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if Type <> xRec.Type then
                    Validate("No.", '');
            end;
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Service Item")) "Service Item"
            else
            if (Type = const(Item)) Item;

            trigger OnLookup()
            begin
                case Type of
                    Type::"Service Item":
                        begin
                            ServItem.Get("Parent Service Item No.");
                            ServItem2.Reset();
                            ServItem2.SetCurrentKey("Customer No.", "Ship-to Code");
                            ServItem2.SetRange("Customer No.", ServItem."Customer No.");
                            ServItem2.SetRange("Ship-to Code", ServItem."Ship-to Code");
                            ServItem2."No." := "No.";
                            if PAGE.RunModal(0, ServItem2) = ACTION::LookupOK then
                                Validate("No.", ServItem2."No.");
                        end;
                    Type::Item:
                        begin
                            Item."No." := xRec."No.";
                            if PAGE.RunModal(0, Item) = ACTION::LookupOK then
                                Validate("No.", Item."No.");
                        end;
                    else
                        OnLookupNoOnCaseElse(Rec);
                end;
            end;

            trigger OnValidate()
            begin
                if "No." <> '' then begin
                    case Type of
                        Type::"Service Item":
                            begin
                                if "No." = "Parent Service Item No." then
                                    Error(
                                      Text000,
                                      Type, "No.", TableCaption(), ServItem.TableCaption(), "Parent Service Item No.");
                                ServItem.Get("No.");
                                "Serial No." := ServItem."Serial No.";
                                "Variant Code" := ServItem."Variant Code";
                                Description := ServItem.Description;
                                "Description 2" := ServItem."Description 2";
                            end;
                        Type::Item:
                            begin
                                Item.Get("No.");
                                "Serial No." := '';
                                Description := Item.Description;
                                "Description 2" := Item."Description 2";
                            end;
                        else
                            OnValidateNoOnCaseElse(Rec);
                    end;
                    "Date Installed" := WorkDate();
                end else begin
                    "No." := '';
                    "Date Installed" := 0D;
                    "Serial No." := '';
                    Description := '';
                    "Description 2" := '';
                end;

                Validate("Serial No.");
            end;
        }
        field(7; "Date Installed"; Date)
        {
            Caption = 'Date Installed';
        }
        field(8; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                OnBeforeLookupVariantCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                case Type of
                    Type::Item:
                        begin
                            ItemVariant.Reset();
                            ItemVariant.SetRange("Item No.", "No.");
                            if PAGE.RunModal(PAGE::"Item Variants", ItemVariant) = ACTION::LookupOK then
                                "Variant Code" := ItemVariant.Code;
                        end;
                    Type::"Service Item":
                        begin
                            if "No." <> '' then begin
                                ServItem.Get("No.");
                                ItemVariant.Reset();
                                ItemVariant.SetRange("Item No.", ServItem."Item No.");
                            end else
                                ItemVariant.SetRange("Item No.", '');
                            if PAGE.RunModal(PAGE::"Item Variants", ItemVariant) = ACTION::LookupOK then
                                Validate("Variant Code", ItemVariant.Code);
                        end;
                end;
            end;

            trigger OnValidate()
            begin
                if Type = Type::"Service Item" then
                    if "No." <> '' then begin
                        ServItem.Get("No.");
                        TestField("Variant Code", ServItem."Variant Code");
                    end;
            end;
        }
        field(11; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                if (Type = Type::"Service Item") and
                   ("No." <> '')
                then begin
                    ServItem.Get("No.");
                    if "Serial No." <> ServItem."Serial No." then
                        Error(Text001, FieldCaption("Serial No."), Type, "No.");
                end;
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(15; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;

            trigger OnLookup()
            begin
                ServOrderMgt.ServHeaderLookup(1, "Service Order No.");
            end;
        }
        field(16; "From Line No."; Integer)
        {
            Caption = 'From Line No.';
        }
        field(17; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
        }
    }

    keys
    {
        key(Key1; Active, "Parent Service Item No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Active, "Parent Service Item No.", "From Line No.")
        {
        }
        key(Key3; Type, "No.", Active)
        {
        }
        key(Key4; Active, "Parent Service Item No.", Type, "No.")
        {
        }
        key(Key5; "Parent Service Item No.", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Active then begin
            ServItemComponent.Reset();
            ServItemComponent.SetCurrentKey(Active, "Parent Service Item No.", "From Line No.");
            ServItemComponent.SetRange(Active, false);
            ServItemComponent.SetRange("Parent Service Item No.", "Parent Service Item No.");
            ServItemComponent.SetRange("From Line No.", "Line No.");
            if ServItemComponent.FindFirst() then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text002, "No."), true) then
                    Error('');
            ServItemComponent.DeleteAll();
        end;
    end;

    trigger OnModify()
    begin
        if Active and (Type <> xRec.Type) then begin
            ServItemComponent.Reset();
            ServItemComponent.SetCurrentKey(Active, "Parent Service Item No.", "Line No.");
            ServItemComponent.SetRange(Active, false);
            ServItemComponent.SetRange("Parent Service Item No.", "Parent Service Item No.");
            if ServItemComponent.FindLast() then
                NextNo := ServItemComponent."Line No." + 1
            else
                NextNo := 1;
            ServItemComponent := xRec;
            ServItemComponent.Active := false;
            ServItemComponent."Line No." := NextNo;
            ServItemComponent."From Line No." := "Line No.";
            ServItemComponent."Last Date Modified" := Today;
            ServItemComponent.Insert(true);
        end;
    end;

    var
        ServItemComponent: Record "Service Item Component";
        ServItem: Record "Service Item";
        ServItem2: Record "Service Item";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServOrderMgt: Codeunit ServOrderManagement;
        NextNo: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 can not be a component in %3 for %4 %5';
        Text001: Label '%1 must be the same as in %2 %3.';
        Text002: Label 'Component %1 has replacements\Do you want to delete this Component?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AssistEditSerialNo()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TestField(Type, Type::Item);
        Clear(ItemLedgEntry);
        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        if "Variant Code" <> '' then
            ItemLedgEntry.SetRange("Variant Code", "Variant Code");
        ItemLedgEntry.SetFilter("Serial No.", '<>%1', '');
        if PAGE.RunModal(0, ItemLedgEntry) = ACTION::LookupOK then
            "Serial No." := ItemLedgEntry."Serial No.";
    end;

    procedure SplitLineNo(xServiceItemComponent: Record "Service Item Component"; BelowxRec: Boolean) ResultLineNo: Integer
    var
        ServiceItemComponent: Record "Service Item Component";
    begin
        if "Line No." <> 0 then
            ResultLineNo := "Line No."
        else begin
            ServiceItemComponent.SetCurrentKey("Parent Service Item No.", "Line No.");
            TestField("Parent Service Item No.");
            ServiceItemComponent.SetRange("Parent Service Item No.", "Parent Service Item No.");
            if BelowxRec then begin
                if ServiceItemComponent.FindLast() then;
                ResultLineNo := ServiceItemComponent."Line No." + 10000;
            end else
                if "Parent Service Item No." = xServiceItemComponent."Parent Service Item No." then begin
                    ServiceItemComponent.SetFilter("Line No.", '<%1', xServiceItemComponent."Line No.");
                    if ServiceItemComponent.FindLast() then;
                    ResultLineNo := Round((xServiceItemComponent."Line No." + ServiceItemComponent."Line No.") / 2, 1);
                end else begin
                    if ServiceItemComponent.FindLast() then;
                    ResultLineNo := ServiceItemComponent."Line No." + 10000;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupVariantCode(var ServiceItemComponent: Record "Service Item Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupNoOnCaseElse(var ServiceItemComponent: Record "Service Item Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnCaseElse(var ServiceItemComponent: Record "Service Item Component")
    begin
    end;
}

