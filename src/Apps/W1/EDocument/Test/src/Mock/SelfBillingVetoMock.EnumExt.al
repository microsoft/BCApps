// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 139779 "Self-Billing Veto Mock" extends "Export Eligibility Evaluator"
{
    value(139778; "Self-Billing Veto Mock")
    {
        Implementation = IExportEligibilityEvaluator = "Self-Billing Format Mock";
    }
}
