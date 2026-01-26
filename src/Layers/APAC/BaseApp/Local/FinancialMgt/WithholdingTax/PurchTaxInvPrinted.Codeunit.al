// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

codeunit 28071 "Purch. Tax Inv.-Printed"
{
    Permissions = TableData "Purch. Tax Inv. Header" = rimd;
    TableNo = "Purch. Tax Inv. Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        Rec.Modify();
        Commit();
    end;
}

