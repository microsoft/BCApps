// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Tracking;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Resources;

tableextension 6452 "Serv. Item" extends Item
{
    fields
    {
        field(5900; "Service Item Group"; Code[10])
        {
            Caption = 'Service Item Group';
            DataClassification = CustomerContent;
            TableRelation = "Service Item Group".Code;

            trigger OnValidate()
            var
                ResourceSkill: Record "Resource Skill";
                ResourceSkillMgt: Codeunit "Resource Skill Mgt.";
            begin
                if xRec."Service Item Group" <> "Service Item Group" then begin
                    if not ResourceSkillMgt.ChangeResSkillRelationWithGroup(
                         ResourceSkill.Type::Item,
                         "No.",
                         ResourceSkill.Type::"Service Item Group",
                         "Service Item Group",
                         xRec."Service Item Group")
                    then
                        "Service Item Group" := xRec."Service Item Group";
                end else
                    ResourceSkillMgt.RevalidateResSkillRelation(
                      ResourceSkill.Type::Item,
                      "No.",
                      ResourceSkill.Type::"Service Item Group",
                      "Service Item Group")
            end;
        }
        field(5901; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = sum("Service Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                              Type = const(Item),
                                                                              "No." = field("No."),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Needed by Date" = field("Date Filter"),
                                                                              "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5902; "Res. Qty. on Service Orders"; Decimal)
        {
            AccessByPermission = TableData "Service Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(5902),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Service Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key12; "Service Item Group")
        {
        }
    }
}
