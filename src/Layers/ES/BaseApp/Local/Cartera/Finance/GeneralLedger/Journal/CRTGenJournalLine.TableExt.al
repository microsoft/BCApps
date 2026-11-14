// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.ReceivablesPayables;

tableextension 7000090 "CRT Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA25
        field(7000003; "Pmt. Address Code"; Code[10])
        {
            Caption = 'Pmt. Address Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Address is taken from the fields Address, City, etc. of Customer/Vendor table.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }

    [Scope('OnPrem')]
    procedure AdjustDueDate(MaxDate: Date)
    var
        DueDateAdjust: Codeunit "Due Date-Adjust";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                if "Bill-to/Pay-to No." <> '' then
                    DueDateAdjust.SalesAdjustDueDate("Due Date", "Document Date", MaxDate, "Bill-to/Pay-to No.")
                else
                    DueDateAdjust.SalesAdjustDueDate("Due Date", "Document Date", MaxDate, "Account No.");
            "Account Type"::Vendor:
                DueDateAdjust.PurchAdjustDueDate("Due Date", "Document Date", MaxDate, "Account No.");
        end;
    end;
}
