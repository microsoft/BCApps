// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

pageextension 10805 "Audit File Export Setup XML" extends "Audit File Export Setup"
{
    layout
    {
        modify("Data Quality")
        {
            Enabled = not XMLFormat;
            Visible = not XMLFormat;
        }
    }

    var
        XMLFormat: Boolean;

    trigger OnOpenPage()
    begin
        XMLFormat := IsXMLFormat();
    end;

    local procedure IsXMLFormat(): Boolean
    var
        AuditFileExportFormat: Enum "Audit File Export Format";
    begin
        exit(Rec."Audit File Export Format" = AuditFileExportFormat::"GL Entries XML FR");
    end;
}
