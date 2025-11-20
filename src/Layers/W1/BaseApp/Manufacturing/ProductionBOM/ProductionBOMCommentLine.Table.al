// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

table 99000776 "Production BOM Comment Line"
{
    Caption = 'Production BOM Comment Line';
    DrillDownPageID = "Prod. BOM Comment List";
    LookupPageID = "Prod. BOM Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            NotBlank = true;
            TableRelation = "Production BOM Header";
        }
        field(2; "BOM Line No."; Integer)
        {
            Caption = 'BOM Line No.';
            NotBlank = true;
            TableRelation = "Production BOM Line"."Line No." where("Production BOM No." = field("Production BOM No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
            TableRelation = "Production BOM Version"."Version Code" where("Production BOM No." = field("Production BOM No."),
                                                                           "Version Code" = field("Version Code"));
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
        }
        field(12; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(13; "Code"; Code[10])
        {
            Caption = 'Code';
        }
    }

    keys
    {
        key(Key1; "Production BOM No.", "BOM Line No.", "Version Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
    begin
        ProductionBOMCommentLine.SetRange("Production BOM No.", "Production BOM No.");
        ProductionBOMCommentLine.SetRange("Version Code", "Version Code");
        ProductionBOMCommentLine.SetRange("BOM Line No.", "BOM Line No.");
        ProductionBOMCommentLine.SetRange(Date, WorkDate());
        if not ProductionBOMCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ProductionBOMCommentLine);
    end;

    procedure Caption(): Text
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        if GetFilters = '' then
            exit('');

        if not ProdBOMHeader.Get("Production BOM No.") then
            exit('');

        exit(
          StrSubstNo('%1 %2 %3',
            "Production BOM No.", ProdBOMHeader.Description, "BOM Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ProductionBOMCommentLineRec: Record "Production BOM Comment Line"; var ProductionBOMCommentLineFilter: Record "Production BOM Comment Line")
    begin
    end;
}

