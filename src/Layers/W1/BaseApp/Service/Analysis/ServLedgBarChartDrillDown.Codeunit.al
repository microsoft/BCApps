// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Service.Ledger;
using System.Visualization;

codeunit 6085 "Serv. Ledg Bar Chart DrillDown"
{
    TableNo = "Bar Chart Buffer";

    trigger OnRun()
    begin
        if Rec.Tag = '' then
            Error(Text000);
        ServLedgEntry.SetView(Rec.Tag);
        ServLedgEntry.SetRange(Open, false);
        case Rec."Series No." of
            1:
                ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
            2:
                begin
                    ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Usage);
                    ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                end;
        end;
        PAGE.RunModal(0, ServLedgEntry);
    end;

    var
        ServLedgEntry: Record "Service Ledger Entry";
#pragma warning disable AA0074
        Text000: Label 'The corresponding service ledger entries cannot be displayed because the filter expression is too long.';
#pragma warning restore AA0074
}

