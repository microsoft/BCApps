// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.GLAccount;
using System.Telemetry;

page 705 "IC Dimensions Selector"
{
    Caption = 'Intercompany Dimensions Selector';
    PageType = List;
    SourceTable = Dimension;
    Editable = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Code; Rec."Code")
                {
                    Caption = 'Code';
                    ToolTip = 'Specifies the code for the dimension.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the dimension.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field("Code Caption"; Rec."Code Caption")
                {
                    Caption = 'Code Caption';
                    ToolTip = 'Specifies the caption of the dimension. This is displayed as the name of dimension fields.';
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
                action(CopyFromDimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Copy from Dimensions';
                    Image = CopyDimensions;
                    ToolTip = 'Creates intercompany dimensions using the selected dimensions as a template.';

                    trigger OnAction()
                    begin
                        CopyFromDimensionsToICDim();
                    end;
                }
            }
        }
        area(Promoted)
        {
            actionref(CopyFromDimensions_Promoted; CopyFromDimensions)
            {
            }
        }
    }

    var
        CopyFromDimensionsQst: Label 'Are you sure you want to copy the selected dimensions? This action will overwritte any existing intercompany dimension value.';
        DimensionsCopiedAskToCloseQst: Label 'Successfully added to the intercompany dimensions.\Do you want to close the page?';
        SelectedDimensionsAlreadyExistMsg: Label 'Selected dimensions already exist as intercompany dimensions.';

    local procedure CopyFromDimensionsToICDim()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandle: Boolean;
        ICDimValEmpty: Boolean;
        ICDimValExists: Boolean;
        DimensionAlreayExists: Boolean;
        DimensionsCopied: Boolean;
        DimensionValuesCopied: Boolean;
        PrevIndentation: Integer;
    begin

        if not Confirm(CopyFromDimensionsQst, true) then
            exit;

        FeatureTelemetry.LogUptake('0000IL2', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        IsHandle := false;
        OnBeforeSelectingDimensions(IsHandle, Dimension);
        if not IsHandle then
            CurrPage.SetSelectionFilter(Dimension);

        ICDimensionValue.LockTable();
        ICDimension.LockTable();
        DimensionsCopied := false;
        if not Dimension.IsEmpty() then begin
            Dimension.FindSet();
            repeat
                if not ICDimension.Get(Dimension.Code) then begin
                    DimensionsCopied := true;
                    ICDimension.Init();
                    ICDimension.Code := Dimension.Code;
                    ICDimension.Name := Dimension.Name;
                    ICDimension.Insert();
                end else
                    DimensionAlreayExists := true;

                ICDimValExists := false;
                DimensionValue.SetRange("Dimension Code", Dimension.Code);
                ICDimensionValue.SetRange("Dimension Code", Dimension.Code);
                if not ICDimensionValue.IsEmpty() then
                    ICDimensionValue.DeleteAll(true);
                ICDimValEmpty := not ICDimensionValue.FindFirst();
                if not DimensionValue.isEmpty() then begin
                    DimensionValue.FindSet();
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
                            ICDimensionValue."Map-to Dimension Code" := ICDimension."Map-to Dimension Code";
                            ICDimensionValue.Indentation := PrevIndentation;
                            ICDimensionValue.Insert();
                            DimensionValuesCopied := true;
                        end;
                        PrevIndentation := ICDimensionValue.Indentation;
                        if DimensionValue."Dimension Value Type" = DimensionValue."Dimension Value Type"::"Begin-Total" then
                            PrevIndentation := PrevIndentation + 1;
                    until DimensionValue.Next() = 0;
                end;
            until Dimension.Next() = 0;
        end;
        if GuiAllowed() then
            if DimensionsCopied or DimensionValuesCopied then begin
                if Confirm(DimensionsCopiedAskToCloseQst, false) then
                    CurrPage.Close();
            end
            else
                if DimensionAlreayExists then
                    Message(SelectedDimensionsAlreadyExistMsg);

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectingDimensions(var IsHandled: Boolean; var Dimension: Record Dimension)
    begin
    end;
}
