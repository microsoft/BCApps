// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

#if not CLEAN29
using Microsoft.Foundation.UOM;
#endif
using Microsoft.Inventory.Item;

tableextension 7417 "Excise Item Ext" extends Item
{
    fields
    {
        field(7412; "Excise Tax Type"; Code[20])
        {
            Caption = 'Excise Tax Type';
            TableRelation = "Excise Tax Type".Code where(Enabled = const(true));
            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Item Excise Tax table to support multiple excise taxes per item.';
            ObsoleteTag = '29.0';
#endif
        }
        field(7413; "Quantity for Excise Tax"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity for Excise Tax';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Item Excise Tax table to support multiple excise taxes per item.';
            ObsoleteTag = '29.0';
#endif
        }
        field(7414; "Excise Unit of Measure Code"; Code[10])
        {
            Caption = 'Excise Tax Unit of Measure Code';
#if not CLEAN29
            TableRelation = "Unit of Measure".Code;
#endif

            DataClassification = CustomerContent;
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Item Excise Tax table to support multiple excise taxes per item.';
            ObsoleteTag = '29.0';
#endif
        }
    }
}