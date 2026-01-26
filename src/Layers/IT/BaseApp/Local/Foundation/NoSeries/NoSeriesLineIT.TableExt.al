// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
tableextension 12146 NoSeriesLineIT extends "No. Series Line"
{
    fields
    {
        field(12100; "No. Series Type"; Enum "No. Series Type")
        {
            CalcFormula = lookup("No. Series"."No. Series Type" where(Code = field("Series Code")));
            Caption = 'No. Series Type';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
