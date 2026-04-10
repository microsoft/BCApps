// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

table 8363 "Dimension Perspective Name"
{
    Caption = 'Dimension Perspective Name';
    DataCaptionFields = Name;
    DataClassification = CustomerContent;
    LookupPageId = "Dimension Perspectives";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the description of the dimension perspective. The description is not shown on the final report but is used to provide more context when using the definition.';
        }
        field(3; "Internal Description"; Text[250])
        {
            Caption = 'Internal Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the internal description of the dimension perspective. The internal description is not shown on the final report but is used to provide more context when using the definition.';
        }
        field(4; "Perspective Type"; Enum "Dimension Perspective Type")
        {
            Caption = 'Perspective Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the financial report dimension perspectives will be totaled by. If you select Custom, then you can set up a combination of fields to total by on a dimension-by-dimension basis. Otherwise, perspectives are automatically created and totaled by each dimension value or business unit.';
        }
        field(5; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View';
            DataClassification = CustomerContent;
            TableRelation = "Analysis View";
            ToolTip = 'Specifies the name of the analysis view you want the dimension perspective to use. This field is optional.';

            trigger OnValidate()
            begin
                ValidateAnalysisViewName();
            end;
        }
    }

    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        DimPerspectiveLine: Record "Dimension Perspective Line";
    begin
        DimPerspectiveLine.SetRange(Name, Name);
        DimPerspectiveLine.DeleteAll(true);
    end;

    var
        ClearDimensionTotalingConfirmTxt: Label 'Changing Analysis View will clear differing dimension totaling columns of Dimension Perspective Lines. \Do you want to continue?';

    procedure LookupPerspectiveType(var PerspectiveTypeText: Text): Boolean
    var
        DimSelection: Page "Dimension Selection";
        IDimPerspective: Interface IDimensionPerspective;
        Ordinal: Integer;
        NewPerspectiveType: Text;
    begin
        foreach Ordinal in Enum::"Dimension Perspective Type".Ordinals() do begin
            IDimPerspective := Enum::"Dimension Perspective Type".FromInteger(Ordinal);
            IDimPerspective.InsertBufferForPerspectiveTotalingLookup(this, Enum::"Dimension Perspective Type".FromInteger(Ordinal), DimSelection);
        end;

        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = Action::LookupOK then begin
            NewPerspectiveType := DimSelection.GetDimSelCode();
            if UpperCase(NewPerspectiveType) <> UpperCase(PerspectiveTypeText) then begin
                PerspectiveTypeText := NewPerspectiveType;
                exit(true);
            end;
        end;
    end;

    procedure PerspectiveTypeToText(PerspectiveType: Enum "Dimension Perspective Type") Result: Text
    var
        IDimPerspective: Interface IDimensionPerspective;
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"Dimension Perspective Type".Ordinals() do begin
            IDimPerspective := Enum::"Dimension Perspective Type".FromInteger(Ordinal);
            if IDimPerspective.PerspectiveTypeToText(this, PerspectiveType, Result) then
                exit(Result);
        end;
    end;

    procedure TextToPerspectiveType(Text: Text) Type: Enum "Dimension Perspective Type"
    var
        IDimPerspective: Interface IDimensionPerspective;
        Ordinal: Integer;
    begin
        Text := UpperCase(Text);
        foreach Ordinal in Enum::"Dimension Perspective Type".Ordinals() do begin
            IDimPerspective := Enum::"Dimension Perspective Type".FromInteger(Ordinal);
            if IDimPerspective.TextToPerspectiveType(this, Text, Type) then
                exit(Type);
        end;
    end;

    local procedure ValidateAnalysisViewName()
    var
        AnalysisView: Record "Analysis View";
        DimPerspectiveLine: Record "Dimension Perspective Line";
        xAnalysisView: Record "Analysis View";
        ConfirmManagement: Codeunit "Confirm Management";
        ClearConfirmed: Boolean;
        DimsToClear: array[4] of Boolean;
        i: Integer;
    begin
        if "Analysis View Name" = xRec."Analysis View Name" then
            exit;

        AnalysisViewGet(AnalysisView, "Analysis View Name");
        AnalysisViewGet(xAnalysisView, xRec."Analysis View Name");

        DimPerspectiveLine.SetRange(Name, Name);
        for i := 1 to 4 do begin
            if GetDimCodeByNum(AnalysisView, i) = GetDimCodeByNum(xAnalysisView, i) then
                continue;
            case i of
                1:
                    DimPerspectiveLine.SetFilter("Dimension 1 Totaling", '<>%1', '');
                2:
                    DimPerspectiveLine.SetFilter("Dimension 2 Totaling", '<>%1', '');
                3:
                    DimPerspectiveLine.SetFilter("Dimension 3 Totaling", '<>%1', '');
                4:
                    DimPerspectiveLine.SetFilter("Dimension 4 Totaling", '<>%1', '');
            end;
            if not DimPerspectiveLine.IsEmpty() then begin
                if not ClearConfirmed then
                    if ConfirmManagement.GetResponseOrDefault(ClearDimensionTotalingConfirmTxt, true) then
                        ClearConfirmed := true
                    else
                        Error('');
                DimsToClear[i] := true;
            end;
        end;

        if not ClearConfirmed then
            exit;

        DimPerspectiveLine.Reset();
        DimPerspectiveLine.SetRange(Name, Name);
        if DimPerspectiveLine.FindSet() then
            repeat
                if DimsToClear[1] then
                    DimPerspectiveLine."Dimension 1 Totaling" := '';
                if DimsToClear[2] then
                    DimPerspectiveLine."Dimension 2 Totaling" := '';
                if DimsToClear[3] then
                    DimPerspectiveLine."Dimension 3 Totaling" := '';
                if DimsToClear[4] then
                    DimPerspectiveLine."Dimension 4 Totaling" := '';
                DimPerspectiveLine.Modify(true);
            until DimPerspectiveLine.Next() = 0;
    end;

    local procedure AnalysisViewGet(var AnalysisView: Record "Analysis View"; AnalysisViewName: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if AnalysisView.Get(AnalysisViewName) then
            exit;
        if AnalysisView.Name = '' then begin
            GLSetup.Get();
            AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;
    end;

    local procedure GetDimCodeByNum(AnalysisView: Record "Analysis View"; DimNumber: Integer): Code[20]
    begin
        case DimNumber of
            1:
                exit(AnalysisView."Dimension 1 Code");
            2:
                exit(AnalysisView."Dimension 2 Code");
            3:
                exit(AnalysisView."Dimension 3 Code");
            4:
                exit(AnalysisView."Dimension 4 Code");
        end;
    end;
}