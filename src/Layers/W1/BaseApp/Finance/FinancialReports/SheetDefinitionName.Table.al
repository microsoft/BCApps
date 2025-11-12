// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

table 8363 "Sheet Definition Name"
{
    Caption = 'Sheet Definition Name';
    DataCaptionFields = Name;
    DataClassification = CustomerContent;
    LookupPageId = "Sheet Definitions";

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
            ToolTip = 'Specifies the description of the sheet definition. The description is not shown on the final report but is used to provide more context when using the definition.';
        }
        field(3; "Internal Description"; Text[250])
        {
            Caption = 'Internal Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the internal description of the sheet definition. The internal description is not shown on the final report but is used to provide more context when using the definition.';
        }
        field(4; "Sheet Type"; Enum "Sheet Type")
        {
            Caption = 'Sheet Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the financial report sheets will be totaled by. If you select Custom, then you can set up a combination of fields to total by on a sheet-by-sheet basis. Otherwise, sheets are automatically created and totaled by each dimension value or business unit.';
        }
        field(5; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View';
            DataClassification = CustomerContent;
            TableRelation = "Analysis View";
            ToolTip = 'Specifies the name of the analysis view you want the sheet definition to use. This field is optional.';

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
        SheetDefLine: Record "Sheet Definition Line";
    begin
        SheetDefLine.SetRange(Name, Name);
        SheetDefLine.DeleteAll(true);
    end;

    var
        ClearDimensionTotalingConfirmTxt: Label 'Changing Analysis View will clear differing dimension totaling columns of Sheet Definition Lines. \Do you want to continue?';

    procedure LookupSheetSheetType(var SheetTypeText: Text): Boolean
    var
        DimSelection: Page "Dimension Selection";
        ISheetDefinition: Interface ISheetDefinition;
        Ordinal: Integer;
        NewSheetType: Text;
    begin
        foreach Ordinal in Enum::"Sheet Type".Ordinals() do begin
            ISheetDefinition := Enum::"Sheet Type".FromInteger(Ordinal);
            ISheetDefinition.InsertBufferForSheetTotalingLookup(this, Enum::"Sheet Type".FromInteger(Ordinal), DimSelection);
        end;

        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = Action::LookupOK then begin
            NewSheetType := DimSelection.GetDimSelCode();
            if UpperCase(NewSheetType) <> UpperCase(SheetTypeText) then begin
                SheetTypeText := NewSheetType;
                exit(true);
            end;
        end;
    end;

    procedure SheetTypeToText(SheetType: Enum "Sheet Type") Result: Text
    var
        ISheetDefinition: Interface ISheetDefinition;
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"Sheet Type".Ordinals() do begin
            ISheetDefinition := Enum::"Sheet Type".FromInteger(Ordinal);
            if ISheetDefinition.SheetTypeToText(this, SheetType, Result) then
                exit(Result);
        end;
    end;

    procedure TextToSheetType(Text: Text) Type: Enum "Sheet Type"
    var
        ISheetDefinition: Interface ISheetDefinition;
        Ordinal: Integer;
    begin
        Text := UpperCase(Text);
        foreach Ordinal in Enum::"Sheet Type".Ordinals() do begin
            ISheetDefinition := Enum::"Sheet Type".FromInteger(Ordinal);
            if ISheetDefinition.TextToSheetType(this, Text, Type) then
                exit(Type);
        end;
    end;

    local procedure ValidateAnalysisViewName()
    var
        AnalysisView: Record "Analysis View";
        SheetDefLine: Record "Sheet Definition Line";
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

        SheetDefLine.SetRange(Name, Name);
        for i := 1 to 4 do begin
            if GetDimCodeByNum(AnalysisView, i) = GetDimCodeByNum(xAnalysisView, i) then
                continue;
            case i of
                1:
                    SheetDefLine.SetFilter("Dimension 1 Totaling", '<>%1', '');
                2:
                    SheetDefLine.SetFilter("Dimension 2 Totaling", '<>%1', '');
                3:
                    SheetDefLine.SetFilter("Dimension 3 Totaling", '<>%1', '');
                4:
                    SheetDefLine.SetFilter("Dimension 4 Totaling", '<>%1', '');
            end;
            if not SheetDefLine.IsEmpty() then begin
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

        SheetDefLine.Reset();
        SheetDefLine.SetRange(Name, Name);
        if SheetDefLine.FindSet() then
            repeat
                if DimsToClear[1] then
                    SheetDefLine."Dimension 1 Totaling" := '';
                if DimsToClear[2] then
                    SheetDefLine."Dimension 2 Totaling" := '';
                if DimsToClear[3] then
                    SheetDefLine."Dimension 3 Totaling" := '';
                if DimsToClear[4] then
                    SheetDefLine."Dimension 4 Totaling" := '';
                SheetDefLine.Modify(true);
            until SheetDefLine.Next() = 0;
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