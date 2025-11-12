// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Worksheet;

codeunit 843 "Cash Flow Wksh. - Register"
{
    TableNo = "Cash Flow Worksheet Line";

    trigger OnRun()
    begin
        CFWkshLine.Copy(Rec);
        Code();
        Rec.Copy(CFWkshLine);
    end;

    var
        CFWkshLine: Record "Cash Flow Worksheet Line";

        RegisterWorksheetLinesQst: Label 'Do you want to register the worksheet lines?';
        NothingToRegisterMsg: Label 'There is nothing to register.';
        WorksheetLinesRegisteredMsg: Label 'The worksheet lines were successfully registered.';

    local procedure "Code"()
    begin
        if not Confirm(RegisterWorksheetLinesQst) then
            exit;

        CODEUNIT.Run(CODEUNIT::"Cash Flow Wksh.-Register Batch", CFWkshLine);

        if CFWkshLine."Line No." = 0 then
            Message(NothingToRegisterMsg)
        else
            Message(WorksheetLinesRegisteredMsg);

        if not CFWkshLine.Find('=><') then begin
            CFWkshLine.Reset();
            CFWkshLine."Line No." := 1;
        end;
    end;
}

