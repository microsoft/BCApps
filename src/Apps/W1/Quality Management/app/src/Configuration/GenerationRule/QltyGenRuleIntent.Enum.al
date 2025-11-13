// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

enum 20460 "Qlty. Gen. Rule Intent"
{
    Caption = 'Generation Rule Intent';
    Extensible = false;

    value(0; Unknown)
    {
        Caption = 'Unknown';
    }
    value(1; Purchase)
    {
        Caption = 'Purchase';
    }
    value(2; "Sales Return")
    {
        Caption = 'Sales Return';
    }
    value(3; "Warehouse Receipt")
    {
        Caption = 'Warehouse Receipt';
    }
    value(4; "Warehouse Movement")
    {
        Caption = 'Warehouse Movement';
    }
    value(5; Transfer)
    {
        Caption = 'Transfer';
    }
    value(6; Production)
    {
        Caption = 'Production';
    }
    value(7; "Assembly")
    {
        Caption = 'Assembly';
    }
}
