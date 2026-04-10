// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Master data interface for defining VAT reporting codes used in tax authority submissions.
/// Enables configuration of reporting codes with descriptions for VAT statement and regulatory compliance.
/// </summary>
page 349 "VAT Reporting Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Reporting Codes';
    PageType = List;
    SourceTable = "VAT Reporting Code";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(VATCodes)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Shows the general posting type that is linked to the VAT reporting code.';
                }
                field("Test Gen. Posting Type"; Rec."Test Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to test the general posting type when posting.';
                }
                field("Trade Settlement 2017 Box No."; Rec."Trade Settlement 2017 Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting field that links the VAT code to the Box No. field in the Trade Settlement 2017 report.';
                }
                field("Reverse Charge Report Box No."; Rec."Reverse Charge Report Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting field that links the VAT code to the Box No. field in the Trade Settlement 2017 report in case of reverse charge VAT.';
                }
                field("VAT Specification Code"; Rec."VAT Specification Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification code';
                }
                field("VAT Note Code"; Rec."VAT Note Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT note code.';
                }
                field("SAF-T VAT Code"; Rec."SAF-T VAT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SAF-T VAT code.';
                }
            }
        }
    }
}