// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Document;

tableextension 99000761 "Mfg. Location" extends Location
{
    fields
    {
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
    }

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
