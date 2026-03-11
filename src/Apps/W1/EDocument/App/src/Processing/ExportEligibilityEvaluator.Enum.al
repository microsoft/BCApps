// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Enum for the implementations of the Export Eligibility Evaluator interface.
/// </summary>
enum 6127 "Export Eligibility Evaluator" implements IExportEligibilityEvaluator
{
    Extensible = true;
    DefaultImplementation = IExportEligibilityEvaluator = "Default Export Eligibility";

    value(0; "Default")
    {
        Caption = 'Default';
    }
}
