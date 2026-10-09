// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Projects.Resources.Resource;

/// <summary>
/// Extends Sales Line with Intercompany-specific fields and logic.
/// </summary>
tableextension 8481 ICSalesLine extends "Sales Line"
{
    fields
    {
        /// <summary>
        /// Specifies the type of intercompany partner reference for the line item.
        /// </summary>
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
                    GetItem(Item);
                    Item.TestField("Common Item No.");
                    "IC Partner Reference" := Item."Common Item No.";
                end;
            end;
        }
        /// <summary>
        /// Specifies the intercompany partner reference number for the item or G/L account.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the IC partner. If the line is being sent to one of your intercompany partners, this field is used together with the IC Partner Ref. Type field to indicate the item or account in your partner''s company that corresponds to the line.';

            trigger OnLookup()
            var
                ICGLAccount: Record "IC G/L Account";
                Item: Record Item;
            begin
                if Rec."No." <> '' then
                    case Rec."IC Partner Ref. Type" of
                        Rec."IC Partner Ref. Type"::"G/L Account":
                            begin
                                if ICGLAccount.Get(Rec."IC Partner Reference") then;
                                if PAGE.RunModal(PAGE::"IC G/L Account List", ICGLAccount) = ACTION::LookupOK then
                                    Rec.Validate("IC Partner Reference", ICGLAccount."No.");
                            end;
                        Rec."IC Partner Ref. Type"::Item:
                            begin
                                if Item.Get(Rec."IC Partner Reference") then;
                                if PAGE.RunModal(PAGE::"Item List", Item) = ACTION::LookupOK then
                                    Rec.Validate("IC Partner Reference", Item."No.");
                            end;
                        else
                            Rec.RunOnLookUpICPartnerReferenceTypeCaseElse();
                    end;
            end;
        }
        /// <summary>
        /// Specifies the intercompany partner code for transactions with related companies.
        /// </summary>
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            TableRelation = "IC Partner";
            ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';

            trigger OnValidate()
            var
                SalesHeader: Record "Sales Header";
            begin
                if "IC Partner Code" <> '' then begin
                    TestField(Type, Type::"G/L Account");
                    SalesHeader := GetSalesHeader();
                    SalesHeader.TestField("Sell-to IC Partner Code", '');
                    SalesHeader.TestField("Bill-to IC Partner Code", '');
                    Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"G/L Account");
                end;
            end;
        }
        /// <summary>
        /// Specifies the item reference number for intercompany transactions.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the IC item reference. If the line is being sent to one of your intercompany partners, this field is used together with the IC Partner Ref. Type field to indicate the item or account in your partner''s company that corresponds to the line.';

            trigger OnLookup()
            var
                ItemReference: Record "Item Reference";
            begin
                if Rec."No." <> '' then
                    case Rec."IC Partner Ref. Type" of
                        Rec."IC Partner Ref. Type"::"Cross Reference":
                            begin
                                ItemReference.Reset();
                                ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
                                ItemReference.SetFilter("Reference Type", '%1|%2', "Item Reference Type"::Customer, "Item Reference Type"::" ");
                                ItemReference.SetFilter("Reference Type No.", '%1|%2', Rec."Sell-to Customer No.", '');
                                if PAGE.RunModal(PAGE::"Item Reference List", ItemReference) = ACTION::LookupOK then
                                    Rec.Validate("IC Item Reference No.", ItemReference."Reference No.");
                            end;
                    end;
            end;
        }
    }

    /// <summary>
    /// Updates the intercompany partner information on the sales line for outgoing intercompany documents.
    /// </summary>
    procedure UpdateICPartner()
    var
        ICPartner: Record "IC Partner";
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        Resource: Record Resource;
        ShouldUpdateICPartner: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesHeader := GetSalesHeader();
        OnBeforeDoUpdateICPartner(Rec, SalesHeader, IsHandled);
        if not IsHandled then begin
            ShouldUpdateICPartner :=
                SalesHeader."Send IC Document" and (SalesHeader."IC Direction" = SalesHeader."IC Direction"::Outgoing) and
                (SalesHeader."Bill-to IC Partner Code" <> '');
            OnBeforeUpdateICPartner(SalesHeader, Rec, ShouldUpdateICPartner);
            if ShouldUpdateICPartner then
                case Type of
                    Type::" ", Type::"Charge (Item)":
                        begin
                            "IC Partner Ref. Type" := Type;
                            "IC Partner Reference" := "No.";
                        end;
                    Type::"G/L Account":
                        begin
                            GLAccount := GetGLAccount();
                            "IC Partner Ref. Type" := Type;
                            "IC Partner Reference" := GLAccount."Default IC Partner G/L Acc. No";
                        end;
                    Type::Item:
                        begin
                            if SalesHeader."Sell-to IC Partner Code" <> '' then
                                ICPartner.Get(SalesHeader."Sell-to IC Partner Code")
                            else
                                ICPartner.Get(SalesHeader."Bill-to IC Partner Code");
                            case ICPartner."Outbound Sales Item No. Type" of
                                ICPartner."Outbound Sales Item No. Type"::"Common Item No.":
                                    SetICPartnerRefType(Rec."IC Partner Ref. Type"::"Common Item No.");
                                ICPartner."Outbound Sales Item No. Type"::"Internal No.":
                                    begin
                                        SetICPartnerRefType(Rec."IC Partner Ref. Type"::Item);
                                        "IC Partner Reference" := "No.";
                                    end;
                                ICPartner."Outbound Sales Item No. Type"::"Cross Reference":
                                    begin
                                        SetICPartnerRefType(Rec."IC Partner Ref. Type"::"Cross Reference");
                                        UpdateICPartnerItemReference();
                                    end;
                            end;
                        end;
                    Type::"Fixed Asset":
                        begin
                            "IC Partner Ref. Type" := "IC Partner Ref. Type"::" ";
                            "IC Partner Reference" := '';
                        end;
                    Type::Resource:
                        begin
                            Resource := GetResource();
                            "IC Partner Ref. Type" := "IC Partner Ref. Type"::"G/L Account";
                            "IC Partner Reference" := Resource."IC Partner Purch. G/L Acc. No.";
                        end;
                end;
        end;

        OnAfterUpdateICPartner(Rec, SalesHeader);
    end;

    local procedure SetICPartnerRefType(NewType: Enum "IC Partner Reference Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetICPartnerRefType(Rec, NewType, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Rec.Validate("IC Partner Ref. Type", NewType);
    end;

    local procedure UpdateICPartnerItemReference()
    var
        ItemReference: Record "Item Reference";
        ToDate: Date;
    begin
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Customer);
        ItemReference.SetRange("Reference Type No.", "Sell-to Customer No.");
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

    /// <summary>
    /// Raised after updating the IC partner on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesHeader">The parent sales header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateICPartner(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before updating the IC partner on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesHeader">The parent sales header.</param>
    /// <param name="IsHandled">Set to true to skip the default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoUpdateICPartner(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating the IC partner.
    /// </summary>
    /// <param name="SalesHeader">The parent sales header.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="ShouldUpdateICPartner">Specifies whether to update the IC partner.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateICPartner(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ShouldUpdateICPartner: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting the IC partner reference type.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="NewType">The new IC partner reference type.</param>
    /// <param name="FieldNo">The field number.</param>
    /// <param name="IsHandled">Set to true to skip the default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetICPartnerRefType(var SalesLine: Record "Sales Line"; NewType: Enum "IC Partner Reference Type"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnLookUpICPartnerReferenceTypeCaseElse()
    begin
        OnLookUpICPartnerReferenceTypeCaseElse();
    end;

    /// <summary>
    /// Raised for the else case when looking up IC partner reference type.
    /// </summary>
    [IntegrationEvent(true, false)]
    local procedure OnLookUpICPartnerReferenceTypeCaseElse()
    begin
    end;
}
