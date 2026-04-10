// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Finance.Dimension;

/// <summary>
/// Stores manual allocation overrides for allocation account distribution calculations.
/// Enables custom allocation amounts and percentages that override standard distribution rules.
/// </summary>
table 2673 "Alloc. Acc. Manual Override"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifier of the parent table that contains the original allocation data.
        /// </summary>
        field(1; "Parent Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Table Id';
        }
        /// <summary>
        /// System ID of the parent record being overridden.
        /// </summary>
        field(2; "Parent System Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent System Id';
        }
        /// <summary>
        /// Sequential line number for manual override entries within the parent record.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        /// <summary>
        /// Account type for the allocation destination (G/L Account, Customer, Vendor, etc.).
        /// </summary>
        field(5; "Destination Account Type"; Enum "Destination Account Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Destination Account Type';
        }
        /// <summary>
        /// Account number for the allocation destination based on the destination account type.
        /// </summary>
        field(6; "Destination Account Number"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Destination Account Number';
        }
        /// <summary>
        /// Manual override amount to allocate to the destination account.
        /// </summary>
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
            Caption = 'Amount';
        }
        /// <summary>
        /// Allocation account number that this manual override applies to.
        /// </summary>
        field(9; "Allocation Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Allocation Account No.';
        }
        /// <summary>
        /// Manual override percentage to allocate to the destination account.
        /// </summary>
        field(15; Percentage; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = CustomerContent;
            Caption = 'Percentage';
        }
        /// <summary>
        /// Quantity used for manual allocation calculation and override processing.
        /// </summary>
        field(20; Quantity; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = SystemMetadata;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Global dimension 1 code for the manual override entry.
        /// </summary>
        field(37; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Global dimension 2 code for the manual override entry.
        /// </summary>
        field(38; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Dimension set ID linking to dimension combinations for the manual override entry.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Parent Table Id", "Parent System Id", "Line No.")
        {
            Clustered = true;
        }
    }
}
