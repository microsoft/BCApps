// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Telemetry;

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
                    ApplicationArea = Basic, Suite;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company to be included on the VAT report.';
                }
                field("Company Address"; Rec."Company Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the company that is submitting the VAT report.';
                }
                field("Company City"; Rec."Company City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company for the VAT report.';
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
                field("EC Sales List No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Return No. Series"; Rec."VAT Return No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Return Period No. Series"; Rec."VAT Return Period No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Return Period")
            {
                Caption = 'Return Period';
                field("Report Version"; Rec."Report Version")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Reminder Calculation"; Rec."Period Reminder Calculation")
                {
                    ApplicationArea = Basic, Suite;
                }
                group(Control16)
                {
                    ShowCaption = false;
                    field("Manual Receive Period CU ID"; Rec."Manual Receive Period CU ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Manual Receive Codeunit ID';
                        Importance = Additional;
                    }
                    field("Manual Receive Period CU Cap"; Rec."Manual Receive Period CU Cap")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Manual Receive Codeunit Caption';
                        Importance = Additional;
                    }
                    field("Receive Submitted Return CU ID"; Rec."Receive Submitted Return CU ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receive Submitted Return Codeunit ID';
                        Importance = Additional;
                    }
                    field("Receive Submitted Return CUCap"; Rec."Receive Submitted Return CUCap")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receive Submitted Return Codeunit Caption';
                        Importance = Additional;
                    }
                }
                group("Auto Update Job")
                {
                    Caption = 'Auto Update Job';
                    field("Update Period Job Frequency"; Rec."Update Period Job Frequency")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Auto Receive Period CU ID"; Rec."Auto Receive Period CU ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Auto Receive Codeunit ID';
                        Importance = Additional;
                        Editable = Rec."Update Period Job Frequency" = Rec."Update Period Job Frequency"::Never;
                    }
                    field("Auto Receive Period CU Cap"; Rec."Auto Receive Period CU Cap")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Auto Receive Codeunit Caption';
                        Importance = Additional;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        VatReportTok: Label 'DACH VAT Report', Locked = true;
    begin
        FeatureTelemetry.LogUptake('0001Q0B', VatReportTok, Enum::"Feature Uptake Status"::"Set up");
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

