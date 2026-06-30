// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

enumextension 11389 "Gen. Journal Template Type NL" extends "Gen. Journal Template Type"
{
    value(11; Cash)
    {
        Caption = 'Cash';
    }
    value(12; Bank)
    {
        Caption = 'Bank';
    }
}
