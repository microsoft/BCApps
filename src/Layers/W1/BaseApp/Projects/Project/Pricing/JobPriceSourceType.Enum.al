// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Pricing;

enum 7008 "Job Price Source Type"
{
    Extensible = true;
    value(30; "All Jobs")
    {
        Caption = 'All Projects';
    }
    value(31; Job)
    {
        Caption = 'Project';
    }
    value(32; "Job Task")
    {
        Caption = 'Project Task';
    }
}