// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

codeunit 4144 "Purchase Manual Reopen"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        ReleasePurchaseDocument.PerformManualReopen(Rec);
    end;
}
