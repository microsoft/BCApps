// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Telemetry;

tableextension 10803 "Audit File Export Header XML" extends "Audit File Export Header"
{
    fields
    {
        modify("Audit File Export Format")
        {
            trigger OnBeforeValidate()
            var
                AuditFileExportFormatSetup: Record "Audit File Export Format Setup";
            begin
                if Rec."Audit File Export Format" = Rec."Audit File Export Format"::"GL Entries XML FR" then
                    if not AuditFileExportFormatSetup.Get(Rec."Audit File Export Format"::"GL Entries XML FR") then
                        Error(AuditExportFormatSetupNotExistErr);
            end;

            trigger OnAfterValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                if Rec."Audit File Export Format" = Rec."Audit File Export Format"::"GL Entries XML FR" then begin
                    Rec.Validate("Split By Month", false);
                    Rec.Validate("Split By Date", false);
                    Rec.Validate("Create Multiple Zip Files", false);

                    FeatureTelemetry.LogUptake('0000QPG', XMLAuditFileTok, Enum::"Feature Uptake Status"::Discovered);
                end;
            end;
        }
    }

    var
        AuditExportFormatSetupNotExistErr: Label 'XML export format setup not found. Reinstall extension or add XML format in Audit File Export Format setup.';
        XMLAuditFileTok: label 'XML Audit File', Locked = true;
}
