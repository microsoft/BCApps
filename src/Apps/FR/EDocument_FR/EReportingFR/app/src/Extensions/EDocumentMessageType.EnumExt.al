// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.eServices.EDocument.Processing.Message;

enumextension 10971 "FR E-Document Message Type" extends "E-Document Message Type"
{
    value(10970; "FR Invoice Lifecycle")
    {
        Caption = 'FR Invoice Lifecycle';
        Implementation = IEDocMessageBuilder = "FR E-Invoice Lifecycle Msg.";
    }
}