// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Intrastat;

tableextension 11709 "Item Journal Line CZL" extends "Item Journal Line"
{
    fields
    {
        field(31079; "Invt. Movement Template CZL"; Code[10])
        {
            Caption = 'Inventory Movement Template';
            TableRelation = "Invt. Movement Template CZL";
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                InvtMovementTemplateCZL: Record "Invt. Movement Template CZL";
                ItemJournalTemplate: Record "Item Journal Template";
            begin
                if InvtMovementTemplateCZL.Get("Invt. Movement Template CZL") then begin
                    ItemJournalTemplate.Get("Journal Template Name");
                    case ItemJournalTemplate.Type of
                        ItemJournalTemplate.Type::Transfer:
                            InvtMovementTemplateCZL.TestField("Entry Type", InvtMovementTemplateCZL."Entry Type"::Transfer);
                        ItemJournalTemplate.Type::"Phys. Inventory":
                            if CurrFieldNo = FieldNo("Invt. Movement Template CZL") then
                                InvtMovementTemplateCZL.TestField("Entry Type", "Entry Type");
                    end;
                    if ItemJournalTemplate.Type <> ItemJournalTemplate.Type::"Phys. Inventory" then
                        Validate("Entry Type", InvtMovementTemplateCZL."Entry Type");
                    Validate("Gen. Bus. Posting Group", InvtMovementTemplateCZL."Gen. Bus. Posting Group");
                end;
            end;
        }
        field(11764; "G/L Correction CZL"; Boolean)
        {
            Caption = 'G/L Correction';
            DataClassification = CustomerContent;
        }
        field(11765; "Additional Currency Factor CZL"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Additional Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
            DataClassification = CustomerContent;
        }
    }
}
