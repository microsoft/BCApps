// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

/// <summary>
/// Temporary table for sample purchase invoice header data used in PDF generation.
/// </summary>
table 5379 "Sample Purch. Inv. Header"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableType = Temporary;
    Caption = 'Sample Purch. Inv. Header';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
        }
        field(3; "Vendor Invoice No."; Text[35])
        {
            Caption = 'Vendor Invoice No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
