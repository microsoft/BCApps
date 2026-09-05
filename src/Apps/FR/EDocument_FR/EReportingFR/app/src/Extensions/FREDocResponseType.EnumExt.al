// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument.Processing.Message;

enumextension 10974 "FR E-Doc. Response Type" extends "E-Doc. Response Type"
{
    value(10970; Submitted)
    {
        Caption = 'Submitted';
    }
    value(10971; Refused)
    {
        Caption = 'Refused';
    }
}