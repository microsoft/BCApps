// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.SalesPurch.Setup;

using Microsoft.Purchases.Setup;

tableextension 10510 "Purchases & Payables Setup" extends "Purchases & Payables Setup"
{

    trigger OnInsert()
    begin
            "Posting Date Check on Posting" := true;
    end;
}