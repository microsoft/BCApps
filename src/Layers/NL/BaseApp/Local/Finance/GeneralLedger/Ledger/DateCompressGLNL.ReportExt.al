// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

reportextension 11400 "Date Compress G/L NL" extends "Date Compress General Ledger"
{
    dataset
    {
        modify("G/L Entry")
        {
            trigger OnBeforePreDataItem()
            begin
                SetRange(Open, true);
            end;

            trigger OnAfterPreDataItem()
            var
                DateCompressGLNL: Codeunit "Date Compress G/L NL";
            begin
                DateCompressGLNL.FilterUnappliedEntries("G/L Entry");
            end;
        }
    }
}
