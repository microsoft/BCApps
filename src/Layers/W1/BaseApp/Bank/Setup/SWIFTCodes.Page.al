// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

/// <summary>
/// List page for managing SWIFT (Society for Worldwide Interbank Financial Telecommunication) codes.
/// Provides interface for maintaining bank identification codes used in international wire transfers.
/// </summary>
/// <remarks>
/// Source Table: SWIFT Code (1210). Used for lookup and maintenance of standardized bank identifier codes.
/// Supports international banking operations and wire transfer processing.
/// </remarks>
page 1240 "SWIFT Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SWIFT Codes';
    PageType = List;
    SourceTable = "SWIFT Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank for the corresponding SWIFT code.';
                }
            }
        }
    }

    actions
    {
    }
}

