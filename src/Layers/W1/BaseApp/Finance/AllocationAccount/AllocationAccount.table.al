// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

table 2670 "Allocation Account"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "Allocation Account";
    LookupPageId = "Allocation Account List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account type';
            OptionMembers = Fixed,Variable;

            trigger OnValidate()
            begin
                DeleteTheExistingSetupRecords();
            end;
        }
        field(10; "Document Lines Split"; Option)
        {
            Caption = 'Split Document Lines';
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
