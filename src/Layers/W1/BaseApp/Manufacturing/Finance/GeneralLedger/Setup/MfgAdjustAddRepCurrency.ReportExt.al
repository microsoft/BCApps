// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Manufacturing.Document;

reportextension 99000786 "Mfg. Adjust Add. Rep. Currency" extends "Adjust Add. Reporting Currency"
{
    dataset
    {
        addafter("Job Ledger Entry")
        {
            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if OldProdOrderLine."Prod. Order No." <> "Prod. Order No." then begin
                        Window.Update(1, "Prod. Order No.");
                        OldProdOrderLine := "Prod. Order Line";
                    end;

                    "Cost Amount (ACY)" := ExchangeAmtLCYToFCY(WorkDate(), "Cost Amount", false);
                    "Unit Cost (ACY)" := ExchangeAmtLCYToFCY(WorkDate(), "Unit Cost", true);
                    Modify();
                end;

                trigger OnPreDataItem()
                begin
                    Window.Open(Text99000004Txt + Text99000002Txt);
                end;
            }
        }
    }

    var
        OldProdOrderLine: Record "Prod. Order Line";
#pragma warning disable AA0470
        Text99000002Txt: Label 'Prod. Order No. #1##########\';
#pragma warning restore AA0470
        Text99000004Txt: Label 'Processing Finished Prod. Order Lines...\\';
}