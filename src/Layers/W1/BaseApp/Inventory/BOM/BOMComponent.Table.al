// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

table 90 "BOM Component"
{
    Caption = 'BOM Component';
    DrillDownPageID = "Assembly BOM";
    LookupPageID = "Assembly BOM";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Parent Item No."; Code[20])
        {
            Caption = 'Parent Item No.';
            ToolTip = 'Specifies the number of the assembly item that the assembly BOM component belongs to.';
            NotBlank = true;
            TableRelation = Item where(Type = const(Inventory));
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Enum "BOM Component Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies if the assembly BOM component is an item or a resource.';

            trigger OnValidate()
            begin
                "No." := '';
                "Variant Code" := '';
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(Item)) Item where(Type = filter(Inventory | "Non-Inventory"))
            else
            if (Type = const(Resource)) Resource;

            trigger OnValidate()
            begin
                TestField(Type);
                "Variant Code" := '';
                if "No." = '' then
                    exit;

                case Type of
                    Type::Item:
                        CopyFromItem();
                    Type::Resource:
                        CopyFromResource();
                end;
            end;
        }
        field(5; "Assembly BOM"; Boolean)
        {
            CalcFormula = exist("BOM Component" where("Parent Item No." = field("No.")));
            Caption = 'Assembly BOM';
            ToolTip = 'Specifies if the assembly BOM component is an assembly BOM.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the assembly BOM component.';
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));
        }
        field(8; "Quantity per"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity per';
            ToolTip = 'Specifies how many units of the component are required to assemble or produce the parent item.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Quantity per" < 0 then
                    Error(QtyPerCannotBeNegativeErr);
            end;
        }
        field(9; Position; Code[10])
        {
            Caption = 'Position';
            ToolTip = 'Specifies the position of the component on the bill of material.';
        }
        field(10; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
            ToolTip = 'Specifies the component''s position in the assembly BOM structure.';
        }
        field(11; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
            ToolTip = 'Specifies the third reference number for the component position on a bill of material, such as the alternate position number of a component on a print card.';
        }
        field(12; "Machine No."; Code[10])
        {
            Caption = 'Machine No.';
            ToolTip = 'Specifies a machine that should be used when processing the component on this line of the assembly BOM.';
        }
        field(13; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';
            ToolTip = 'Specifies the total number of days required to assemble the item on the assembly BOM line.';
        }
        field(14; "BOM Description"; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Parent Item No.")));
            Caption = 'BOM Description';
            ToolTip = 'Specifies a description of the assembly BOM if the item on the line is an assembly BOM.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Resource Usage Type"; Option)
        {
            Caption = 'Resource Usage Type';
            ToolTip = 'Specifies how the cost of the resource on the assembly BOM is allocated during assembly.';
            OptionCaption = 'Direct,Fixed';
            OptionMembers = Direct,"Fixed";

            trigger OnValidate()
            begin
                if "Resource Usage Type" = xRec."Resource Usage Type" then
                    exit;

                TestField(Type, Type::Resource);
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));

            trigger OnValidate()
            begin
                if Rec."Variant Code" = '' then
                    exit;
                TestField(Type, Type::Item);
                TestField("No.");
                ItemVariant.Get("No.", "Variant Code");
                Description := ItemVariant.Description;
            end;
        }
        field(5900; "Installed in Line No."; Integer)
        {
            Caption = 'Installed in Line No.';

            trigger OnLookup()
            begin
                BOMComp.Reset();
                BOMComp.SetRange("Parent Item No.", "Parent Item No.");
                BOMComp.SetRange(Type, BOMComp.Type::Item);
                BOMComp.SetFilter("Line No.", '<>%1', "Line No.");
                Clear(AssemblyBOM);
                AssemblyBOM.SetTableView(BOMComp);
                AssemblyBOM.Editable(false);
                AssemblyBOM.LookupMode(true);
                if AssemblyBOM.RunModal() = ACTION::LookupOK then begin
                    AssemblyBOM.GetRecord(BOMComp);
                    Validate("Installed in Line No.", BOMComp."Line No.");
                end;
            end;

            trigger OnValidate()
            begin
                if "Installed in Line No." <> 0 then begin
                    if "Installed in Line No." = "Line No." then
                        Error(Text000, FieldCaption("Installed in Line No."));
                    BOMComp.Reset();
                    BOMComp.SetRange("Parent Item No.", "Parent Item No.");
                    BOMComp.SetRange(Type, BOMComp.Type::Item);
                    BOMComp.SetRange("Line No.", "Installed in Line No.");
                    BOMComp.FindFirst();
                    BOMComp.TestField("Quantity per", 1);
                    "Installed in Item No." := BOMComp."No.";
                end else
                    "Installed in Item No." := '';
            end;
        }
        field(5901; "Installed in Item No."; Code[20])
        {
            Caption = 'Installed in Item No.';
            ToolTip = 'Specifies which service item the component on the line is used in.';
            TableRelation = if (Type = const(Item)) Item;

            trigger OnLookup()
            begin
                BOMComp.Reset();
                BOMComp.SetRange("Parent Item No.", "Parent Item No.");
                BOMComp.SetRange(Type, BOMComp.Type::Item);
                BOMComp."No." := "Installed in Item No.";
                BOMComp.SetFilter("Line No.", '<>%1', "Line No.");
                Clear(AssemblyBOM);
                AssemblyBOM.SetTableView(BOMComp);
                AssemblyBOM.Editable(false);
                AssemblyBOM.LookupMode(true);
                if AssemblyBOM.RunModal() = ACTION::LookupOK then begin
                    AssemblyBOM.GetRecord(BOMComp);
                    Validate("Installed in Line No.", BOMComp."Line No.");
                end;
            end;

            trigger OnValidate()
            begin
                if "Installed in Item No." <> '' then begin
                    BOMComp.Reset();
                    BOMComp.SetRange("Parent Item No.", "Parent Item No.");
                    BOMComp.SetRange(Type, BOMComp.Type::Item);
                    BOMComp.SetRange("No.", "Installed in Item No.");
                    BOMComp.FindFirst();
                end;

                Validate("Installed in Line No.", BOMComp."Line No.");
            end;
        }
    }

    keys
    {
        key(Key1; "Parent Item No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Type, "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Item.Get("Parent Item No.");
        if Type = Type::Item then
            ValidateAgainstRecursion("No.")
    end;

    trigger OnModify()
    begin
        Item.Get("Parent Item No.");
        if Type = Type::Item then
            ValidateAgainstRecursion("No.")
    end;

    trigger OnRename()
    begin
        Item.Get("Parent Item No.");
        if Type = Type::Item then
            ValidateAgainstRecursion("No.")
    end;

    var
        Item: Record Item;
        ParentItem: Record Item;
        Res: Record Resource;
        ItemVariant: Record "Item Variant";
        BOMComp: Record "BOM Component";
        AssemblyBOM: Page "Assembly BOM";
        QtyPerCannotBeNegativeErr: Label 'Quantity per cannot be negative.';

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be component of itself.';
        Text001: Label 'You cannot insert item %1 as an assembly component of itself.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure ValidateAgainstRecursion(ItemNo: Code[20])
    var
        BOMComp: Record "BOM Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateAgainstRecursion(ItemNo, IsHandled, Rec);
        if IsHandled then
            exit;

        if "Parent Item No." = ItemNo then
            Error(Text001, ItemNo);

        if Type = Type::Item then begin
            BOMComp.SetCurrentKey(Type, "No.");
            BOMComp.SetRange(Type, Type::Item);
            BOMComp.SetRange("No.", "Parent Item No.");
            if BOMComp.FindSet() then
                repeat
                    BOMComp.ValidateAgainstRecursion(ItemNo);
                until BOMComp.Next() = 0
        end
    end;

    local procedure CopyFromItem()
    var
        IsHandled: Boolean;
    begin
        Item.Get("No.");
        ValidateAgainstRecursion("No.");
        IsHandled := false;
        OnBeforeCopyFromItem(Rec, xRec, Item, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Item.CalcFields("Assembly BOM");
        "Assembly BOM" := Item."Assembly BOM";
        Description := Item.Description;
        "Unit of Measure Code" := Item."Base Unit of Measure";
        ParentItem.Get("Parent Item No.");
        OnCopyFromItemOnAfterGetParentItem(Item, ParentItem);
        Item.Find();
        ParentItem.Find();
        if ParentItem."Low-Level Code" >= Item."Low-Level Code" then
            Error(Text001, "No.");

        OnAfterCopyFromItem(Rec, Item);
    end;

    local procedure CopyFromResource()
    begin
        Res.Get("No.");
        "Assembly BOM" := false;
        Description := Res.Name;
        "Unit of Measure Code" := Res."Base Unit of Measure";

        OnAfterCopyFromResource(Rec, Res);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var BOMComponent: Record "BOM Component"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromResource(var BOMComponent: Record "BOM Component"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var BOMComponent: Record "BOM Component"; xBOMComponent: Record "BOM Component"; Item: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnCopyFromItemOnAfterGetParentItem(var Item: Record Item; ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateAgainstRecursion(ItemNo: Code[20]; var IsHandled: Boolean; var BOMComponent: Record "BOM Component")
    begin
    end;
}

