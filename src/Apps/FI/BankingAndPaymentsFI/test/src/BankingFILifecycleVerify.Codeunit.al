// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 148242 "Banking FI Lifecycle Verify"
{
    trigger OnRun()
    var
        Lifecycle: Codeunit "Banking FI Lifecycle Capture";
    begin
        Lifecycle.VerifyUpgrade();
    end;
}
