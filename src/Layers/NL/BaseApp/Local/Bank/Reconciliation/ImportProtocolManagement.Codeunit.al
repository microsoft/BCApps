// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

codeunit 11000005 "Import Protocol Management"
{

    trigger OnRun()
    var
        ImportProtocolList: Page "Import Protocol List";
    begin
        ImportProtocol.SetCurrentKey(Current);
        ImportProtocol.SetRange(Current, true);
        ImportProtocol.ModifyAll(Current, false);
        ImportProtocol.SetRange(Current);
        Commit();

        Clear(ImportProtocolList);
        ImportProtocolList.SetTableView(ImportProtocol);
        ImportProtocolList.LookupMode(true);
        if ImportProtocolList.RunModal() = ACTION::LookupOK then begin
            ImportProtocolList.GetRecord(ImportProtocol);
            ImportProtocol.TestField("Import ID");
            ImportProtocol.SetRange(Code, ImportProtocol.Code);
            ImportProtocol.Validate(Current, true);
            ImportProtocol.Modify();
            Commit();

            case ImportProtocol."Import Type" of
                ImportProtocol."Import Type"::Report:
                    REPORT.RunModal(ImportProtocol."Import ID", true);
                ImportProtocol."Import Type"::XMLport:
                    XMLPORT.Run(ImportProtocol."Import ID", true, true);
                ImportProtocol."Import Type"::Codeunit:
                    CODEUNIT.Run(ImportProtocol."Import ID");
            end;
        end;
    end;

    var
        ImportProtocol: Record "Import Protocol";

    procedure GetCurrentImportProtocol(var ImportProtocol: Record "Import Protocol"): Boolean
    begin
        ImportProtocol.Reset();
        ImportProtocol.SetCurrentKey(Current);
        ImportProtocol.SetRange(Current, true);
        if not ImportProtocol.Find('-') then
            exit(false);

        ImportProtocol.Current := false;
        ImportProtocol.Modify();
        exit(true);
    end;
}

