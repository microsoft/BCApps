// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.GLAccount;
using System.Telemetry;

page 706 "IC Dim Values Selector"
{
    Caption = 'Intercompany Dimension Values Selector';
    PageType = List;
    SourceTable = "Dimension Value";
    Editable = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(DimCode; Rec."Dimension Code")
                {
                    Caption = 'Dimension Code';
                    ToolTip = 'Specifies the dimension code for the dimension value.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(Code; Rec."Code")
                {
                    Caption = 'Code';
                    ToolTip = 'Specifies the code for the dimension value.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the dimension value.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action(CopyFromDimensionValues)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Copy from Dimension Values';
                    Image = CopyDimensions;
                    ToolTip = 'Creates intercompany dimension values using the selected dimension values as a template.';

                    trigger OnAction()
                    begin
                        CopyFromDimValuesToICDimValues();
                    end;
                }
            }
        }
        area(Promoted)
        {
            actionref(CopyFromDimensionValues_Promoted; CopyFromDimensionValues)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Dimension Code", DimensionCode);
    end;

    var
        DimensionCode: Code[20];
        CopyFromDimValuesQst: Label 'Are you sure you want to copy the selected dimension values?';
        DimValuesCopiedAskToCloseQst: Label 'Successfully added to the intercompany dimension values.\Do you want to close the page?';
        SelectedDimValuesAlreadyExistMsg: Label 'Selected dimension values already exist as intercompany dimension values.';

    procedure SetDimensionCode(SourceDimCode: Code[20])
    begin
        DimensionCode := SourceDimCode;
    end;

    local procedure CopyFromDimValuesToICDimValues()
    var
        DimensionValue: Record "Dimension Value";
        ICDimensionValue: Record "IC Dimension Value";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandle: Boolean;
        ICDimValEmpty: Boolean;
        ICDimValExists: Boolean;
        DimValueAlreayExists: Boolean;
        PrevIndentation: Integer;
        DimValuesCopied: Boolean;
    begin
        if not Confirm(CopyFromDimValuesQst, true) then
            exit;

        FeatureTelemetry.LogUptake('0000KOP', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        IsHandle := false;
        OnBeforeSelectingDimensionValue(IsHandle, DimensionValue);
        if not IsHandle then
            CurrPage.SetSelectionFilter(DimensionValue);

        ICDimensionValue.LockTable();
        if not DimensionValue.IsEmpty() then begin
            DimensionValue.FindSet();
            ICDimensionValue.SetRange("Dimension Code", DimensionValue."Dimension Code");
            ICDimValEmpty := not ICDimensionValue.FindFirst();
            repeat
                if DimensionValue."Dimension Value Type" = DimensionValue."Dimension Value Type"::"End-Total" then
                    PrevIndentation := PrevIndentation - 1;
                if not ICDimValEmpty then
                    ICDimValExists := ICDimensionValue.Get(DimensionValue."Dimension Code", DimensionValue.Code);
                if not ICDimValExists and not DimensionValue.Blocked then begin
                    ICDimensionValue.Init();
                    ICDimensionValue."Dimension Code" := DimensionValue."Dimension Code";
                    ICDimensionValue.Code := DimensionValue.Code;
                    ICDimensionValue.Name := DimensionValue.Name;
                    ICDimensionValue."Dimension Value Type" := DimensionValue."Dimension Value Type";
                    ICDimensionValue.Indentation := PrevIndentation;
                    ICDimensionValue.Insert();
                    DimValuesCopied := true;
                end
                else
                    DimValueAlreayExists := true;
                PrevIndentation := ICDimensionValue.Indentation;
                if DimensionValue."Dimension Value Type" = DimensionValue."Dimension Value Type"::"Begin-Total" then
                    PrevIndentation := PrevIndentation + 1;
            until DimensionValue.Next() = 0;
        end;
        if GuiAllowed() then
            if DimValuesCopied then begin
                if Confirm(DimValuesCopiedAskToCloseQst, false) then
                    CurrPage.Close();
            end
            else
                if DimValueAlreayExists then
                    Message(SelectedDimValuesAlreadyExistMsg);

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectingDimensionValue(var IsHandled: Boolean; var DimensionValue: Record "Dimension Value")
    begin
    end;
}
