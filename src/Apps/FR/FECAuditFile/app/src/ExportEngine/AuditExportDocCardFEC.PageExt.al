// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

pageextension 10826 "Audit Export Doc. Card FEC" extends "Audit File Export Doc. Card"
{
    layout
    {
        addafter(General)
        {
            group(FEC)
            {
                Enabled = FECFormat;
                Visible = FECFormat;

                field(IncludeOpeningBalances; Rec."Include Opening Balances")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to include opening balances in the audit report file. The balances are calculated as of the date before the first date of the period covered by the report.';
                }
                field(DefaultSourceCode; Rec."Default Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code to be used if there is no code specified in the G/L entry.';
                }
                field(GLAccountFilter; Rec."G/L Account Filter Expression")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the filter for G/L Account record.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.SetTableFilter();
                    end;
                }
            }
        }
        modify(AuditFileExportFormat)
        {
            trigger OnAfterValidate()
            begin
                UpdateFECFormat();
                CurrPage.Update();
            end;
        }
    }

    var
        FECFormat: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateFECFormat();
    end;

    local procedure UpdateFECFormat()
    var
        AuditFileExportSetup: Record "Audit File Export Setup";
        AuditFileExportFormat: enum "Audit File Export Format";
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
        FECFormat := AuditFileExportFormat = AuditFileExportFormat::FEC;
    end;
}
