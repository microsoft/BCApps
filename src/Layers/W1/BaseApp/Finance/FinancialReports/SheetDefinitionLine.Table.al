// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

table 8364 "Sheet Definition Line"
{
    Caption = 'Sheet Definition Line';
    DataClassification = CustomerContent;
    LookupPageId = "Sheet Definition";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            TableRelation = "Sheet Definition Name";
            ToolTip = 'Specifies the name of the financial report sheet definition.';
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the line number for the financial report sheet.';
        }
        field(4; "Sheet Header"; Text[30])
        {
            Caption = 'Sheet Header';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a header for the sheet.';
            NotBlank = true;
        }
        field(7; "Business Unit Totaling"; Text[80])
        {
            Caption = 'Business Unit Totaling';
            DataClassification = CustomerContent;
            TableRelation = "Business Unit";
            ToolTip = 'Specifies which business unit amounts will be totaled on this sheet.';
            ValidateTableRelation = false;
        }
        field(8; "Dimension 1 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            Caption = 'Dimension 1 Totaling';
            DataClassification = CustomerContent;
            CaptionClass = GetCaptionClass(1);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(1, Rec."Dimension 1 Totaling");
            end;
        }
        field(9; "Dimension 2 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            DataClassification = CustomerContent;
            Caption = 'Dimension 2 Totaling';
            CaptionClass = GetCaptionClass(2);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(2, Rec."Dimension 2 Totaling");
            end;
        }
        field(10; "Dimension 3 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            DataClassification = CustomerContent;
            Caption = 'Dimension 3 Totaling';
            CaptionClass = GetCaptionClass(3);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(3, Rec."Dimension 3 Totaling");
            end;
        }
        field(11; "Dimension 4 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            Caption = 'Dimension 4 Totaling';
            CaptionClass = GetCaptionClass(4);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(4, Rec."Dimension 4 Totaling");
            end;
        }
        field(12; "Dimension 5 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            DataClassification = CustomerContent;
            Caption = 'Dimension 5 Totaling';
            CaptionClass = GetCaptionClass(5);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(5, Rec."Dimension 5 Totaling");
            end;
        }
        field(13; "Dimension 6 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            DataClassification = CustomerContent;
            Caption = 'Dimension 6 Totaling';
            CaptionClass = GetCaptionClass(6);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(6, Rec."Dimension 6 Totaling");
            end;
        }
        field(14; "Dimension 7 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            DataClassification = CustomerContent;
            Caption = 'Dimension 7 Totaling';
            CaptionClass = GetCaptionClass(7);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(7, Rec."Dimension 7 Totaling");
            end;
        }
        field(15; "Dimension 8 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            DataClassification = CustomerContent;
            Caption = 'Dimension 8 Totaling';
            CaptionClass = GetCaptionClass(8);
            ToolTip = 'Specifies which dimension value amounts will be totaled on this sheet.';

            trigger OnLookup()
            begin
                LookUpDimFilter(8, Rec."Dimension 8 Totaling");
            end;
        }
    }

    keys
    {
        key(PK; Name, "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Sheet Header");
    end;

    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        SheetDefName: Record "Sheet Definition Name";
        DimensionCodes: array[8] of Text[20];
        HasGLSetup: Boolean;
        DimensionTxt: Label '1,5,%1,, Totaling', Comment = '%1 = Dimension Code';
        DimensionGenericTxt: Label '1,5,,Dimension %1 Totaling', Comment = '%1 = Dimension No.';
        MissingAnalysisViewMsg: Label 'The %1 refers to %2 %3, which does not exist. The field %4 on table %1 has now been deleted.', Comment = '%1 = Sheet Def Name, %2 = Analysis View, %3 = Analysis View Name, %4 = Analysis View Field';

    local procedure LookUpDimFilter(DimNo: Integer; var Result: Text[80])
    var
        DimValue: Record "Dimension Value";
        DimValueList: Page "Dimension Value List";
    begin
        GetDimensionCodes();
        DimValue.SetRange("Dimension Code", DimensionCodes[DimNo]);
        if DimValue.GetFilter("Dimension Code") = '' then
            exit;
        DimValueList.LookupMode(true);
        DimValueList.SetTableView(DimValue);
        if DimValueList.RunModal() = Action::LookupOK then begin
            DimValueList.GetRecord(DimValue);
            Result := CopyStr(DimValueList.GetSelectionFilter(), 1, MaxStrLen(Result));
        end;
    end;

    local procedure GetCaptionClass(DimNo: Integer) Result: Text[250]
    begin
        GetDimensionCodes();
        Result := DimensionCodes[DimNo] = '' ?
            StrSubstNo(DimensionGenericTxt, DimNo) :
            StrSubstNo(DimensionTxt, DimensionCodes[DimNo]);
    end;

    local procedure GetDimensionCodes()
    begin
        GetDefinitionName();
        if SheetDefName."Analysis View Name" <> '' then
            if SheetDefName."Analysis View Name" <> AnalysisView.Code then
                if not AnalysisView.Get(SheetDefName."Analysis View Name") then begin
                    Message(MissingAnalysisViewMsg, SheetDefName.TableCaption(),
                        AnalysisView.TableCaption(), SheetDefName."Analysis View Name",
                        SheetDefName.FieldCaption("Analysis View Name"));
                    SheetDefName."Analysis View Name" := '';
                    SheetDefName.Modify();
                end;
        if SheetDefName."Analysis View Name" = '' then begin
            if not HasGLSetup then begin
                GLSetup.Get();
                HasGLSetup := true;
            end;
            DimensionCodes[1] := GLSetup."Global Dimension 1 Code";
            DimensionCodes[2] := GLSetup."Global Dimension 2 Code";
            DimensionCodes[3] := GLSetup."Shortcut Dimension 3 Code";
            DimensionCodes[4] := GLSetup."Shortcut Dimension 4 Code";
            DimensionCodes[5] := GLSetup."Shortcut Dimension 5 Code";
            DimensionCodes[6] := GLSetup."Shortcut Dimension 6 Code";
            DimensionCodes[7] := GLSetup."Shortcut Dimension 7 Code";
            DimensionCodes[8] := GLSetup."Shortcut Dimension 8 Code";
        end else begin
            Clear(DimensionCodes);
            DimensionCodes[1] := AnalysisView."Dimension 1 Code";
            DimensionCodes[2] := AnalysisView."Dimension 2 Code";
            DimensionCodes[3] := AnalysisView."Dimension 3 Code";
            DimensionCodes[4] := AnalysisView."Dimension 4 Code";
        end;
    end;

    local procedure GetDefinitionName()
    begin
        if Name <> SheetDefName.Name then
            SheetDefName.Get(Name);
    end;
}