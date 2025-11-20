// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

codeunit 743 "VAT Report Export"
{

    trigger OnRun()
    begin
    end;

    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
#pragma warning disable AA0074
        Text001: Label 'This action will also mark the report as released. Are you sure you want to continue?';
#pragma warning restore AA0074

    procedure Export(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                ExportOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                ExportReleased();
            VATReportHeader.Status::Submitted:
                ExportReleased();
        end;
    end;

    local procedure ExportOpen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            ExportReleased();
        end;
    end;

    local procedure ExportReleased()
    begin
        ExportReport();
    end;

    local procedure ExportReport()
    begin
    end;
}

