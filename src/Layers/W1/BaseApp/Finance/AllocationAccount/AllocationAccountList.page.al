// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using System.Telemetry;

/// <summary>
/// List interface for allocation accounts with support for creating and managing both fixed and variable allocation methods.
/// Provides overview of allocation account configurations with direct navigation to detailed setup.
/// </summary>
page 2673 "Allocation Account List"
{
    ApplicationArea = All;
    AdditionalSearchTerms = 'Allocation accounts, Variable Allocation, Fixed Allocation';
    Caption = 'Allocation Accounts';
    CardPageId = "Allocation Account";
    PageType = List;
    SourceTable = "Allocation Account";
    UsageCategory = Lists;
    MultipleNewLines = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    RefreshOnActivate = true;
    AboutTitle = 'About Allocation Accounts';
    AboutText = 'Manage allocation accounts to automatically split amounts across multiple destination accounts Define fixed or variable allocation methods, set destination accounts, and control how values are distributed during posting. Use allocation accounts in journals and documents to apply consistent allocation rules without manual line splitting.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                Editable = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                }

                field(AccountType; Rec."Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Account Type';
                    ToolTip = 'Specifies the type of the allocation account.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KY9', AllocAccTelemetry.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
    end;
}
