// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

pageextension 10803 "Audit Export Doc. Card XML" extends "Audit File Export Doc. Card"
{
    layout
    {
        modify(AuditFileExportFormat)
        {
            trigger OnAfterValidate()
            begin
                UpdateXMLFormat();
                CurrPage.Update();
            end;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateXMLFormat();
    end;

    local procedure UpdateXMLFormat()
    var
        AuditFileExportSetup: Record "Audit File Export Setup";
        AuditFileExportFormat: Enum "Audit File Export Format";
    begin
        AuditFileExportFormat := Rec."Audit File Export Format";
        if AuditFileExportFormat.AsInteger() = 0 then begin     // if not initialized yet
            AuditFileExportSetup.Get();
            AuditFileExportFormat := AuditFileExportSetup."Audit File Export Format";
        end;
        if Rec."Audit File Export Format" <> AuditFileExportFormat then begin
            Rec."Audit File Export Format" := AuditFileExportFormat;
            Rec.Modify(true);
        end;
    end;
}
