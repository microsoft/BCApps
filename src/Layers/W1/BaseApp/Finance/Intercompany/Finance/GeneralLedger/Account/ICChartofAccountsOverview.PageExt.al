// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

pageextension 8526 "ICChartofAccountsOverview" extends "Chart of Accounts Overview"
{
    layout
    {
        addafter("Consol. Translation Method")
        {
            field("Default IC Partner G/L Acc. No"; Rec."Default IC Partner G/L Acc. No")
            {
                ApplicationArea = Intercompany;
                Editable = false;
                Visible = false;
            }
        }
    }
}
