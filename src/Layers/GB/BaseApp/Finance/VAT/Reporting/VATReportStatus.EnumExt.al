#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enumextension 10400 "VAT Report Status" extends "VAT Report Status"
{
    value(7; "Partially Accepted")
    {
        ObsoleteState = Pending;
        ObsoleteTag = '27.0';
        ObsoleteReason = 'Moved to GovTalk app';
        Caption = 'Partially Accepted';
    }
}
#endif