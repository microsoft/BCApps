// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Buffer table for tracking the usage frequency of accounts across various setup tables.
/// Stores account numbers and their usage counts for analysis and where-used functionality.
/// </summary>
table 63 "Account Use Buffer"
{
    Caption = 'Account Use Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// The G/L account number for which usage is being tracked.
        /// </summary>
        field(1; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// The number of times this account is being used across different setup tables.
        /// </summary>
        field(2; "No. of Use"; Integer)
        {
            Caption = 'No. of Use';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Account No.")
        {
            Clustered = true;
        }
        key(Key2; "No. of Use")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Updates the buffer with usage counts for accounts found in the specified record reference.
    /// Scans through all records and counts how many times each account appears in the specified field.
    /// </summary>
    /// <param name="RecRef">Record reference to scan for account usage</param>
    /// <param name="AccountFieldNo">Field number of the account field to analyze</param>
    procedure UpdateBuffer(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        FieldRef: FieldRef;
        AccNo: Code[20];
    begin
        if RecRef.FindSet() then
            repeat
                FieldRef := RecRef.Field(AccountFieldNo);
                AccNo := FieldRef.Value();
                if AccNo <> '' then
                    if Get(AccNo) then begin
                        "No. of Use" += 1;
                        Modify();
                    end else begin
                        Init();
                        "Account No." := AccNo;
                        "No. of Use" += 1;
                        Insert();
                    end;
            until RecRef.Next() = 0;
    end;
}

