// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

/// <summary>
/// List page for managing bank clearing standard codes and descriptions.
/// Provides lookup interface for bank clearing codes used in electronic payment processing.
/// </summary>
/// <remarks>
/// Source Table: Bank Clearing Standard (1280). Used for defining standard bank routing codes.
/// Supports lookup functionality for bank account setup and payment processing configuration.
/// </remarks>
page 1280 "Bank Clearing Standards"
{
    Caption = 'Bank Clearing Standards';
    PageType = List;
    SourceTable = "Bank Clearing Standard";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the bank clearing standard that you choose in the Bank Clearing Standard field on a company, customer, or vendor bank account card.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the bank clearing standard that you choose in the Bank Clearing Standard field on a company, customer, or vendor bank account card.';
                }
            }
        }
    }

    actions
    {
    }
}

