// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 139778 "Self-Billing Format Mock" extends "E-Document Format"
{
    value(139778; "Self-Billing Mock")
    {
        Implementation = "E-Document" = "Self-Billing Format Mock",
                         ISelfBillingFormatPolicy = "Self-Billing Format Mock";
    }
    value(139779; "Self-Billing Denied Mock")
    {
        Implementation = "E-Document" = "Self-Billing Format Mock",
                         ISelfBillingFormatPolicy = "Self-Billing Format Mock";
    }
}
