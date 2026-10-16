// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Journal;

tableextension 7443 "EA Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(7420; "EA Corp Card Trans Entry No."; Integer)
        {
            Caption = 'Corp Card Transaction Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "EA Corp Card Trans"."Entry No.";
        }
    }
}
