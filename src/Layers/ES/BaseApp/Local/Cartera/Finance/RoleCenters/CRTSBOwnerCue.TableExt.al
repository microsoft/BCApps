// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Finance.ReceivablesPayables;

tableextension 7000091 "CRT SB Owner Cue" extends "SB Owner Cue"
{
    fields
    {
        field(7000000; "Receivable Documents"; Integer)
        {
            CalcFormula = count("Cartera Doc." where(Type = const(Receivable),
                                                      "Bill Gr./Pmt. Order No." = const('')));
            Caption = 'Receivable Documents';
            FieldClass = FlowField;
        }
        field(7000001; "Payable Documents"; Integer)
        {
            CalcFormula = count("Cartera Doc." where(Type = const(Payable),
                                                      "Bill Gr./Pmt. Order No." = const('')));
            Caption = 'Payable Documents';
            FieldClass = FlowField;
        }
        field(7000002; "Posted Receivable Documents"; Integer)
        {
            CalcFormula = count("Posted Cartera Doc." where(Type = const(Receivable),
                                                             "Bill Gr./Pmt. Order No." = const('')));
            Caption = 'Posted Receivable Documents';
            FieldClass = FlowField;
        }
        field(7000003; "Posted Payable Documents"; Integer)
        {
            CalcFormula = count("Posted Cartera Doc." where(Type = const(Payable),
                                                             "Bill Gr./Pmt. Order No." = const('')));
            Caption = 'Posted Payable Documents';
            FieldClass = FlowField;
        }
    }
}
