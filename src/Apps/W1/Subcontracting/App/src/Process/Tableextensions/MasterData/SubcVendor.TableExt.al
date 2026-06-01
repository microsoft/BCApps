// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

tableextension 99001507 "Subc. Vendor" extends Vendor
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001515; "Subc. Location Code"; Code[10])
        {
            Caption = 'Subcontracting Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location where("Use As In-Transit" = const(false));
            trigger OnValidate()
            var
                Location: Record Location;
                ErrorInfo: ErrorInfo;
            begin
                if "Subc. Location Code" = '' then
                    exit;
                Location.Get("Subc. Location Code");
                if Location."Bin Mandatory" or Location."Require Pick" or Location."Require Put-away" or Location."Require Receive" or Location."Require Shipment" then begin
                    ErrorInfo.Title := CannotUseLocationLbl;
                    ErrorInfo.Message := StrSubstNo(BinWarehouseEnabledOnLocationErr, "Subc. Location Code");
                    ErrorInfo.Verbosity := ErrorInfo.Verbosity::Error;
                    ErrorInfo.PageNo := Page::"Location Card";
                    ErrorInfo.RecordId := Location.RecordId;
                    ErrorInfo.AddNavigationAction(ShowLocationCardLbl);
                    Error(ErrorInfo);
                end;
            end;
        }
        field(99001516; "Subc. Linked to Work Center"; Boolean)
        {
            CalcFormula = exist("Work Center" where("Subcontractor No." = field("No.")));
            Caption = 'Linked to Work Center';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99001517; "Subc. Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center" where("Subcontractor No." = field("No."));
        }
    }

    keys
    {
        key(SubcLocationCode; "Subc. Location Code") { }
    }

    var
        CannotUseLocationLbl: Label 'Cannot user the location for subcontracting';
        ShowLocationCardLbl: Label 'Show Location Card';
        BinWarehouseEnabledOnLocationErr: Label 'Location %1 cannot be used as a subcontracting location because Bin Mandatory or warehouse handling is enabled on the location.', Comment = '%1 = Location Code';
}