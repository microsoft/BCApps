// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

using Microsoft.Finance.AuditFileExport;
using Microsoft.Utilities;

codeunit 6544 "euBP Data Check" implements "Audit File Export Data Check"
{
    procedure CheckDataToExport(var AuditFileExportHeader: Record "Audit File Export Header"): enum "Audit Data Check Status"
    var
        EUBPSetup: Record "euBP Setup";
    begin
        EUBPSetup.EnsureExists();
        EUBPSetup.Get();
        EUBPSetup.ValidateStoredLohnPayload();
        exit("Audit Data Check Status"::Passed);
    end;

    procedure CheckAuditDocReadyToExport(var AuditFileExportHeader: Record "Audit File Export Header"): enum "Audit Data Check Status"
    var
        EUBPSetup: Record "euBP Setup";
    begin
        AuditFileExportHeader.TestField("Starting Date");
        AuditFileExportHeader.TestField("Ending Date");

        EUBPSetup.EnsureExists();
        EUBPSetup.Get();
        EUBPSetup.TestField("Sender ID");
        EUBPSetup.TestField("Receiver ID");
        if not EUBPSetup.HasLohnPayload() then
            EUBPSetup.TestField("LOHN Payload");

        exit("Audit Data Check Status"::Passed);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", OnCreateEvaluationDataOnAfterClassifyTablesToNormal, '', true, true)]
    local procedure CreateEvaluationDataForeuBP()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"euBP Setup");
    end;

}
