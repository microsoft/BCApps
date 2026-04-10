// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.Company;
using System.IO;

codeunit 8648 "Company Setup Notification"
{
    Access = Internal;

    procedure OpenCompanyInformationPage(N: Notification)
    begin
        Page.RunModal(Page::"Company Information");
    end;

    procedure OpenCostingMethodConfigurationPage(N: Notification)
    begin
        Page.RunModal(Page::"Costing Method Configuration");
    end;
}