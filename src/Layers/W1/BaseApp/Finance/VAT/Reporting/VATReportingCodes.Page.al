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
            }
        }
    }
}
