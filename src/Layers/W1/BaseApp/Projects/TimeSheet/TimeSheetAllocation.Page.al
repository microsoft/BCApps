// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Utilities;

page 970 "Time Sheet Allocation"
{
    Caption = 'Time Sheet Allocation';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            grid(General)
            {
                Caption = 'General';
                group(Control2)
                {
                    ShowCaption = false;
                    field(TotalQty; TotalQty)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Total Quantity';
                        Editable = false;
                        ToolTip = 'Specifies the allocation of posted time sheet lines.';
                    }
                    field(AllocatedQty; AllocatedQty)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Allocated Quantity';
                        Editable = false;
                        ToolTip = 'Specifies the sum of the hours that have been allocated on the time sheet. The allocated number of hours must equal the total number of hours.';
                    }
                }
            }
            grid("Time Sheet Period")
            {
                Caption = 'Time Sheet Period';
                group(Control13)
                {
                    ShowCaption = false;
                    field(DateQuantity1; DateQuantity[1])
                    {
                        ApplicationArea = Jobs;
                        CaptionClass = '3,' + DateDescription[1];

                        trigger OnValidate()
                        begin
                            UpdateQty();
                        end;
                    }
                    field(DateQuantity2; DateQuantity[2])
                    {
                        ApplicationArea = Jobs;
                        CaptionClass = '3,' + DateDescription[2];

                        trigger OnValidate()
                        begin
                            UpdateQty();
                        end;
                    }
                    field(DateQuantity3; DateQuantity[3])
                    {
                        ApplicationArea = Jobs;
                        CaptionClass = '3,' + DateDescription[3];

                        trigger OnValidate()
                        begin
                            UpdateQty();
                        end;
                    }
                    field(DateQuantity4; DateQuantity[4])
                    {
                        ApplicationArea = Jobs;
                        CaptionClass = '3,' + DateDescription[4];

                        trigger OnValidate()
                        begin
                            UpdateQty();
                        end;
                    }
                    field(DateQuantity5; DateQuantity[5])
                    {
                        ApplicationArea = Jobs;
                        CaptionClass = '3,' + DateDescription[5];

                        trigger OnValidate()
                        begin
                            UpdateQty();
                        end;
                    }
                    field(DateQuantity6; DateQuantity[6])
                    {
                        ApplicationArea = Jobs;
                        CaptionClass = '3,' + DateDescription[6];

                        trigger OnValidate()
                        begin
                            UpdateQty();
                        end;
                    }
                    field(DateQuantity7; DateQuantity[7])
                    {
                        ApplicationArea = Jobs;
                        CaptionClass = '3,' + DateDescription[7];

                        trigger OnValidate()
                        begin
                            UpdateQty();
                        end;
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
        Calendar: Record Date;
        i: Integer;
    begin
        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");
        if Calendar.FindSet() then
            repeat
                i += 1;
                DateDescription[i] := TimeSheetMgt.FormatDate(Calendar."Period Start", 0);
                if TimeSheetDetail.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.", Calendar."Period Start") then
                    DateQuantity[i] := TimeSheetDetail.Quantity;
            until Calendar.Next() = 0;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            if TotalQty <> AllocatedQty then
                Error(Text001);
    end;

    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        DateDescription: array[7] of Text[30];
        DateQuantity: array[7] of Decimal;
        TotalQty: Decimal;
        AllocatedQty: Decimal;
#pragma warning disable AA0074
        Text001: Label 'Allocated quantity must be equal to total quantity.';
#pragma warning restore AA0074

    procedure InitParameters(TimeSheetNo: Code[20]; TimeSheetLineNo: Integer; QtyToAllocate: Decimal)
    begin
        TimeSheetHeader.Get(TimeSheetNo);
        TimeSheetLine.Get(TimeSheetNo, TimeSheetLineNo);
        TotalQty := QtyToAllocate;
        AllocatedQty := QtyToAllocate;
    end;

    local procedure UpdateQty()
    var
        i: Integer;
    begin
        AllocatedQty := 0;
        for i := 1 to 7 do
            AllocatedQty += DateQuantity[i];
    end;

    procedure GetAllocation(var Quantity: array[7] of Decimal)
    begin
        CopyArray(Quantity, DateQuantity, 1);
    end;
}

