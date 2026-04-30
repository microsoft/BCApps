// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.QualityManagement.Configuration;

codeunit 5709 "Create QM No Series"
{
    trigger OnRun()
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        QltyAutoConfigure.EnsureBasicSetupExists(false);
    end;
}