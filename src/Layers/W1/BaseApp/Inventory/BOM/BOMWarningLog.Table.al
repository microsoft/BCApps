// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.Item;
using System.Reflection;

table 5874 "BOM Warning Log"
{
    Caption = 'BOM Warning Log';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Warning Description"; Text[250])
        {
            Caption = 'Warning Description';
        }
        field(6; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(7; "Table Position"; Text[250])
        {
            Caption = 'Table Position';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetWarning(TheWarning: Text[250]; TheTableID: Integer; TheTablePosition: Text[250])
    begin
        "Entry No." := "Entry No." + 1;
        "Warning Description" := TheWarning;
        "Table ID" := TheTableID;
        "Table Position" := TheTablePosition;
        Insert();
    end;

    procedure ShowWarning()
    var
        Item: Record Item;
        RecRef: RecordRef;
    begin
        if "Table ID" = 0 then
            exit;

        RecRef.Open("Table ID");
        RecRef.SetPosition("Table Position");

        case "Table ID" of
            DATABASE::Item:
                begin
                    RecRef.SetTable(Item);
                    Item.SetRecFilter();
                    PAGE.RunModal(PAGE::"Item Card", Item);
                end;
        end;

        OnAfterShowWarning(Rec, RecRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowWarning(var BOMWarningLog: Record "BOM Warning Log"; RecRef: RecordRef)
    begin
    end;
}

