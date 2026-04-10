// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Structure;

tableextension 99000761 "Mfg. Location" extends Location
{
    fields
    {
        field(7314; "To-Production Bin Code"; Code[20])
        {
            Caption = 'To-Production Bin Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin in the production area where components picked for production are placed by default, before they can be consumed.';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "To-Production Bin Code", FieldCaption("To-Production Bin Code"), Code);
            end;
        }
        field(7315; "From-Production Bin Code"; Code[20])
        {
            Caption = 'From-Production Bin Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin in the production area, where finished end items are taken from by default, when the process involves warehouse activity.';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "From-Production Bin Code", FieldCaption("From-Production Bin Code"), Code);
            end;
        }
        field(7316; "Prod. Consump. Whse. Handling"; Enum "Prod. Consump. Whse. Handling")
        {
            Caption = 'Prod. Consump. Whse. Handling';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if Rec."Prod. Consump. Whse. Handling" <> xRec."Prod. Consump. Whse. Handling" then
                    CheckInventoryActivityExists(Rec.Code, Database::"Prod. Order Component", Rec.FieldCaption("Prod. Consump. Whse. Handling"));
            end;
        }
        field(7318; "Prod. Output Whse. Handling"; Enum "Prod. Output Whse. Handling")
        {
            Caption = 'Prod. Output Whse. Handling';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if Rec."Directed Put-away and Pick" then
                    if Rec."Prod. Output Whse. Handling" = Rec."Prod. Output Whse. Handling"::"Inventory Put-away" then
                        Error(InvalidProdOutputHandlingErr, Rec."Prod. Output Whse. Handling", Rec.TableCaption, Rec.Code, Rec.FieldCaption("Directed Put-away and Pick"));
            end;
        }
        field(7350; "Missing SKU Planning Policy"; Enum "Missing SKU Planning Policy")
        {
            Caption = 'Missing SKU Planning Policy';
            DataClassification = SystemMetadata;
        }
        field(7351; "SKU Creation Policy"; Enum "SKU Creation Policy")
        {
            Caption = 'SKU Creation Policy';
            DataClassification = SystemMetadata;
        }
    }

    procedure IsBinBWProdOutput(BinCode: Code[20]): Boolean
    begin
        exit(("To-Production Bin Code" <> '') and (BinCode = "To-Production Bin Code"));
    end;

    procedure RequireWhsePutAwayForProdOutput(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        Location.SetLoadFields("Prod. Output Whse. Handling");
        if Location.Get(LocationCode) then
            exit(Location."Prod. Output Whse. Handling" = Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
    end;

    var
        InvalidProdOutputHandlingErr: Label 'You cannot select %1 on %2 %3 when %4 is enabled.', Comment = '%1 = Inventory Put-away, %2 = Location Table Caption, %3 = Location Code, %4 =  Directed Put-away Field Caption';
}
