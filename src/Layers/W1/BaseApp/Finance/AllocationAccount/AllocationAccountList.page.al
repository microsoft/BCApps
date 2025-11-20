// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using System.Telemetry;

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
                    ToolTip = 'Specifies the allocation account number.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the allocation account name.';
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
