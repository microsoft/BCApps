// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

enum 6111 "E-Doc PO Match Warning"
{
    Extensible = false;
    value(0; NotYetReceived)
    {
    }
    value(1; QuantityMismatch)
    {
    }
    value(2; MissingInformationForMatch)
    {
    }
}