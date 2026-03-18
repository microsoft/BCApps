// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

page 5375 "Synth. Relation Mapping"
{
    Caption = 'Relation Setup';
    SourceTableTemporary = true;
    SourceTable = "Synth. Relation Mapping Buffer";
    Editable = false;
    PageType = List;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Tables)
            {
                field("Virtual Table Caption"; Rec."Virtual Table Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    Editable = false;
                    Visible = Selecting = Selecting::VirtualTable;
                    ToolTip = 'Specifies the virtual table name.';
                }
                field("Virtual Table Logical Name"; Rec."Virtual Table Logical Name")
                {
                    ApplicationArea = All;
                    Caption = 'Logical Name';
                    Editable = false;
                    Visible = Selecting = Selecting::VirtualTable;
                    Tooltip = 'Specifies the virtual table logical name.';
                }
                field("Virtual Table Phys. Name"; Rec."Virtual Table Phys. Name")
                {
                    ApplicationArea = All;
                    Caption = 'Physical Name';
                    Editable = false;
                    Visible = Selecting = Selecting::VirtualTableApiID;
                    Tooltip = 'Specifies the virtual table physical name.';
                }
                field("Virtual Table API Page Id"; Rec."Virtual Table API Page Id")
                {
                    ApplicationArea = All;
                    Caption = 'Page ID';
                    Editable = false;
                    Visible = Selecting = Selecting::VirtualTableApiID;
                    ToolTip = 'Specifies the virtual table API page ID in Business Central.';
                }
                field("Syncd. Table Name"; Rec."Syncd. Table Name")
                {
                    ApplicationArea = All;
                    Caption = 'Integration Table Name';
                    Editable = false;
                    Visible = Selecting = Selecting::NativeTable;
                    Tooltip = 'Specifies the integration table name.';
                }
                field("Syncd. Table External Name"; Rec."Syncd. Table External Name")
                {
                    ApplicationArea = All;
                    Caption = 'External Table Name';
                    Editable = false;
                    Visible = Selecting = Selecting::NativeTable;
                    Tooltip = 'Specifies the integration table external name.';
                }
                field("Syncd. Field 1 Name"; Rec."Syncd. Field 1 Name")
                {
                    ApplicationArea = All;
                    Caption = 'Integration Field Name';
                    Editable = false;
                    Visible = Selecting = Selecting::NativeField;
                    Tooltip = 'Specifies the integration field name.';
                }
                field("Syncd. Field 1 External Name"; Rec."Syncd. Field 1 External Name")
                {
                    ApplicationArea = All;
                    Caption = 'External Field Name';
                    Editable = false;
                    Visible = Selecting = Selecting::NativeField;
                    Tooltip = 'Specifies the integration field external name.';
                }
                field("Virtual Table Column 1 Caption"; Rec."Virtual Table Column 1 Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Virtual Table Column Name';
                    Editable = false;
                    Visible = Selecting = Selecting::VirtualField;
                    Tooltip = 'Specifies the name of the virtual table''s column.';
                }
                field("Virtual Table Column 1 Name"; Rec."Virtual Table Column 1 Name")
                {
                    ApplicationArea = All;
                    Caption = 'Virtual Table Column Logical Name';
                    Editable = false;
                    Visible = Selecting = Selecting::VirtualField;
                    Tooltip = 'Specifies the logical name of the virtual tables''s column.';
                }
            }
        }
    }

    var
        Selecting: Option VirtualTable,NativeTable,VirtualField,NativeField,VirtualTableApiID;

    internal procedure SetSelectingVirtualTables()
    begin
        Selecting := Selecting::VirtualTable;
    end;

    internal procedure SetSelectingVirtualTablePageId()
    begin
        Selecting := Selecting::VirtualTableApiID;
    end;

    internal procedure SetSelectingNativeTables()
    begin
        Selecting := Selecting::NativeTable;
    end;

    internal procedure SetSelectingVirtualFields()
    begin
        Selecting := Selecting::VirtualField;
    end;

    internal procedure SetSelectingNativeFields()
    begin
        Selecting := Selecting::NativeField;
    end;

    internal procedure SetTables(var SynthRelationMapping: Record "Synth. Relation Mapping Buffer" temporary)
    begin
        if not SynthRelationMapping.FindSet() then
            exit;
        repeat
            Rec.Copy(SynthRelationMapping);
            Rec.Insert();
        until SynthRelationMapping.Next() = 0;
    end;

    internal procedure GetSelectedTable(var SynthRelationMapping: Record "Synth. Relation Mapping Buffer")
    begin
        CurrPage.SetSelectionFilter(SynthRelationMapping);
        SynthRelationMapping.FindFirst();
    end;
}
