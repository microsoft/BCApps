// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;

codeunit 149507 "Filename Proof Show Inbox"
{
    // Calls the download as the Report Inbox pages do (ShowReport), isolated so a failing download
    // cannot end the proof; the name is decided and captured before the download.

    TableNo = "Report Inbox";

    trigger OnRun()
    begin
        Rec.ShowReport();
    end;
}
