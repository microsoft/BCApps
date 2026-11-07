// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Inventory.Counting.Recording;

page 30237 "APIV2 - Phys. Inv. Rec. Lines"
{
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    APIVersion = 'v2.0';
    EntityCaption = 'Physical Inventory Recording Line';
    EntitySetCaption = 'Physical Inventory Recording Lines';
    PageType = API;
    ODataKeyFields = SystemId;
    EntityName = 'physicalInventoryRecordingLine';
    EntitySetName = 'physicalInventoryRecordingLines';
    SourceTable = "Phys. Invt. Record Line";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(orderNumber; Rec."Order No.")
                {
                    Caption = 'Order No.';
                    Editable = false;
                }
                field(recordingNumber; Rec."Recording No.")
                {
                    Caption = 'Recording No.';
                    Editable = false;
                }
                field(sequence; Rec."Line No.")
                {
                    Caption = 'Sequence';
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit Of Measure Code';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(recorded; Rec.Recorded)
                {
                    Caption = 'Recorded';
                }
                field(dateRecorded; Rec."Date Recorded")
                {
                    Caption = 'Date Recorded';
                }
                field(timeRecorded; Rec."Time Recorded")
                {
                    Caption = 'Time Recorded';
                }
                field(personRecorded; Rec."Person Recorded")
                {
                    Caption = 'Person Recorded';
                }
                field(serialNumber; Rec."Serial No.")
                {
                    Caption = 'Serial No.';
                }
                field(lotNumber; Rec."Lot No.")
                {
                    Caption = 'Lot No.';
                }
                field(packageNumber; Rec."Package No.")
                {
                    Caption = 'Package No.';
                }
                field(shelfNumber; Rec."Shelf No.")
                {
                    Caption = 'Shelf No.';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }
}
