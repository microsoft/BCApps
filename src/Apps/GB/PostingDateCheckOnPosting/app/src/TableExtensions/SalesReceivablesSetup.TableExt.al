// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.SalesPurch.Setup;

using Microsoft.Sales.Setup;

tableextension 10511 "Sales & Receivables Setup" extends "Sales & Receivables Setup"
{

    trigger OnInsert()
    begin
            "Posting Date Check on Posting" := true;
    end;
}