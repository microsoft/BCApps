// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Extends Purchase Line with Intercompany-specific fields and logic.
/// </summary>
tableextension 8444 ICPurchaseLine extends "Purchase Line"
{
    fields
    {
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item or account in your IC partner''s company that corresponds to the item or account on the line.';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "IC Partner Code" <> '' then
                    "IC Partner Ref. Type" := "IC Partner Ref. Type"::"G/L Account";
                if "IC Partner Ref. Type" <> xRec."IC Partner Ref. Type" then
                    "IC Partner Reference" := '';
                if "IC Partner Ref. Type" = "IC Partner Ref. Type"::"Common Item No." then begin
                    Item := GetItem();
                    Item.TestField("Common Item No.");
                    "IC Partner Reference" := Item."Common Item No.";
                end;
            end;
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the IC partner. If the line is being sent to one of your intercompany partners, this field is used together with the IC Partner Ref. Type field to indicate the item or account in your partner''s company that corresponds to the line.';

            trigger OnLookup()
            var
                ItemReference: Record "Item Reference";
                ItemVendorCatalog: Record "Item Vendor";
                PurchHeader: Record "Purchase Header";
            begin
                if Rec."No." <> '' then
                    case Rec."IC Partner Ref. Type" of
                        Rec."IC Partner Ref. Type"::"Cross Reference":
                            begin
                                PurchHeader := Rec.GetPurchHeader();
                                ItemReference.Reset();
                                ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
                                ItemReference.SetFilter(
                                    "Reference Type", '%1|%2',
                                    ItemReference."Reference Type"::Vendor, ItemReference."Reference Type"::" ");
                                ItemReference.SetFilter("Reference Type No.", '%1|%2', PurchHeader."Buy-from Vendor No.", '');
                                if PAGE.RunModal(PAGE::"Item Reference List", ItemReference) = ACTION::LookupOK then
                                    Rec.Validate("IC Item Reference No.", ItemReference."Reference No.");
                            end;
                        Rec."IC Partner Ref. Type"::"Vendor Item No.":
                            begin
                                PurchHeader := Rec.GetPurchHeader();
                                ItemVendorCatalog.SetCurrentKey("Vendor No.");
                                ItemVendorCatalog.SetRange("Vendor No.", PurchHeader."Buy-from Vendor No.");
                                if PAGE.RunModal(PAGE::"Vendor Item Catalog", ItemVendorCatalog) = ACTION::LookupOK then
                                    Rec.Validate("IC Item Reference No.", ItemVendorCatalog."Vendor Item No.");
                            end;
                    end;
            end;
        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            TableRelation = "IC Partner";
            ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';

            trigger OnValidate()
            var
                PurchaseHeader: Record "Purchase Header";
            begin
                if "IC Partner Code" <> '' then begin
                    TestField(Type, Type::"G/L Account");
                    PurchaseHeader := GetPurchHeader();
                    PurchaseHeader.TestField("Buy-from IC Partner Code", '');
                    PurchaseHeader.TestField("Pay-to IC Partner Code", '');
                    Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"G/L Account");
                end;
            end;
        }
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item number in your IC partner''s company that corresponds to the item on the line. This field is used together with the IC Partner Ref. Type field to indicate the item in your partner''s company that corresponds to the line.';

            trigger OnLookup()
            var
                ItemReference: Record "Item Reference";
                ItemVendorCatalog: Record "Item Vendor";
                PurchHeader: Record "Purchase Header";
            begin
                if Rec."No." <> '' then
                    case Rec."IC Partner Ref. Type" of
                        Rec."IC Partner Ref. Type"::"Cross Reference":
                            begin
                                PurchHeader := Rec.GetPurchHeader();
                                ItemReference.Reset();
                                ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
                                ItemReference.SetFilter(
                                    "Reference Type", '%1|%2',
                                    ItemReference."Reference Type"::Vendor, ItemReference."Reference Type"::" ");
                                ItemReference.SetFilter("Reference Type No.", '%1|%2', PurchHeader."Buy-from Vendor No.", '');
                                if PAGE.RunModal(PAGE::"Item Reference List", ItemReference) = ACTION::LookupOK then
                                    Rec.Validate("IC Item Reference No.", ItemReference."Reference No.");
                            end;
                        Rec."IC Partner Ref. Type"::"Vendor Item No.":
                            begin
                                PurchHeader := Rec.GetPurchHeader();
                                ItemVendorCatalog.SetCurrentKey("Vendor No.");
                                ItemVendorCatalog.SetRange("Vendor No.", PurchHeader."Buy-from Vendor No.");
                                if PAGE.RunModal(PAGE::"Vendor Item Catalog", ItemVendorCatalog) = ACTION::LookupOK then
                                    Rec.Validate("IC Item Reference No.", ItemVendorCatalog."Vendor Item No.");
                            end;
                    end;
            end;
        }
    }

    /// <summary>
    /// Updates the intercompany partner information on the purchase line if the purchase header has outgoing intercompany direction.
    /// </summary>
    procedure UpdateICPartner()
    var
        ICPartner: Record "IC Partner";
        PurchHeader: Record "Purchase Header";
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchHeader := GetPurchHeader();
        OnBeforeUpdateICPartner(Rec, GLAcc, PurchHeader, IsHandled);
        if not IsHandled then
            if PurchHeader."Send IC Document" and (PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing) then
                case Type of
                    Type::" ", Type::"Charge (Item)":
                        begin
                            "IC Partner Ref. Type" := Type;
                            "IC Partner Reference" := "No.";
                        end;
                    Type::"G/L Account":
                        begin
                            GLAcc := GetGLAccount();
                            "IC Partner Ref. Type" := Type;
                            "IC Partner Reference" := GLAcc."Default IC Partner G/L Acc. No";
                        end;
                    Type::Item:
                        begin
                            ICPartner.Get(PurchHeader."Buy-from IC Partner Code");
                            case ICPartner."Outbound Purch. Item No. Type" of
                                ICPartner."Outbound Purch. Item No. Type"::"Common Item No.":
                                    Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Common Item No.");
                                ICPartner."Outbound Purch. Item No. Type"::"Internal No.":
                                    begin
                                        Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::Item);
                                        "IC Partner Reference" := "No.";
                                    end;
                                ICPartner."Outbound Purch. Item No. Type"::"Cross Reference":
                                    begin
                                        Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Cross Reference");
                                        UpdateICPartnerItemReference();
                                    end;
                                ICPartner."Outbound Purch. Item No. Type"::"Vendor Item No.":
                                    begin
                                        "IC Partner Ref. Type" := "IC Partner Ref. Type"::"Vendor Item No.";
                                        "IC Item Reference No." := "Vendor Item No.";
                                    end;
                            end;
                        end;
                    Type::"Fixed Asset":
                        begin
                            "IC Partner Ref. Type" := "IC Partner Ref. Type"::" ";
                            "IC Partner Reference" := '';
                        end;
                end;

        OnAfterUpdateICPartner(Rec, PurchHeader);
    end;

    local procedure UpdateICPartnerItemReference()
    var
        ItemReference: Record "Item Reference";
        ToDate: Date;
    begin
        ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", "Buy-from Vendor No.");
        ItemReference.SetRange("Item No.", "No.");
        ItemReference.SetRange("Variant Code", "Variant Code");
        ItemReference.SetRange("Unit of Measure", "Unit of Measure Code");
        ToDate := Rec.GetDateForCalculations();
        if ToDate <> 0D then begin
            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        if ItemReference.FindFirst() then
            "IC Item Reference No." := ItemReference."Reference No."
        else
            "IC Partner Reference" := "No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateICPartner(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateICPartner(var PurchLine: Record "Purchase Line"; GLAcc: Record "G/L Account"; var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}
