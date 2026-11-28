// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace ExternalEDocument.WriterConsumer;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 50101 "External Read Into Draft" extends "E-Doc. Read into Draft"
{
    value(50100; "External Purchase Reader")
    {
        Caption = 'External Purchase Reader';
        Implementation = IStructuredFormatReader = "External Purchase Draft Reader";
    }
}
