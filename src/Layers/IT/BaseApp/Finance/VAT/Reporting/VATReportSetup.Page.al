// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Utilities;

/// <summary>
/// Setup interface for VAT reporting configuration and parameters.
/// Controls report modification permissions, VAT base reporting options, and period management settings.
/// </summary>
page 743 "VAT Report Setup"
{
    ApplicationArea = VAT;
    Caption = 'VAT Report Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "VAT Report Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Modify Submitted Reports"; Rec."Modify Submitted Reports")
                {
                    ApplicationArea = VAT;
                }
                field("Filter Datifattura Lines"; Rec."Filter Datifattura Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enable Datifattura Lines Filtering';
                    ToolTip = 'Specifies if the request page must be shown when suggesting Datifattura lines to allow setting a filter for the entries that will be considered.';
                }
                field("Report VAT Note"; Rec."Report VAT Note")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT Note field is available for reporting from the VAT Return card page.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series that will be used for standard VAT reports.';
                }
            }
            group(Intermediary)
            {
                Caption = 'Intermediary';
                field("Intermediary VAT Reg. No."; Rec."Intermediary VAT Reg. No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number of your company or your tax representative.';
                }
                field("Intermediary CAF Reg. No."; Rec."Intermediary CAF Reg. No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the registration number of the intermediary in the registry of tax assistance centers (CAF).';
                }
                field("Intermediary Date"; Rec."Intermediary Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the date that the intermediary processed the VAT report.';
                }
            }
            part(Control1130003; "Spesometro Appointments")
            {
                ApplicationArea = VAT;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

