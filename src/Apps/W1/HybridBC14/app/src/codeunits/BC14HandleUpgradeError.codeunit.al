// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;

codeunit 50160 "BC14 Handle Upgrade Error"
{
    TableNo = "Hybrid Replication Summary";
    trigger OnRun()
    begin
        MarkUpgradeFailed(Rec);
    end;

    internal procedure MarkUpgradeFailed(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        FailureMessageOutStream: OutStream;
        DetailsOutStream: OutStream;
        ErrorText: Text;
        DetailedError: Text;
    begin
        ErrorText := GetLastErrorText();
        DetailedError := GetDetailedUpgradeErrorSummary();

        if ErrorText = '' then
            ErrorText := DetailedError
        else
            ErrorText := ErrorText + ' | ' + DetailedError;

        HybridCompanyStatus.Get(CompanyName());
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Failed;
        HybridCompanyStatus."Upgrade Failure Message".CreateOutStream(FailureMessageOutStream);
        FailureMessageOutStream.Write(ErrorText);
        HybridCompanyStatus.Modify();
        Commit();

        HybridReplicationSummary.Find();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradeFailed;

        // Update End Time to reflect when this upgrade attempt finished
        HybridReplicationSummary."End Time" := CurrentDateTime();

        // Update Details field to show upgrade error instead of replication success message
        HybridReplicationSummary.Details.CreateOutStream(DetailsOutStream);
        DetailsOutStream.Write(StrSubstNo(UpgradeFailedDetailsTxt, ErrorText));

        HybridReplicationSummary.Modify();

        Session.LogMessage('0000RO7', UpgradeFailedMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
    end;

    local procedure GetDetailedUpgradeErrorSummary(): Text
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        ErrorSummary: TextBuilder;
        MaxErrors: Integer;
        ErrorCount: Integer;
        ErrorDetail: Text;
    begin
        MaxErrors := 5;
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Resolved", false);
        BC14MigrationErrors.SetCurrentKey("Created On");
        BC14MigrationErrors.Ascending(false);

        if BC14MigrationErrors.FindSet() then begin
            repeat
                ErrorCount += 1;
                if ErrorCount <= MaxErrors then begin
                    if ErrorSummary.Length > 0 then
                        ErrorSummary.AppendLine();

                    ErrorDetail := StrSubstNo(ErrorDetailFormatTxt,
                        ErrorCount,
                        BC14MigrationErrors."Migration Type",
                        BC14MigrationErrors."Source Table Name",
                        BC14MigrationErrors."Source Record Key",
                        BC14MigrationErrors."Error Message");
                    ErrorSummary.Append(ErrorDetail);
                end;
            until BC14MigrationErrors.Next() = 0;

            if ErrorCount > MaxErrors then
                ErrorSummary.AppendLine(StrSubstNo(MoreErrorsTxt, ErrorCount - MaxErrors));
        end;

        if ErrorSummary.Length = 0 then
            exit(UnknownUpgradeErr);

        exit(ErrorSummary.ToText());
    end;

    var
        UpgradeFailedMsg: Label 'BC14 upgrade failed.', Locked = true;
        UpgradeFailedDetailsTxt: Label 'Upgrade failed: %1', Comment = '%1 = Error message';
        UnknownUpgradeErr: Label 'Upgrade failed with unknown error. Check BC14 Migration Errors page for details.';
        ErrorDetailFormatTxt: Label '[%1] %2 | Table: %3 | Record: %4 | Error: %5', Comment = '%1=Error number, %2=Migration type, %3=Table name, %4=Record key, %5=Error message';
        MoreErrorsTxt: Label '... and %1 more errors. See BC14 Migration Errors page for full list.', Comment = '%1=Number of additional errors';
}
