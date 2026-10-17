// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50157 "Filename Proof Show Inbox"
{
    // Calls the download the way both Report Inbox pages call it. Isolated in its own codeunit
    // so that the failure a non-interactive session produces - it cannot receive a file - does
    // not end the proof. By the time it fails, the name has already been decided and captured.

    TableNo = "Report Inbox";

    trigger OnRun()
    begin
        Rec.ShowReport();
    end;
}
