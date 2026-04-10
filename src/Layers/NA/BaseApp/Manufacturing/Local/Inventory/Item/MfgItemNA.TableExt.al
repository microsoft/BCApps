#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Manufacturing.Document;

tableextension 10027 "Mfg. Item NA" extends Item
{
    fields
    {
        field(10013; "Rel. Scheduled Receipt (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const(Released),
                                                                                "Item No." = field("No."),
                                                                                "Variant Code" = field("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Filter"),
                                                                                "Bin Code" = field("Bin Filter"),
                                                                                "Due Date" = field("Date Filter")));
            Caption = 'Rel. Scheduled Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ObsoleteReason = 'Prepare for extraction of Manufacturing app';
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
        }
        field(10014; "Rel. Scheduled Need (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Prod. Order Component"."Remaining Qty. (Base)" where(Status = filter(Released),
                                                                                     "Item No." = field("No."),
                                                                                     "Variant Code" = field("Variant Filter"),
                                                                                     "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                     "Location Code" = field("Location Filter"),
                                                                                     "Bin Code" = field("Bin Filter"),
                                                                                     "Due Date" = field("Date Filter")));
            Caption = 'Rel. Scheduled Need (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ObsoleteReason = 'Prepare for extraction of Manufacturing app';
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
        }
    }
}
#endif
