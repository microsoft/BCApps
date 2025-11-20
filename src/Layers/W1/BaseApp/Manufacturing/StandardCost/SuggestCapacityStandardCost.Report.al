// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;
using System.Utilities;

report 5852 "Suggest Capacity Standard Cost"
{
    Caption = 'Suggest Work/Mach Ctr Std Cost';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Work Center"; "Work Center")
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                if not (WorkSheetSource in [WorkSheetSource::"Work Center", WorkSheetSource::All]) then
                    CurrReport.Skip();

                InsertStdCostWksh(1, "No.");
                if CurrentDateTime - WindowUpdateDateTime >= 750 then begin
                    Window.Update(1, "No.");
                    WindowUpdateDateTime := CurrentDateTime;
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                WindowUpdateDateTime := CurrentDateTime;
                Window.Open(Text007 + Text008);
            end;
        }
        dataitem("Machine Center"; "Machine Center")
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                if not (WorkSheetSource in [WorkSheetSource::"Machine Center", WorkSheetSource::All]) then
                    CurrReport.Skip();

                InsertStdCostWksh(2, "No.");
                if CurrentDateTime - WindowUpdateDateTime >= 750 then begin
                    Window.Update(1, "No.");
                    WindowUpdateDateTime := CurrentDateTime;
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                WindowUpdateDateTime := CurrentDateTime;
                Window.Open(Text007 + Text009);
            end;
        }
        dataitem(Resource; Resource)
        {

            trigger OnAfterGetRecord()
            begin
                if not (WorkSheetSource in [WorkSheetSource::Resource, WorkSheetSource::All]) then
                    CurrReport.Skip();

                InsertStdCostWksh(3, "No.");
                if CurrentDateTime - WindowUpdateDateTime >= 750 then begin
                    Window.Update(1, "No.");
                    WindowUpdateDateTime := CurrentDateTime;
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                WindowUpdateDateTime := CurrentDateTime;
                Window.Open(Text007 + Text010);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Standard Cost")
                    {
                        Caption = 'Standard Cost';
                        field("AmtAdjustFactor[1]"; AmtAdjustFactor[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Adjustment Factor';
                            DecimalPlaces = 0 : 5;
                            MinValue = 0;
                            NotBlank = true;
                            ToolTip = 'Specifies an adjustment factor to multiply the capacity that you want suggested. By entering an adjustment factor, you can increase or decrease the amounts that are suggested.';
                        }
                        field("RoundingMethod[1]"; RoundingMethod[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Rounding Method';
                            TableRelation = "Rounding Method";
                            ToolTip = 'Specifies a code for the rounding method that you want to apply to costs that you adjust.';
                        }
                    }
                    group("Indirect Cost %")
                    {
                        Caption = 'Indirect Cost %';
                        field("AmtAdjustFactor[2]"; AmtAdjustFactor[2])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Adjustment Factor';
                            DecimalPlaces = 0 : 5;
                            MinValue = 0;
                            NotBlank = true;
                            ToolTip = 'Specifies an adjustment factor to multiply the capacity that you want suggested. By entering an adjustment factor, you can increase or decrease the amounts that are suggested.';
                        }
                        field("RoundingMethod[2]"; RoundingMethod[2])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Rounding Method';
                            TableRelation = "Rounding Method";
                            ToolTip = 'Specifies a code for the rounding method that you want to apply to costs that you adjust.';
                        }
                    }
                    group("Overhead Rate")
                    {
                        Caption = 'Overhead Rate';
                        field("AmtAdjustFactor[3]"; AmtAdjustFactor[3])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Adjustment Factor';
                            DecimalPlaces = 0 : 5;
                            MinValue = 0;
                            NotBlank = true;
                            ToolTip = 'Specifies an adjustment factor to multiply the capacity that you want suggested. By entering an adjustment factor, you can increase or decrease the amounts that are suggested.';
                        }
                        field("RoundingMethod[3]"; RoundingMethod[3])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Rounding Method';
                            TableRelation = "Rounding Method";
                            ToolTip = 'Specifies a code for the rounding method that you want to apply to costs that you adjust.';
                        }
                        field(Source; WorkSheetSource)
                        {
                            Caption = 'Source';
                            ApplicationArea = All;
                            ToolTip = 'Specifies the Type of Standard Cost Worksheet.';
                            OptionCaption = 'All,Work Center,Machine Center,Resource';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            i: Integer;
        begin
            for i := 1 to ArrayLen(AmtAdjustFactor) do
                if AmtAdjustFactor[i] = 0 then
                    AmtAdjustFactor[i] := 1;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        StdCostWkshName: Record "Standard Cost Worksheet Name";
    begin
        if ToStdCostWkshName = '' then
            Error(Text004);
        StdCostWkshName.Get(ToStdCostWkshName);

        ToStdCostWksh.LockTable();
    end;

    var
        ToStdCostWksh: Record "Standard Cost Worksheet";
        Window: Dialog;
        ToStdCostWkshName: Code[10];
        RoundingMethod: array[3] of Code[10];
        AmtAdjustFactor: array[3] of Decimal;
        WindowUpdateDateTime: DateTime;
        WorkSheetSource: Option All,"Work Center","Machine Center",Resource;

#pragma warning disable AA0074
        Text004: Label 'You must specify a worksheet name to copy to.';
        Text007: Label 'Copying worksheet...\\';
#pragma warning disable AA0470
        Text008: Label 'Work Center No. #1####################\';
        Text009: Label 'Machine Center No. #1####################\';
        Text010: Label 'Resource No. #1####################\';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure InsertStdCostWksh(Type2: Option; No2: Code[20])
    begin
        ToStdCostWksh.Init();
        ToStdCostWksh.Validate("Standard Cost Worksheet Name", ToStdCostWkshName);
        ToStdCostWksh.Validate(Type, Type2);
        ToStdCostWksh.Validate("No.", No2);

        ToStdCostWksh.Validate(
            "New Standard Cost",
            RoundAndAdjustAmt(ToStdCostWksh."Standard Cost", RoundingMethod[1], AmtAdjustFactor[1]));
        ToStdCostWksh.Validate(
            "New Indirect Cost %",
            RoundAndAdjustAmt(ToStdCostWksh."Indirect Cost %", RoundingMethod[2], AmtAdjustFactor[2]));
        ToStdCostWksh.Validate(
            "New Overhead Rate",
            RoundAndAdjustAmt(ToStdCostWksh."Overhead Rate", RoundingMethod[3], AmtAdjustFactor[3]));

        OnInsertStdCostWkshOnBeforeInsert(ToStdCostWksh, RoundingMethod, AmtAdjustFactor);
        if not ToStdCostWksh.Insert(true) then
            ToStdCostWksh.Modify(true);
    end;

    procedure RoundAndAdjustAmt(Amt: Decimal; RoundingMethodCode: Code[10]; AmtAdjustFactor: Decimal): Decimal
    var
        RoundingMethod: Record "Rounding Method";
        Sign: Decimal;
    begin
        if Amt = 0 then
            exit(Amt);

        Amt := Round(Amt * AmtAdjustFactor, 0.00001);

        if RoundingMethodCode <> '' then begin
            if Amt >= 0 then
                Sign := 1
            else
                Sign := -1;

            RoundingMethod.SetRange(Code, RoundingMethodCode);
            RoundingMethod.Code := RoundingMethodCode;
            RoundingMethod."Minimum Amount" := Abs(Amt);
            if RoundingMethod.Find('=<') then begin
                Amt := Amt + Sign * RoundingMethod."Amount Added Before";
                if RoundingMethod.Precision > 0 then
                    Amt := Sign * Round(Abs(Amt), RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                Amt := Amt + Sign * RoundingMethod."Amount Added After";
            end;
        end;

        exit(Amt);
    end;

    procedure SetCopyToWksh(ToStdCostWkshName2: Code[10])
    begin
        ToStdCostWkshName := ToStdCostWkshName2;
    end;

    procedure Initialize(ToStdCostWkshName2: Code[10]; AmtAdjustFactor1: Decimal; AmtAdjustFactor2: Decimal; AmtAdjustFactor3: Decimal; RoundingMethod1: Code[10]; RoundingMethod2: Code[10]; RoundingMethod3: Code[10])
    begin
        ToStdCostWkshName := ToStdCostWkshName2;
        AmtAdjustFactor[1] := AmtAdjustFactor1;
        AmtAdjustFactor[2] := AmtAdjustFactor2;
        AmtAdjustFactor[3] := AmtAdjustFactor3;
        RoundingMethod[1] := RoundingMethod1;
        RoundingMethod[2] := RoundingMethod2;
        RoundingMethod[3] := RoundingMethod3;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertStdCostWkshOnBeforeInsert(var ToStandardCostWorksheet: Record "Standard Cost Worksheet"; RoundingMethod: array[3] of Code[10]; AmtAdjustFactor: array[3] of Decimal)
    begin
    end;
}

