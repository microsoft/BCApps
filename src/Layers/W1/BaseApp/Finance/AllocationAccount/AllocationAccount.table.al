// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

/// <summary>
/// Defines allocation accounts for automatic distribution of amounts across multiple destinations.
/// Supports both fixed and variable allocation methods with configurable distribution rules.
/// </summary>
table 2670 "Allocation Account"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "Allocation Account";
    LookupPageId = "Allocation Account List";

    fields
    {
        /// <summary>
        /// Unique identifier for the allocation account.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the allocation account number.';
            OptimizeForTextSearch = true;
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the allocation account.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the allocation account name.';
            OptimizeForTextSearch = true;
        }
        /// <summary>
        /// Type of allocation method: Fixed for predefined percentages, Variable for dynamic calculations.
        /// </summary>
        field(3; "Account Type"; Option)
        {
            Caption = 'Account type';
            ToolTip = 'Specifies the account type for the distribution.';
            OptionMembers = Fixed,Variable;

            trigger OnValidate()
            begin
                DeleteTheExistingSetupRecords();
            end;
        }
        /// <summary>
        /// Specifies how document lines should be split: by Amount or by Quantity.
        /// </summary>
        field(10; "Document Lines Split"; Option)
        {
            Caption = 'Split Document Lines';
            ToolTip = 'Specifies the strategy for splitting the lines when used on the documents.';
            OptionMembers = "Split Amount","Split Quantity";
        }
    }
    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution.SetRange("Allocation Account No.", "No.");
        AllocAccountDistribution.DeleteAll();
    end;

    local procedure DeleteTheExistingSetupRecords()
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution.SetRange("Allocation Account No.", "No.");
        if AllocAccountDistribution.IsEmpty() then
            exit;

        if GuiAllowed() then
            if not Confirm(ConfirmDeleteQst) then
                Error('');

        AllocAccountDistribution.DeleteAll();
    end;

    var
        ConfirmDeleteQst: Label 'Changing the account type will delete the existing distributions. Are you sure you want to continue?';
}
