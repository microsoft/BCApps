// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

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
                field("Report VAT Base"; Rec."Report VAT Base")
                {
                    ApplicationArea = VAT;
                }
                field("Report VAT Note"; Rec."Report VAT Note")
                {
                    ApplicationArea = VAT;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("EC Sales List No. Series"; Rec."No. Series")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Return No. Series"; Rec."VAT Return No. Series")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Return Period No. Series"; Rec."VAT Return Period No. Series")
                {
                    ApplicationArea = VAT;
                }
            }
            group("Return Period")
            {
                Caption = 'Return Period';
                field("Report Version"; Rec."Report Version")
                {
                    ApplicationArea = VAT;
                }
                field("Period Reminder Calculation"; Rec."Period Reminder Calculation")
                {
                    ApplicationArea = VAT;
                }
                group(Control16)
                {
                    ShowCaption = false;
                    field("Manual Receive Period CU ID"; Rec."Manual Receive Period CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Manual Receive Codeunit ID';
                        Importance = Additional;
                    }
                    field("Manual Receive Period CU Cap"; Rec."Manual Receive Period CU Cap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Manual Receive Codeunit Caption';
                        Importance = Additional;
                    }
                    field("Receive Submitted Return CU ID"; Rec."Receive Submitted Return CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Receive Submitted Return Codeunit ID';
                        Importance = Additional;
                    }
                    field("Receive Submitted Return CUCap"; Rec."Receive Submitted Return CUCap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Receive Submitted Return Codeunit Caption';
                        Importance = Additional;
                    }
                }
                group("Auto Update Job")
                {
                    Caption = 'Auto Update Job';
                    field("Update Period Job Frequency"; Rec."Update Period Job Frequency")
                    {
                        ApplicationArea = VAT;
                    }
                    field("Auto Receive Period CU ID"; Rec."Auto Receive Period CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Auto Receive Codeunit ID';
                        Importance = Additional;
                        Editable = Rec."Update Period Job Frequency" = Rec."Update Period Job Frequency"::Never;
                    }
                    field("Auto Receive Period CU Cap"; Rec."Auto Receive Period CU Cap")
                    {
                        ApplicationArea = VAT;
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
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

