// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sustainability.EUDR;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

pageextension 6319 "EUDR Lot No. Information Card" extends "Lot No. Information Card"
{
    layout
    {
        addlast(content)
        {
            group(EUDR)
            {
                Caption = 'EUDR';
                Visible = EUDRVisible;

                field("EUDR Certificate No."; Rec."EUDR Certificate No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Certification Scheme"; Rec."Certification Scheme")
                {
                    ApplicationArea = ItemTracking;
                }
                field("EUDR Valid From"; Rec."EUDR Valid From")
                {
                    ApplicationArea = ItemTracking;
                }
                field("EUDR Valid To"; Rec."EUDR Valid To")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Country/Region of Production Code"; Rec."Country/Region of Prod. Code")
                {
                    ApplicationArea = ItemTracking;
                }
                field("DDS Reference Number"; Rec."DDS Reference Number")
                {
                    ApplicationArea = ItemTracking;
                }
                field("DDS Verification No."; Rec."DDS Verification No.")
                {
                    ApplicationArea = ItemTracking;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetControlVisibility();
        EUDRLotInformationMgmt.SetCountryRegionCode(TrackingSpecification);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetControlVisibility();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetCountryOfProductionFromSource();
    end;

    trigger OnClosePage()
    begin
        EUDRLotInformationMgmt.ClearCountryRegionCode();
    end;

    var
        EUDRLotInformationMgmt: Codeunit "EUDR Lot Info. Tracking Mgmt";
        EUDRVisible: Boolean;

    local procedure SetControlVisibility()
    var
        Item: Record Item;
    begin
        EUDRVisible := false;
        if Item.Get(Rec."Item No.") then
            EUDRVisible := Item."EUDR Relevant";
    end;

    local procedure SetCountryOfProductionFromSource()
    var
        Item: Record Item;
    begin
        if Rec."Country/Region of Prod. Code" <> '' then
            exit;

        if not Item.Get(Rec."Item No.") then
            exit;

        if not Item."EUDR Relevant" then
            exit;

        if EUDRLotInformationMgmt.GetCurrentCountryRegionCode() <> '' then
            Rec.Validate("Country/Region of Prod. Code", EUDRLotInformationMgmt.GetCurrentCountryRegionCode());
    end;
}