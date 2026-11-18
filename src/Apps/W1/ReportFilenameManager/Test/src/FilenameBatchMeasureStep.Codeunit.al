// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

codeunit 149541 "Filename Batch Measure Step"
{
    // Runs one step of Filename Batch Measure through Codeunit.Run: a report render writes, which a
    // TryFunction does not allow on-premises by default.

    trigger OnRun()
    var
        FilenameBatchMeasure: Codeunit "Filename Batch Measure";
    begin
        FilenameBatchMeasure.RunCurrentStep();
    end;
}
