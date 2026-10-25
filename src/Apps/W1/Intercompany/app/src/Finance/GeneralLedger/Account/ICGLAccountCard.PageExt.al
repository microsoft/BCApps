// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

pageextension 8527 "ICGLAccountCard" extends "G/L Account Card"
{
    layout
    {
        addafter("Tax Group Code")
        {
            field("Default IC Partner G/L Acc. No"; Rec."Default IC Partner G/L Acc. No")
            {
                ApplicationArea = Intercompany;
            }
        }
    }
}
