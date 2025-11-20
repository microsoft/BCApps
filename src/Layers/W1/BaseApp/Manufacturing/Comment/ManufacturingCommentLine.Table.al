// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Comment;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

table 99000770 "Manufacturing Comment Line"
{
    Caption = 'Manufacturing Comment Line';
    DrillDownPageID = "Manufacturing Comment List";
    LookupPageID = "Manufacturing Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Enum "Mfg. Comment Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if ("Table Name" = const("Work Center")) "Work Center"
            else
            if ("Table Name" = const("Machine Center")) "Machine Center"
            else
            if ("Table Name" = const("Routing Header")) "Routing Header"
            else
            if ("Table Name" = const("Production BOM Header")) "Production BOM Header";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        ManufacturingCommentLine: Record "Manufacturing Comment Line";
    begin
        ManufacturingCommentLine.SetRange("Table Name", "Table Name");
        ManufacturingCommentLine.SetRange("No.", "No.");
        ManufacturingCommentLine.SetRange(Date, WorkDate());
        if not ManufacturingCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ManufacturingCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ManufacturingCommentLineRec: Record "Manufacturing Comment Line"; var ManufacturingCommentLineFilter: Record "Manufacturing Comment Line")
    begin
    end;
}

