// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using System.Utilities;

codeunit 7030 "Campaign Target Group Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        ContBusRel: Record "Contact Business Relation";
        SegLine: Record "Segment Line";
        CampaignTargetGr: Record "Campaign Target Group";
        InteractLogEntry: Record "Interaction Log Entry";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 is now activated.';
        Text001: Label '%1 %2 is now deactivated.';
        Text002: Label 'To activate the sales prices and/or line discounts, you must apply the relevant %1(s) to the %2 and place a check mark in the %3 field on the %1.';
        Text004: Label 'There are no Sales Prices or Sales Line Discounts currently linked to this %1. Do you still want to activate?';
#pragma warning restore AA0470
        Text006: Label 'Activating prices for the Contacts...\\';
        Text007: Label 'Segment Lines  @1@@@@@@@@@@';
        Text008: Label 'Logged Segment Lines  @1@@@@@@@@@@';
#pragma warning restore AA0074

    procedure ActivateCampaign(var Campaign: Record Campaign)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Window: Dialog;
        Found: Boolean;
        Continue: Boolean;
        NoOfRecords: Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeActivateCampaign(Campaign, IsHandled);
        if IsHandled then
            exit;

        if NoPriceDiscForCampaign(Campaign."No.") then begin
            Continue :=
                ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text004, Campaign.TableCaption()), true);
            if not Continue then
                exit;
        end;
        CampaignTargetGr.LockTable();
        Found := false;

        SegLine.SetCurrentKey("Campaign No.");
        SegLine.SetRange("Campaign No.", Campaign."No.");
        SegLine.SetRange("Campaign Target", true);
        if SegLine.Find('-') then begin
            Found := true;
            i := 0;
            Window.Open(
              Text006 +
              Text007);
            NoOfRecords := SegLine.Count;
            repeat
                i := i + 1;
                AddSegLinetoTargetGr(SegLine);
                Window.Update(1, Round(i / NoOfRecords * 10000, 1));
            until SegLine.Next() = 0;
            Window.Close();
        end;

        InteractLogEntry.SetCurrentKey("Campaign No.", "Campaign Target");
        InteractLogEntry.SetRange("Campaign No.", Campaign."No.");
        InteractLogEntry.SetRange("Campaign Target", true);
        InteractLogEntry.SetRange(Postponed, false);
        if InteractLogEntry.Find('-') then begin
            Found := true;
            i := 0;
            Window.Open(
              Text006 +
              Text008);
            NoOfRecords := InteractLogEntry.Count;
            repeat
                i := i + 1;
                AddInteractionLogEntry(InteractLogEntry);
                Window.Update(1, Round(i / NoOfRecords * 10000, 1));
            until InteractLogEntry.Next() = 0;
            Window.Close();
        end;
        if Found then begin
            Commit();
            Message(Text000, Campaign.TableCaption(), Campaign."No.")
        end else
            Error(Text002, SegLine.TableCaption(), Campaign.TableCaption(), SegLine.FieldCaption("Campaign Target"));
    end;

    procedure DeactivateCampaign(var Campaign: Record Campaign; ShowMessage: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeactivateCampaign(Campaign, ShowMessage, IsHandled);
        if IsHandled then
            exit;

        CampaignTargetGr.LockTable();

        CampaignTargetGr.SetCurrentKey("Campaign No.");
        CampaignTargetGr.SetRange("Campaign No.", Campaign."No.");
        if not CampaignTargetGr.IsEmpty() then
            CampaignTargetGr.DeleteAll();
        if ShowMessage then
            Message(Text001, Campaign.TableCaption(), Campaign."No.");
    end;

    procedure AddSegLinetoTargetGr(SegLine: Record "Segment Line")
    begin
        if (SegLine."Campaign No." <> '') and SegLine."Campaign Target" then begin
            ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
            ContBusRel.SetRange("Contact No.", SegLine."Contact Company No.");
            if ContBusRel.FindFirst() then
                InsertTargetGroup(CampaignTargetGr.Type::Customer, ContBusRel."No.", SegLine."Campaign No.")
            else
                InsertTargetGroup(
                  CampaignTargetGr.Type::Contact, SegLine."Contact Company No.", SegLine."Campaign No.");
            OnAfterAddSegLineToTargetGroup(CampaignTargetGr, SegLine);
        end;
    end;

    procedure DeleteSegfromTargetGr(SegLine: Record "Segment Line")
    var
        SegLine2: Record "Segment Line";
    begin
        if SegLine."Campaign No." <> '' then begin
            SegLine2.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
            SegLine2.SetRange("Campaign No.", SegLine."Campaign No.");
            SegLine2.SetRange("Contact Company No.", SegLine."Contact Company No.");
            SegLine2.SetRange("Campaign Target", true);

            InteractLogEntry.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
            InteractLogEntry.SetRange("Campaign No.", SegLine."Campaign No.");
            InteractLogEntry.SetRange("Contact Company No.", SegLine."Contact Company No.");
            InteractLogEntry.SetRange("Campaign Target", true);
            InteractLogEntry.SetRange(Postponed, false);

            if SegLine2.Count + InteractLogEntry.Count = 1 then begin
                ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("Contact No.", SegLine."Contact Company No.");

                if ContBusRel.FindFirst() then begin
                    if CampaignTargetGr.Get(
                         CampaignTargetGr.Type::Customer, ContBusRel."No.", SegLine."Campaign No.")
                    then
                        CampaignTargetGr.Delete();
                end else
                    if CampaignTargetGr.Get(
                         CampaignTargetGr.Type::Contact, SegLine."Contact No.", SegLine."Campaign No.")
                    then
                        CampaignTargetGr.Delete();
            end;
        end;
    end;

    procedure AddInteractionLogEntry(InteractionLogEntry: Record "Interaction Log Entry")
    begin
        if (InteractionLogEntry."Campaign No." <> '') and InteractionLogEntry."Campaign Target" then begin
            ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
            ContBusRel.SetRange("Contact No.", InteractionLogEntry."Contact Company No.");
            if ContBusRel.FindFirst() then
                InsertTargetGroup(CampaignTargetGr.Type::Customer, ContBusRel."No.", InteractionLogEntry."Campaign No.")
            else
                InsertTargetGroup(
                  CampaignTargetGr.Type::Contact, InteractionLogEntry."Contact Company No.", InteractionLogEntry."Campaign No.");
        end;
    end;

    procedure DeleteContfromTargetGr(InteractLogEntry: Record "Interaction Log Entry")
    var
        InteractLogEntry2: Record "Interaction Log Entry";
    begin
        if InteractLogEntry."Campaign No." <> '' then begin
            InteractLogEntry2.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
            InteractLogEntry2.SetRange("Campaign No.", InteractLogEntry."Campaign No.");
            InteractLogEntry2.SetRange("Contact Company No.", InteractLogEntry."Contact Company No.");
            InteractLogEntry2.SetRange("Campaign Target", true);
            InteractLogEntry2.SetRange(Postponed, false);

            SegLine.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
            SegLine.SetRange("Campaign No.", InteractLogEntry."Campaign No.");
            SegLine.SetRange("Contact Company No.", InteractLogEntry."Contact Company No.");
            SegLine.SetRange("Campaign Target", true);

            if InteractLogEntry2.Count + InteractLogEntry.Count = 1 then begin
                ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("Contact No.", InteractLogEntry."Contact Company No.");

                if ContBusRel.FindFirst() then begin
                    if CampaignTargetGr.Get(
                         CampaignTargetGr.Type::Customer, ContBusRel."No.", InteractLogEntry."Campaign No.")
                    then
                        CampaignTargetGr.Delete();
                end else
                    if CampaignTargetGr.Get(
                         CampaignTargetGr.Type::Contact, InteractLogEntry."Contact No.", InteractLogEntry."Campaign No.")
                    then
                        CampaignTargetGr.Delete();
            end;
        end;
    end;

    procedure ConverttoCustomer(Contact: Record Contact; Customer: Record Customer)
    var
        CampaignTargetGr2: Record "Campaign Target Group";
    begin
        CampaignTargetGr2.SetCurrentKey("No.");
        CampaignTargetGr2.SetRange("No.", Contact."No.");
        if CampaignTargetGr2.Find('-') then
            repeat
                InsertTargetGroup(
                  CampaignTargetGr2.Type::Customer, Customer."No.", CampaignTargetGr2."Campaign No.");
                CampaignTargetGr2.Delete();
            until CampaignTargetGr2.Next() = 0;
    end;

    procedure ConverttoContact(Cust: Record Customer; CompanyContNo: Code[20])
    var
        CampaignTargetGr2: Record "Campaign Target Group";
    begin
        CampaignTargetGr2.SetRange("No.", Cust."No.");
        if CampaignTargetGr2.Find('-') then
            repeat
                InsertTargetGroup(
                  CampaignTargetGr2.Type::Contact, CompanyContNo, CampaignTargetGr2."Campaign No.");
                CampaignTargetGr2.Delete();
            until CampaignTargetGr2.Next() = 0;
    end;

    local procedure InsertTargetGroup(Type: Option; No: Code[20]; CampaignNo: Code[20])
    begin
        CampaignTargetGr.Type := Type;
        CampaignTargetGr."No." := No;
        CampaignTargetGr."Campaign No." := CampaignNo;
        if not CampaignTargetGr.Insert(true) then;
    end;

    local procedure NoPriceDiscForCampaign(CampaignNo: Code[20]): Boolean
    var
        PriceListLine: Record "Price List Line";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if not PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            exit(NoPriceDiscV15ForCampaign(CampaignNo));
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::Campaign);
        PriceListLine.SetRange("Source No.", CampaignNo);
        exit(PriceListLine.IsEmpty());
    end;

    local procedure NoPriceDiscV15ForCampaign(CampaignNo: Code[20]): Boolean;
    var
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
    begin
        SalesPrice.SetCurrentKey("Sales Type", "Sales Code");
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
        SalesPrice.SetRange("Sales Code", CampaignNo);
        SalesLineDisc.SetCurrentKey("Sales Type", "Sales Code");
        SalesLineDisc.SetRange("Sales Type", SalesLineDisc."Sales Type"::Campaign);
        SalesLineDisc.SetRange("Sales Code", CampaignNo);
        exit(SalesPrice.IsEmpty() and SalesLineDisc.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSegLineToTargetGroup(var CampaignTargetGr: Record "Campaign Target Group"; var SegLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeActivateCampaign(var Campaign: Record Campaign; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeactivateCampaign(var Campaign: Record Campaign; ShowMessage: Boolean; var IsHandled: Boolean)
    begin
    end;
}

