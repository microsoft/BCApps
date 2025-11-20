// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

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
                    ToolTip = 'Specifies the VAT reporting code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the VAT reporting code.';
                }
            }
        }
    }
}
