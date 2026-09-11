// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Samples.BCLESnapshotDebugging;

using System.Utilities;

codeunit 99999 "BCLE Snapshot Debugging"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CountDistinctValues(): Integer
    var
        OuterLoopNo: Integer;
        DistinctValueCount: Integer;
    begin
        for OuterLoopNo := 1 to 2 do
            CountDistinctValuesForIteration(DistinctValueCount);

        exit(DistinctValueCount);
    end;

    local procedure CountDistinctValuesForIteration(var DistinctValueCount: Integer)
    var
        TempInteger: Record Integer temporary;
        InnerLoopNo: Integer;
    begin
        for InnerLoopNo := 1 to 2 do begin
            TempInteger.Number := InnerLoopNo;
            if TempInteger.Insert() then
                DistinctValueCount += 1;
        end;
    end;
}
