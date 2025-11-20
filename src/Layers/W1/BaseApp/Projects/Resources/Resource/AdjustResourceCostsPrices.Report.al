// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Utilities;

report 1195 "Adjust Resource Costs/Prices"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Resource Costs/Prices';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Resource; Resource)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Resource Group No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");

                case Selection of
                    Selection::"Direct Unit Cost":
                        OldFieldNo := "Direct Unit Cost";
                    Selection::"Indirect Cost %":
                        OldFieldNo := "Indirect Cost %";
                    Selection::"Unit Cost":
                        OldFieldNo := "Unit Cost";
                    Selection::"Profit %":
                        OldFieldNo := "Profit %";
                    Selection::"Unit Price":
                        OldFieldNo := "Unit Price";
                end;

                NewFieldNo := OldFieldNo * AdjFactor;

                if RoundingMethod.Code <> '' then begin
                    RoundingMethod."Minimum Amount" := NewFieldNo;
                    if RoundingMethod.Find('=<') then begin
                        NewFieldNo := NewFieldNo + RoundingMethod."Amount Added Before";
                        if RoundingMethod.Precision > 0 then
                            NewFieldNo := Round(NewFieldNo, RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                        NewFieldNo := NewFieldNo + RoundingMethod."Amount Added After";
                    end;
                end;

                case Selection of
                    Selection::"Direct Unit Cost":
                        Validate("Direct Unit Cost", NewFieldNo);
                    Selection::"Indirect Cost %":
                        Validate("Indirect Cost %", NewFieldNo);
                    Selection::"Unit Cost":
                        Validate("Unit Cost", NewFieldNo);
                    Selection::"Profit %":
                        Validate("Profit %", NewFieldNo);
                    Selection::"Unit Price":
                        Validate("Unit Price", NewFieldNo);
                end;

                Modify();
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Selection; Selection)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Adjust Field';
                        OptionCaption = 'Direct Unit Cost,Indirect Cost %,Unit Cost,Profit %,Unit Price';
                        ToolTip = 'Specifies the type of cost or price to be adjusted.';
                    }
                    field(AdjFactor; AdjFactor)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Adjustment Factor';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies an adjustment factor to multiply the amounts that you want suggested. By entering an adjustment factor, you can increase or decrease the amounts that are suggested.';
                    }
                    field("RoundingMethod.Code"; RoundingMethod.Code)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Rounding Method';
                        TableRelation = "Rounding Method";
                        ToolTip = 'Specifies a code for the rounding method that you want to apply to costs or prices that you adjust.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if AdjFactor = 0 then
                AdjFactor := 1;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        RoundingMethod.SetRange(Code, RoundingMethod.Code);
    end;

    var
        RoundingMethod: Record "Rounding Method";
        Window: Dialog;
        NewFieldNo: Decimal;
        OldFieldNo: Decimal;
        AdjFactor: Decimal;
        Selection: Option "Direct Unit Cost","Indirect Cost %","Unit Cost","Profit %","Unit Price";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Processing resources  #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InitializeRequest(SelectionFrom: Option; AdjFactorFrom: Decimal; RoundingMethodCode: Code[10])
    begin
        Selection := SelectionFrom;
        AdjFactor := AdjFactorFrom;
        RoundingMethod.Code := RoundingMethodCode;
    end;
}

