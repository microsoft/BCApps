// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;

codeunit 30422 "Shpfy Process Return Order" implements "Shpfy IProcess Returns As"
{
    procedure GetTargetDocumentType(): Enum "Sales Document Type"
    begin
        exit("Sales Document Type"::"Return Order");
    end;
}
