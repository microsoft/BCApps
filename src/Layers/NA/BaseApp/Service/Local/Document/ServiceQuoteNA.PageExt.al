// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10026 "Service Quote NA" extends "Service Quote"
{
    actions
    {
#if CLEAN27
        modify(ServiceStatistics)
        {
            Visible = not SalesTaxStatisticsVisible;
        }
#endif
        addafter(ServiceStatistics)
        {
            action(ServiceStats)
            {
                ApplicationArea = Service;
                Caption = 'Statistics';
                Image = Statistics;
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = SalesTaxStatisticsVisible;
#else
                Visible = false;
#endif
                RunObject = Page "Service Stats.";
                RunPageOnRec = true;
            }
        }
#if CLEAN27
        addafter(ServiceStatistics_Promoted)
        {
            actionref(ServiceStats_Promoted; ServiceStats)
            {
            }
        }
#endif
    }

    trigger OnOpenPage()
    begin
        SalesTaxStatisticsVisible := Rec."Tax Area Code" <> '';
    end;

    protected var
        SalesTaxStatisticsVisible: Boolean;
}
