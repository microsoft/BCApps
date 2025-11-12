// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

report 6035 "Upd. Disc.% on Contract"
{
    Caption = 'Upd. Disc.% on Contract';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Contract Line"; "Service Contract Line")
        {
            RequestFilterFields = "Contract Type", "Contract No.";

            trigger OnAfterGetRecord()
            begin
                SuspendStatusCheck(true);
                if "Line Discount %" + DiscountPct <= 0 then
                    Validate("Line Discount %", 0)
                else
                    Validate("Line Discount %", "Line Discount %" + DiscountPct);
                Modify(true);
                i := i + 1;
            end;

            trigger OnPostDataItem()
            begin
                if i > 0 then begin
                    UpdateContractAnnualAmount(false);
                    Message(Text000);
                end
            end;

            trigger OnPreDataItem()
            begin
                if DiscountPct = 0 then
                    CurrReport.Break();
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
                    field(DiscountPct; DiscountPct)
                    {
                        ApplicationArea = Service;
                        Caption = 'Add/Subtract Discount %';
                        ToolTip = 'Specifies if any contract discount percent is included in the batch job. ';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if DiscountPct = 0 then
            Error(Text001);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Service contract lines have been updated.';
#pragma warning restore AA0074
        DiscountPct: Decimal;
        i: Integer;
#pragma warning disable AA0074
        Text001: Label 'You must enter a value in the "Add/Subtract Discount ''%''" field.';
#pragma warning restore AA0074

    procedure InitializeRequest(DiscountPercent: Decimal)
    begin
        DiscountPct := DiscountPercent;
    end;
}

