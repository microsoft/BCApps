// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.AuditCodes;

tableextension 6975 "Source Code Setup" extends "Source Code Setup"
{
    fields
    {
        field(6500; "Expense"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Expense';
            TableRelation = "Source Code";
        }
    }
}