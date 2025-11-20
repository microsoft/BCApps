// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Tracking;

tableextension 905 "Asm. Item" extends Item
{
    fields
    {
        field(929; "Res. Qty. on Assembly Order"; Decimal)
        {
            AccessByPermission = TableData "Assembly Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(900),
                                                                           "Source Subtype" = const("1"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(930; "Res. Qty. on  Asm. Comp."; Decimal)
        {
            AccessByPermission = TableData "Assembly Line" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(901),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on  Asm. Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(977; "Qty. on Assembly Order"; Decimal)
        {
            CalcFormula = sum("Assembly Header"."Remaining Quantity (Base)" where("Document Type" = const(Order),
                                                                                   "Item No." = field("No."),
                                                                                   "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Location Code" = field("Location Filter"),
                                                                                   "Variant Code" = field("Variant Filter"),
                                                                                   "Due Date" = field("Date Filter"),
                                                                                   "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(978; "Qty. on Asm. Component"; Decimal)
        {
            CalcFormula = sum("Assembly Line"."Remaining Quantity (Base)" where("Document Type" = const(Order),
                                                                                 Type = const(Item),
                                                                                 "No." = field("No."),
                                                                                 "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                 "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                 "Location Code" = field("Location Filter"),
                                                                                 "Variant Code" = field("Variant Filter"),
                                                                                 "Due Date" = field("Date Filter"),
                                                                                 "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Asm. Component';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
    }

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckAssemblyHeader() in codeunit CheckAssemblyDocument', '25.0')]
    procedure CheckAsmHeader(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckAssemblyDocument: Codeunit "Check Assembly Document";
    begin
        CheckAssemblyDocument.CheckAssemblyHeaders(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckAssemblyLine() in codeunit CheckAssemblyDocument', '25.0')]
    procedure CheckAsmLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        CheckAssemblyDocument: Codeunit "Check Assembly Document";
    begin
        CheckAssemblyDocument.CheckAssemblyLines(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;
#endif
}