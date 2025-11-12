// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.ADCS;
using System.Security.AccessControl;
using System.Security.User;

table 7301 "Warehouse Employee"
{
    Caption = 'Warehouse Employee';
    LookupPageID = "Warehouse Employee List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; Default; Boolean)
        {
            Caption = 'Default';
        }
        field(7710; "ADCS User"; Code[50])
        {
            Caption = 'ADCS User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "ADCS User".Name;

            trigger OnValidate()
            var
                WarehouseEmployee: Record "Warehouse Employee";
            begin
                if ("ADCS User" <> xRec."ADCS User") and ("ADCS User" <> '') then begin
                    WarehouseEmployee.SetRange("ADCS User", "ADCS User");
                    if not WarehouseEmployee.IsEmpty() then
                        Error(Text001);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "User ID", "Location Code")
        {
            Clustered = true;
        }
        key(Key2; Default)
        {
        }
        key(Key3; "Location Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Default then
            CheckDefault();
    end;

    trigger OnModify()
    begin
        if Default then
            CheckDefault();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You can only have one default location per user ID.';
        Text001: Label 'You can only assign an ADCS user name once.';
#pragma warning restore AA0074

    local procedure CheckDefault()
    var
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDefault(Rec, IsHandled);
        if IsHandled then
            exit;

        WhseEmployee.SetRange(Default, true);
        WhseEmployee.SetRange("User ID", "User ID");
        WhseEmployee.SetFilter("Location Code", '<>%1', "Location Code");
        if not WhseEmployee.IsEmpty() then
            Error(Text000);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDefault(var WarehouseEmployee: Record "Warehouse Employee"; var IsHandled: Boolean)
    begin
    end;
}

