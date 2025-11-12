// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

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
                    ToolTip = 'Specifies if users can modify VAT reports that have been submitted to the tax authorities. If the field is left blank, users must create a corrective or supplementary VAT report instead.';
                }
                field("Report VAT Base"; Rec."Report VAT Base")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT base must be calculated and shown to the user in the VAT reports.';
                }
                field("Report VAT Note"; Rec."Report VAT Note")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT report must include the contents of the Note field on the relevant report statement lines.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("EC Sales List No. Series"; Rec."No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("VAT Return No. Series"; Rec."VAT Return No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series that is used for VAT return records.';
                }
                field("VAT Return Period No. Series"; Rec."VAT Return Period No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series that is used for the VAT return period records.';
                }
            }
            group("Return Period")
            {
                Caption = 'Return Period';
                field("Report Version"; Rec."Report Version")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT report version that is used for the VAT reporting periods.';
                }
                field("Period Reminder Calculation"; Rec."Period Reminder Calculation")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a formula that is used to notify about an open VAT report period with an upcoming due date.';
                }
                group(Control16)
                {
                    ShowCaption = false;
                    field("Manual Receive Period CU ID"; Rec."Manual Receive Period CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Manual Receive Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with a manual receipt of the VAT return periods.';
                    }
                    field("Manual Receive Period CU Cap"; Rec."Manual Receive Period CU Cap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Manual Receive Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with a manual receipt of the VAT return periods.';
                    }
                    field("Receive Submitted Return CU ID"; Rec."Receive Submitted Return CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Receive Submitted Return Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with a receipt of the submitted VAT returns.';
                    }
                    field("Receive Submitted Return CUCap"; Rec."Receive Submitted Return CUCap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Receive Submitted Return Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with a receipt of the submitted VAT returns.';
                    }
                }
                group("Auto Update Job")
                {
                    Caption = 'Auto Update Job';
                    field("Update Period Job Frequency"; Rec."Update Period Job Frequency")
                    {
                        ApplicationArea = VAT;
                        ToolTip = 'Specifies the job frequency for an automatic update of the VAT return periods.';
                    }
                    field("Auto Receive Period CU ID"; Rec."Auto Receive Period CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Auto Receive Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with an automatic receipt of the VAT return periods. You can only edit this field if the Update Period Job Frequency field contains Never.';
                        Editable = Rec."Update Period Job Frequency" = Rec."Update Period Job Frequency"::Never;
                    }
                    field("Auto Receive Period CU Cap"; Rec."Auto Receive Period CU Cap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Auto Receive Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with an automatic receipt of the VAT return periods.';
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

