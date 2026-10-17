// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50191 "Filename Batch Measure Step"
{
    // Runs one report step of Filename Batch Measure in isolation. A report render writes, which a
    // TryFunction does not allow, so a step that may fail is run through Codeunit.Run instead and
    // its error read by the caller.

    trigger OnRun()
    var
        FilenameBatchMeasure: Codeunit "Filename Batch Measure";
    begin
        FilenameBatchMeasure.RunCurrentStep();
    end;
}
