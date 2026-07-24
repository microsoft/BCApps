// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Statement;

tableextension 11383 "Gen. Journal Template NL" extends "Gen. Journal Template"
{
    fields
    {
        field(11402; "No. of CBG Statements"; Integer)
        {
            CalcFormula = count("CBG Statement" where("Journal Template Name" = field(Name)));
            Caption = 'No. of CBG Statements';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}

