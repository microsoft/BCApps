// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// List page for managing company size definitions used in financial analysis and reporting.
/// Provides setup interface for company size categories that support analysis and classification.
/// </summary>
/// <remarks>
/// Company size definitions are used for analysis categorization and reporting segmentation.
/// </remarks>
page 532 "Company Sizes"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Company Size";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code that identifies the company size.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the company size.';
                }
            }
        }
    }
}
