// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7444 "EA Corp Card Error Context"
{
    Access = Internal;
    SingleInstance = true;

    var
        StructuredErrorInfo: ErrorInfo;
        HasStructuredErrorInfo: Boolean;
        ImportStage: Text;

    internal procedure ClearErrorInfo()
    begin
        Clear(StructuredErrorInfo);
        HasStructuredErrorInfo := false;
        Clear(ImportStage);
    end;

    internal procedure SetImportStage(NewImportStage: Text)
    begin
        ImportStage := NewImportStage;
    end;

    internal procedure GetImportStage(): Text
    begin
        exit(ImportStage);
    end;

    internal procedure SetErrorInfo(NewErrorInfo: ErrorInfo)
    begin
        StructuredErrorInfo := NewErrorInfo;
        HasStructuredErrorInfo := true;
    end;

    internal procedure TryGetErrorInfo(var RetrievedErrorInfo: ErrorInfo): Boolean
    begin
        if not HasStructuredErrorInfo then
            exit(false);

        RetrievedErrorInfo := StructuredErrorInfo;
        StructuredErrorInfo := ErrorInfo.Create();
        HasStructuredErrorInfo := false;
        Clear(ImportStage);
        exit(true);
    end;
}
